---
name: atlantic-api
description: Build, operate, and troubleshoot Atlantic proving workflows with strong source-grounding and minimal hallucination risk.
---

# Herodotus AI Skill: Atlantic API (v1)

## Purpose

Use this skill to build, operate, and troubleshoot Atlantic proving workflows with strong source-grounding and minimal hallucination risk.

## When to use

> **Precondition:** Atlantic requires an API key. If you don't already have one, run the `herodotus-auth` skill first to obtain one programmatically via wallet auth (https://docs.herodotus.cloud/skills/herodotus-auth). In Claude Code: `/herodotus-skills:herodotus-auth`.

- Submit Cairo proving jobs.
- Track query/job lifecycle and terminal states.
- Download artifacts (PIE/PROOF/metadata).
- Integrate L1/L2/offchain verification steps.

## Source-of-truth

- https://docs.herodotus.cloud/atlantic-api/introduction
- https://docs.herodotus.cloud/atlantic-api/getting-started
- https://docs.herodotus.cloud/atlantic-api/sending-query
- https://docs.herodotus.cloud/atlantic-api/status
- https://docs.herodotus.cloud/atlantic-api/downloading-files
- https://docs.herodotus.cloud/atlantic-api/webhooks
- https://docs.herodotus.cloud/atlantic-api/steps/trace-generation
- https://docs.herodotus.cloud/atlantic-api/steps/proof-generation
- https://docs.herodotus.cloud/atlantic-api/steps/l1-proof-verification
- https://docs.herodotus.cloud/atlantic-api/steps/l2-proof-verification
- https://docs.herodotus.cloud/atlantic-api/x402-payments
- OpenAPI spec: `openapi-atlantic.json` (available in the docs repo)

## Architecture pattern

Treat Atlantic as proving infrastructure, not your business workflow engine:

`planner -> submitter -> lifecycle tracker -> artifact store -> verifier adapters -> app settlement`

## Implementation workflow

1. Authenticate and obtain an API key via the `herodotus-auth` skill (https://docs.herodotus.cloud/skills/herodotus-auth). New wallets get a Personal project + active API key auto-provisioned on the first session — `GET /api-keys?projectId=<selectedProject>` returns it.
2. Build request payload from OpenAPI.
3. Submit query.
4. Poll status/jobs with backoff.
5. On terminal success, download artifacts.
6. Route to verifier adapter (L1/L2/offchain) as needed.
7. Persist query state, artifacts, and verification outcome.

## Reliability requirements

- Keep Atlantic query ID as a first-class DB entity.
- Add idempotency/dedup key handling on submit.
- Implement retry budget + exponential backoff.
- Support both polling and webhook-driven progression.
- Record full error payloads and transitions for debugging.

## Paying with x402

Atlantic speaks the canonical **x402 v2** HTTP-payments protocol on
`POST /atlantic-query`. Header names match the public spec exactly
(`PAYMENT-REQUIRED`, `PAYMENT-SIGNATURE`, `PAYMENT-RESPONSE`), so
off-the-shelf x402 clients (e.g. `x402-fetch`, `@coinbase/x402-axios`)
work unchanged. Use this when an agent has an EVM wallet and either no
API key, or an API key on a project whose prepaid credits ran out.

### Choose your flow

There are three states. Only the second and third trigger x402:

1. **API key + sufficient credits** — normal flow. Do **not** send a
   `PAYMENT-SIGNATURE` header preemptively; it will be ignored. The
   server only requests payment when prepaid credits are not sufficient
   for the query.
2. **API key + depleted credits → API-key flow.** Server returns `402`.
   Pay once, the settled amount is added to your project's credit
   balance with a **2-year expiry**, the current query goes through,
   and **leftover credits remain on the project** for future queries.
3. **No API key + EVM wallet → anonymous flow.** Server returns `402`.
   Identity = recovered EIP-3009 signer. **Pay-once, use-once.** No
   project, no balance, no carryover, no refunds. Each query needs a
   fresh payment. `dedupId` and `bucketId` are rejected
   (`WALLET_FLOW_DEDUP_ID_NOT_SUPPORTED`,
   `WALLET_FLOW_BUCKET_NOT_SUPPORTED`).

### Wire recipe

1. **Submit normally.** `POST /atlantic-query` with your usual body.
   Include the API key (header / query param) for flow 2; omit it
   entirely for flow 3.
2. **Read the 402.** On `402`, parse base64 JSON from the
   `PAYMENT-REQUIRED` header (the same payload also appears in the
   response body under `paymentRequired` for convenience). Shape:
   `{ x402Version: 2, accepts: PaymentRequirement[], error: string }`.
3. **Pick a requirement** from `accepts[]` and read **all** of `payTo`,
   `asset`, `network`, `amount`, `maxTimeoutSeconds` from it — never
   hardcode them. Preserve `extra.challengeId` (server-issued, ULID,
   single-use) and, if present, `extra.atlantic_query_id` (lets you
   resume the same query if you got disconnected after submitting).
4. **Sign EIP-3009.** Build a `transferWithAuthorization` message
   targeting the requirement's `asset` contract on `network`, with
   `from = your wallet`, `to = payTo`, `value = amount`,
   `validAfter = 0`, `validBefore = now + maxTimeoutSeconds`,
   `nonce = 32 random bytes`. Sign EIP-712 typed-data over it. The
   EIP-712 domain `name` and `version` come from `requirement.extra.name`
   and `requirement.extra.version` (the challenge embeds them so you
   don't have to call `eip712Domain()` on the asset contract). Derive
   `chainId` from the `network` string.
5. **Retry the request** with header
   `PAYMENT-SIGNATURE: <base64 JSON>` where the JSON is the x402 v2
   `PaymentPayload`:
   ```json
   {
     "x402Version": 2,
     "accepted": <the chosen PaymentRequirement, verbatim>,
     "payload": {
       "signature": "0x…",
       "authorization": {
         "from": "0x…", "to": "0x…", "value": "1000000",
         "validAfter": "0", "validBefore": "1735689600",
         "nonce": "0x…32 bytes…"
       }
     }
   }
   ```
   On the API-key flow, send the same body again. On the anonymous
   flow, the wallet that signed becomes your identity for this query.
6. **Read `PAYMENT-RESPONSE`** on the `200`. Base64 JSON:
   `{ x402Version: 2, success: true, transaction, network, payer,
   alreadyProcessed }`. Treat `alreadyProcessed: true` as success
   (idempotent replay) — **do not pay again**.

### Anti-hallucination guardrails (x402)

- Use only the public x402 flow exposed by `POST /atlantic-query` and
  the `PAYMENT-REQUIRED`, `PAYMENT-SIGNATURE`, and `PAYMENT-RESPONSE`
  headers. Do not invent or call payment endpoints that are not in the
  public docs or OpenAPI spec.
- Do **not** hardcode `payTo`, `asset`, `network`, or `amount`. Read
  them from `accepts[]` on every 402. The server may switch networks
  or rotate the receiver address.
- Do **not** preemptively send `PAYMENT-SIGNATURE` on the API-key
  flow. The server only requests x402 payment after prepaid credits are
  insufficient;
  sending payment with credits available wastes the signature.
- Do **not** reuse a `PAYMENT-SIGNATURE` after a successful settle.
  Challenges are single-use; a replay returns `X402_SETTLEMENT_FAILED`
  (status 402). Fetch a fresh `PAYMENT-REQUIRED` for each new query.
- Do **not** send `dedupId` or `bucketId` on the anonymous flow.
- Do **not** assume anonymous payments leave a credit balance. They
  do not. If a wallet wants persistent credits, run `herodotus-auth`
  and use the API-key flow.
- Match only on agent-visible error codes. For anonymous flow disabled,
  the agent-visible code is `MISSING_API_KEY` (status 400).

### Error taxonomy (x402)

| Agent-visible code | Status | When |
|---|---|---|
| `X402_NOT_ENABLED` | 503 | x402 disabled in this Atlantic deployment; back off, do not retry |
| `MISSING_API_KEY` | 400 | Anonymous flow disabled; fall back to `herodotus-auth` |
| `X402_CHALLENGE_FAILED` | 502 | Upstream challenge build failed; transient, retry with backoff |
| `X402_SETTLEMENT_FAILED` | 402 | Verify/settle rejected (bad signature, replay, expired auth, insufficient wallet balance); fetch a new challenge |
| `X402_SETTLEMENT_RESPONSE_INVALID` | 502 | Settlement succeeded but response failed schema; treat as ambiguous, do **not** double-pay before checking `GET /atlantic-query/:id` |
| `X402_SERVICE_AUTH_NOT_CONFIGURED` | 500 | Server misconfiguration; surface to the user, do not retry |
| `WALLET_FLOW_DEDUP_ID_NOT_SUPPORTED` | 400 | Drop `dedupId` from the body and resubmit |
| `WALLET_FLOW_BUCKET_NOT_SUPPORTED` | 400 | Drop `bucketId` from the body and resubmit |
| `WALLET_FLOW_NOT_RETRIABLE` | 400 | This anonymous query cannot be retried; submit a new one |

### Self-contained reference example (viem)

```ts
import { createWalletClient, http, parseUnits } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';

const ATLANTIC = 'https://atlantic.api.herodotus.cloud';
const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY as `0x${string}`;
const API_KEY = process.env.ATLANTIC_API_KEY; // undefined → anonymous flow

const account = privateKeyToAccount(PRIVATE_KEY);

function b64(value: unknown) {
  return Buffer.from(JSON.stringify(value), 'utf8').toString('base64');
}
function unb64<T>(value: string): T {
  return JSON.parse(Buffer.from(value, 'base64').toString('utf8')) as T;
}

async function submitWithX402(body: FormData) {
  const headers: Record<string, string> = {};
  if (API_KEY) headers['x-api-key'] = API_KEY;

  let res = await fetch(`${ATLANTIC}/atlantic-query`, { method: 'POST', headers, body });
  if (res.status !== 402) return res;

  const challenge = unb64<{
    x402Version: 2;
    accepts: Array<{
      scheme: 'exact'; network: string; asset: string; payTo: string;
      amount: string; resource: string; mimeType: string;
      maxTimeoutSeconds?: number; extra?: Record<string, unknown>;
    }>;
    error: string;
  }>(res.headers.get('PAYMENT-REQUIRED')!);

  const requirement = challenge.accepts[0];
  const validAfter = 0n;
  const validBefore = BigInt(Math.floor(Date.now() / 1000) + (requirement.maxTimeoutSeconds ?? 300));
  const nonce = `0x${[...crypto.getRandomValues(new Uint8Array(32))]
    .map((b) => b.toString(16).padStart(2, '0')).join('')}` as `0x${string}`;

  // Map x402 `network` string → EIP-155 chainId. Extend per deployment.
  const NETWORK_TO_CHAIN_ID: Record<string, number> = {
    'base': 8453, 'base-sepolia': 84532,
    'ethereum': 1, 'sepolia': 11155111,
  };

  const signature = await account.signTypedData({
    domain: {
      name: requirement.extra?.name as string,        // e.g. "USD Coin"
      version: requirement.extra?.version as string,  // e.g. "2"
      chainId: NETWORK_TO_CHAIN_ID[requirement.network],
      verifyingContract: requirement.asset as `0x${string}`,
    },
    types: {
      TransferWithAuthorization: [
        { name: 'from', type: 'address' },
        { name: 'to', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'validAfter', type: 'uint256' },
        { name: 'validBefore', type: 'uint256' },
        { name: 'nonce', type: 'bytes32' },
      ],
    },
    primaryType: 'TransferWithAuthorization',
    message: {
      from: account.address,
      to: requirement.payTo as `0x${string}`,
      value: BigInt(requirement.amount),
      validAfter,
      validBefore,
      nonce,
    },
  });

  const paymentPayload = {
    x402Version: 2,
    accepted: requirement,
    payload: {
      signature,
      authorization: {
        from: account.address,
        to: requirement.payTo,
        value: requirement.amount,
        validAfter: validAfter.toString(),
        validBefore: validBefore.toString(),
        nonce,
      },
    },
  };

  res = await fetch(`${ATLANTIC}/atlantic-query`, {
    method: 'POST',
    headers: { ...headers, 'PAYMENT-SIGNATURE': b64(paymentPayload) },
    body,
  });
  return res;
}
```

> **Production note.** EIP-712 domain fields (`name`, `version`,
> `chainId`) for USDC and other tokens are not constants — read them
> from `requirement.extra` (the challenge embeds them) or call
> `eip712Domain()` on the `asset` contract. Do not hardcode.

## Anti-hallucination guardrails

- Do not invent endpoints/fields/statuses absent in OpenAPI/docs.
- Do not conflate Atlantic API with Data Processor API.
- If docs prose conflicts with OpenAPI, prefer OpenAPI for wire contract.
- If a behavior is undocumented, mark as unknown and ask for clarification.

## Self-contained reference example

```ts
async function runAtlanticJob(payload: unknown) {
  const queryId = await submitAtlanticQuery(payload); // POST /atlantic-query
  const status = await waitUntilTerminal(queryId); // poll with backoff
  if (status.kind !== "success") throw new Error(status.error);
  const artifacts = await downloadAtlanticArtifacts(queryId);
  return { queryId, artifacts };
}
```

## Output checklist

- Query ID captured
- Terminal status captured
- Artifacts persisted
- Verification path selected
- Failure taxonomy and retry policy documented
