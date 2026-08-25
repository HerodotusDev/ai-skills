---
name: storage-proof-api
description: Request proof-backed data, track completion, and consume verified values on-chain via Satellite.
---

# Herodotus AI Skill: Storage Proof API (v1)

## Purpose

Use this skill to request proof-backed data, track completion, and consume verified values on-chain via Satellite.

## When to use

- Request account/storage/header/timestamp proof data.
- Build cross-chain historical verification workflows.
- Read proven values on-chain with safe access patterns.

## Source-of-truth

- https://docs.herodotus.cloud/storage-proofs-api/introduction
- https://docs.herodotus.cloud/storage-proofs-api/use-cases
- https://docs.herodotus.cloud/storage-proofs-api/quick-start-guide
- https://docs.herodotus.cloud/storage-proofs-api/key-concepts
- https://docs.herodotus.cloud/storage-proofs-api/contracts/accessing-data
- https://docs.herodotus.cloud/storage-proofs-api/contracts/example-smart-contract
- https://docs.herodotus.cloud/storage-proofs-api/contracts/contract-addresses
- OpenAPI spec: `openapi-storage-proof-api.json` (available in the docs repo)

## Production API surface (Mission Control)

Product name remains **Storage Proof API**. Requests are served by Mission Control.

| Item | Value |
|------|-------|
| Base URL | `https://mission-control.api.herodotus.cloud` (alias `https://api.herodotus.cloud`) |
| Swagger UI | https://mission-control.api.herodotus.cloud/swagger/ |
| OpenAPI | https://mission-control.api.herodotus.cloud/api-docs/openapi.json |
| Auth | Header `api-key` (required except `/is-alive`) |
| Console | https://www.herodotus.cloud |

Primary endpoints:

- `POST /submit-request` → `{ status, request_id }`
- `GET /get_queries/{request_id}` → `{ queries: [{ internal_id, status, typ, created_at, completed_at }] }`
- `GET /get_actions/{query_id}` → `{ actions: [...] }`
- Grow orders: `GET/POST /grow-orders`, `GET /grow-orders/{id}`, `POST /grow-orders/{id}/cancel`
- `GET /is-alive` → `{ message: "Alive!" }`

Request body uses snake_case (`destination_chain_id`, not `destinationChainId`). Do not use the retired paths `/submit-batch-query` or `/batch-query-status`. `https://api.herodotus.cloud` is the Storage Proof API alias for the same Mission Control service. Do not invent endpoints beyond this surface.

## Architecture pattern

`request builder -> proof submission -> lifecycle tracker -> Satellite read adapter -> app rule engine`

Only make business decisions after terminal success and successful on-chain read.

## Implementation workflow

1. Build submit-request payload from app intent (origin-chain proof data + `destination_chain_id`).
2. `POST /submit-request` with `api-key` header; persist `request_id` + payload hash.
3. Poll `GET /get_queries/{request_id}` until terminal success/failure; optionally `GET /get_actions/{query_id}` for detail.
4. On success, read values from Satellite using safe methods.
5. Feed verified values to business logic.

## On-chain access pattern

Use documented Satellite reads:

- `headerFieldSafe`
- `accountFieldSafe`
- `storageSlotSafe`
- `timestampSafe`

Prefer safe variants to avoid revert-driven control flow.

## Anti-hallucination guardrails

- Do not invent chain IDs, statuses, fields, or Mission Control endpoints.
- Do not conflate with Data Processor API.
- Auth is the `api-key` header (not query-string `apiKey` on the old host).
- Treat unknown behavior as unknown; do not infer.

## Self-contained reference example

```ts
async function proveThenReadBalance(req: SubmitRequestBody, readArgs: ReadArgs) {
  const { request_id } = await submitRequest(req); // POST /submit-request
  const status = await waitQueriesDone(request_id); // GET /get_queries/{request_id}
  if (status !== "COMPLETED") throw new Error("proof flow not completed");
  const result = await satelliteAccountFieldSafe(readArgs);
  if (!result.exists) throw new Error("verified value missing on-chain");
  return result.value;
}
```

## Output checklist

- Proof request tracked by immutable `request_id`
- Terminal status required before consumption
- Safe-read fallback implemented
- Address/network validation in place
