---
name: herodotus-auth
description: Authenticate to Herodotus Cloud programmatically with an EVM wallet (EIP-712) to obtain a Bearer access token and an API key. Required precondition for every Herodotus API skill (Atlantic, Storage Proof, Data Processor, etc.).
---

# Herodotus AI Skill: Wallet Authentication (v1)

## Purpose

Programmatic, browser-free authentication for AI agents and CLIs. Exchange an EIP-712-signed challenge for a Bearer-channel access token, then read or create your API key. Every other Herodotus API skill assumes this skill has already produced a usable API key.

## When to use

- An agent, CLI, server, or notebook needs an API key for Atlantic API, Storage Proof API, Data Processor API, Data Structure Indexer API, or Satellite contract orchestration.
- Cookie-based session is not viable (no cookie jar, cross-origin, serverless, headless).
- You have an EVM wallet — any signer that can produce an EIP-712 signature works (private key in env, KMS, hardware wallet, MetaMask, ethers, viem).

**Out of scope.** This skill is wallet auth only. The GitHub OAuth path (`/auth/github/...`) is cookie-only by design and is not exposed through this protocol — do not try `channel=bearer` against it.

## Source-of-truth

- Docs: https://docs.herodotus.cloud/documentation/authentication#programmatic-wallet-authentication
- Skill page: https://docs.herodotus.cloud/skills/herodotus-auth
- Prod base URL: `https://auth-billing.api.herodotus.cloud`
- Endpoints used by this skill:
  - `GET  /auth/web3/challenge?wallet=0x…`
  - `POST /auth/web3/session` (body field `channel: "bearer"`)
  - `POST /auth/refresh-token` (`Authorization: Bearer <refreshToken>`)
  - `GET  /api-keys?projectId=<selectedProject>&limit=10&offset=0`
  - `POST /api-keys` (mint additional keys)

## Protocol contract (do not deviate)

1. **Fetch challenge.** `GET /auth/web3/challenge?wallet=<addr>` returns `{ challengeToken, nonce, issuedAt, expiresAt, statement, eip712 }`. The `eip712` object contains `domain`, `types`, `primaryType`, and `message` — **sign exactly those fields, do not reconstruct them client-side**.
2. **Sign typed data.** Use any EIP-712 signer to produce a signature over `eip712.domain` / `eip712.types` / `eip712.primaryType` / `eip712.message`.
3. **Exchange for a Bearer session.** `POST /auth/web3/session` with body `{ wallet, challengeToken, signature, channel: "bearer" }`. Response body returns `{ accessToken, refreshToken, expiresAt, selectedProject }`. **No `Set-Cookie` is sent for the bearer path.** Persist all four fields.
4. **Use the access token.** Set `Authorization: Bearer <accessToken>` on every subsequent call. Do **not** put the token in a cookie — channel binding will reject it.
5. **Refresh.** Before expiry, `POST /auth/refresh-token` with `Authorization: Bearer <refreshToken>`. Response body returns a fresh `{ accessToken, refreshToken, expiresAt }`. Old refresh token is invalidated.
6. **Get API key.** First-time wallets are auto-provisioned with a Personal project and one active API key. Retrieve it with `GET /api-keys?projectId=<selectedProject>&limit=10&offset=0`; read `data[0].apiKey`. Mint additional keys with `POST /api-keys` body `{ projectId, type: { name, color } }`.

## Bring-your-own signer

This skill specifies the wire protocol; signing is the caller's responsibility. The reference example below uses viem because it is terse, but any EIP-712 signer works as long as it signs the exact `{ domain, types, primaryType, message }` returned by the challenge endpoint:

- viem: `account.signTypedData({ domain, types, primaryType, message })`
- ethers v6: `wallet.signTypedData(domain, types, message)` — drop `EIP712Domain` from `types` if present.
- Browser wallet: `window.ethereum.request({ method: 'eth_signTypedData_v4', params: [address, JSON.stringify(payload)] })`
- KMS / hardware: any signer that produces a valid EIP-712 signature for the typed payload.

> **Production note.** A private key in an env var is fine for local development and CI agents; for production agents, prefer KMS or a hardware-backed signer. The protocol is signer-agnostic.

## Channel binding (security property — do not work around)

Tokens are bound to the transport channel they were issued on:

- A token issued with `channel: 'bearer'` is **rejected** if presented via cookie.
- A token issued with `channel: 'cookie'` is **rejected** if presented via `Authorization: Bearer`.

This is enforced server-side and is not configurable. If your agent uses this skill, every authenticated call must use `Authorization: Bearer <accessToken>`. If you also need a browser session for the same wallet, run the cookie path separately — do not reuse tokens across channels.

## Self-contained reference example (viem)

```ts
import { privateKeyToAccount } from 'viem/accounts';

const BASE = 'https://auth-billing.api.herodotus.cloud';
const PRIVATE_KEY = process.env.HERODOTUS_WALLET_PRIVATE_KEY as `0x${string}`;

async function authenticate() {
  const account = privateKeyToAccount(PRIVATE_KEY);

  // 1. Fetch challenge
  const challenge = await fetch(
    `${BASE}/auth/web3/challenge?wallet=${account.address}`,
  ).then((r) => r.json());

  // 2. Sign EIP-712 typed data exactly as returned
  const signature = await account.signTypedData({
    domain: challenge.eip712.domain,
    types: challenge.eip712.types,
    primaryType: challenge.eip712.primaryType,
    message: challenge.eip712.message,
  });

  // 3. Exchange for Bearer session
  const session = await fetch(`${BASE}/auth/web3/session`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      wallet: account.address,
      challengeToken: challenge.challengeToken,
      signature,
      channel: 'bearer',
    }),
  }).then((r) => r.json());

  const { accessToken, refreshToken, expiresAt, selectedProject } = session;

  // 4. Retrieve auto-provisioned API key
  const keysRes = await fetch(
    `${BASE}/api-keys?projectId=${selectedProject}&limit=10&offset=0`,
    { headers: { authorization: `Bearer ${accessToken}` } },
  ).then((r) => r.json());

  const apiKey = keysRes.data[0].apiKey;

  return { accessToken, refreshToken, expiresAt, selectedProject, apiKey };
}

async function refresh(refreshToken: string) {
  const res = await fetch(`${BASE}/auth/refresh-token`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${refreshToken}`,
      'content-type': 'application/json',
    },
    body: '{}',
  }).then((r) => r.json());
  return res; // { accessToken, refreshToken, expiresAt }
}
```

### Equivalent curl recipe

```bash
WALLET=0x...
BASE=https://auth-billing.api.herodotus.cloud

# 1. Challenge
curl -s "$BASE/auth/web3/challenge?wallet=$WALLET" > challenge.json

# 2. Sign challenge.json's eip712 payload with your wallet (out of band)
SIG=0x...

# 3. Bearer session
curl -s -X POST "$BASE/auth/web3/session" \
  -H 'content-type: application/json' \
  -d "{\"wallet\":\"$WALLET\",\"challengeToken\":\"$(jq -r .challengeToken challenge.json)\",\"signature\":\"$SIG\",\"channel\":\"bearer\"}" \
  > session.json

ACCESS=$(jq -r .accessToken session.json)
PROJECT=$(jq -r .selectedProject session.json)

# 4. API key
curl -s "$BASE/api-keys?projectId=$PROJECT&limit=10&offset=0" \
  -H "authorization: Bearer $ACCESS" \
  | jq -r '.data[0].apiKey'
```

## Anti-hallucination guardrails

- Do not invent endpoints. The five listed under "Source-of-truth" are the entire surface this skill needs.
- Do not hardcode the EIP-712 `domain`, `types`, `primaryType`, or `statement` — read them from the challenge response on every login. The server may rotate them.
- Do not extract a cookie-issued JWT and forward it as `Authorization: Bearer`. The server enforces channel binding and will reject it with `ChannelMismatch`.
- Do not assume a default `projectId`. Always read `selectedProject` from the session response.
- Do not assume `POST /api-keys` is required. New wallets get one auto-provisioned; only call POST if you need additional keys.
- If a behavior is undocumented in the source-of-truth list above, mark it unknown and ask for clarification rather than inventing it.

## Output checklist

- Challenge fetched with the exact wallet address that will sign.
- Signature produced over the verbatim `eip712` payload from the challenge response.
- `channel: "bearer"` set on the session request.
- `accessToken`, `refreshToken`, `expiresAt`, `selectedProject` persisted by the agent.
- API key retrieved (or minted) and stored for downstream skills.
- Refresh path verified before access-token expiry: `POST /auth/refresh-token` with `Authorization: Bearer <refreshToken>` returns a new pair.
- All subsequent Herodotus API calls use `Authorization: Bearer <accessToken>` — never cookies.

## Next skill

Once you have an API key, load the product-specific skill:

- `atlantic-api` — Cairo proving jobs, lifecycle tracking, artifact handling, L1/L2 verification.
- `storage-proof-api` — Storage / account / header proofs across chains.
- `data-processor-api` — Verifiable computation orchestration (HDP).
- `data-structure-indexer-api` — Discovery of accumulators and remappers.
- `satellite-contracts` — On-chain consumption of verified data.
- `data-processor` — HDP module authoring and the dry-run / fetch-proofs / sound-run pipeline.
