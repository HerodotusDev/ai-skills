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
