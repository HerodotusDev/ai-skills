---
name: herodotus
description: Complete guide to the Herodotus Cloud stack — cross-chain provable computation, storage proofs, and on-chain verification. Routes to the right product skill for any task.
---

# Herodotus AI Skill: Full Stack (v1)

## Purpose

Use this skill as your starting point for any Herodotus integration. It covers the full product stack, helps you pick the right products for your use case, and routes you to the detailed per-product skills when you need implementation specifics.

## The Herodotus Stack

Herodotus provides **provable cross-chain data access** — the ability to trustlessly read historical state from any supported chain and consume it on-chain or off-chain with cryptographic guarantees.

### Products at a Glance

| Product                        | What It Does                                                                                | When to Use                                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Atlantic API**               | Proving-as-a-service — submit Cairo programs, get back proofs and artifacts                 | You have a Cairo program and need it proven (trace generation, proof generation, L1/L2 verification) |
| **Data Processor (HDP)**       | Verifiable computation over historical chain data — Cairo modules with soundness guarantees | You need to compute over on-chain data with cryptographic correctness (not just read it)             |
| **Data Processor API**         | HTTP orchestration layer for HDP — task scheduling, module registry, lifecycle management   | You want to run HDP modules as managed tasks through an API instead of CLI                           |
| **Storage Proof API**          | Request proof-backed reads of account/storage/header data across chains                     | You need to read a specific historical value from another chain with a proof                         |
| **Satellite Contracts**        | On-chain trust layer — Solidity contracts that serve verified data to your smart contracts  | You need to consume proven data inside your smart contract                                           |
| **Data Structure Indexer API** | Discovery layer — query accumulators, MMR metadata, remappers                               | You need to discover what data is available for proofs, or map timestamps to blocks                  |

### How They Fit Together

```
┌─────────────────────────────────────────────────────────────┐
│                        Your Application                      │
├──────────┬──────────┬──────────────┬────────────────────────┤
│          │          │              │                          │
│  Storage Proof API  │  Data Processor API  │  Atlantic API   │
│  (request proofs)   │  (orchestrate tasks) │  (prove Cairo)  │
│          │          │              │                          │
│          │          │   Data Processor (HDP)                 │
│          │          │   (verifiable computation)              │
│          │          │              │                          │
│          │   Data Structure Indexer API                       │
│          │   (discovery / planning)                           │
│          │          │              │                          │
├──────────┴──────────┴──────────────┴────────────────────────┤
│              Satellite Contracts (on-chain trust layer)      │
│              Your contracts read verified data here           │
└─────────────────────────────────────────────────────────────┘
```

## Choosing the Right Path

### "I want to read a historical value from another chain"

**Storage Proof API + Satellite Contracts**

1. Submit a batch query via Storage Proof API specifying the chain, block, account, and slot.
2. Wait for terminal success.
3. Read the proven value on-chain via Satellite's safe methods (`accountFieldSafe`, `storageSlotSafe`, etc.).

### "I want to compute over historical chain data with proofs"

**Data Processor (HDP) + Data Structure Indexer API**

1. Use Indexer API to discover available accumulators and plan your data range.
2. Write a Cairo module implementing your computation logic.
3. Run the HDP pipeline: `dry-run` → `fetch-proofs` → `sound-run`.
4. Consume the verified output.

### "I want to run HDP as a managed service"

**Data Processor API + Atlantic API**

1. Upload and publish your Cairo module via Data Processor API.
2. Create tasks with your parameters.
3. The API orchestrates execution and proving through Atlantic under the hood.
4. Track task status and retrieve outputs.

### "I have a Cairo program and need a proof"

**Atlantic API (standalone)**

1. Submit your compiled Cairo program with inputs.
2. Atlantic generates traces, produces proofs, and optionally verifies on L1/L2.
3. Download artifacts (PIE, proof, metadata).

### "I need on-chain access to proven data in my smart contract"

**Satellite Contracts**

1. Import `ISatellite` interface.
2. Resolve the Satellite deployment address for your chain.
3. Call safe read methods gated on your business logic.

### "I'm not sure what I need yet"

Start here:

- If your use case is **reading a specific value** → Storage Proof API path
- If your use case is **computing something** over chain data → Data Processor path
- If your use case is **proving an arbitrary Cairo program** → Atlantic API path
- If you need results **on-chain** → you'll always end up using Satellite Contracts

## Cross-Product Composition Patterns

### Storage Proof + Satellite (most common)

Submit proof request → wait for completion → read verified data on-chain via Satellite → make business decision.

### HDP + Indexer + Satellite

Query Indexer for data availability → run HDP for verified computation → results land in Satellite → consumer contracts read.

### Data Processor API + Atlantic

Upload module → create task → API orchestrates HDP + Atlantic proving → retrieve verified output.

### Full Pipeline (complex)

Indexer discovery → HDP validated computation → Atlantic proof generation → L1/L2 verification → Satellite on-chain reads → application settlement.

## Per-Product Skills

For implementation details, load the specific skill for the product you're working with:

- **`atlantic-api`** — Proving job submission, lifecycle tracking, artifact handling, verification routing
- **`data-processor`** — HDP module design, constraint patterns, dry-run/fetch-proofs/sound-run pipeline
- **`data-processor-api`** — Task scheduling, module registry, status tracking via HTTP
- **`storage-proof-api`** — Batch query construction, proof lifecycle, Satellite readback
- **`satellite-contracts`** — ISatellite integration, safe reads, address resolution, trust boundaries
- **`data-structure-indexer-api`** — Accumulator/remapper discovery, candidate planning

In Claude Code: `/herodotus-skills:<skill-name>`

## Anti-Hallucination Rules (Global)

These apply across ALL Herodotus products:

1. **Source of truth hierarchy**: OpenAPI spec > docs pages > code examples. If sources conflict, use the stricter one.
2. **Never invent**: Do not fabricate endpoints, statuses, chain IDs, contract addresses, or deployment details.
3. **Explicit over implicit**: Always specify chain, environment, and network. Never assume defaults.
4. **Fail closed**: If verified data is absent or a proof isn't terminal-success, do not proceed with business logic.
5. **Products are distinct**: Do not conflate Atlantic API with Data Processor API, or Storage Proof API with HDP. They serve different purposes.
6. **Unknown = unknown**: If a behavior is undocumented, say so. Do not infer.

## Key Links

- **Docs**: https://docs.herodotus.cloud
- **Console**: https://www.herodotus.cloud
- **GitHub**: https://github.com/HerodotusDev
- **Satellite repo**: https://github.com/HerodotusDev/satellite
- **Support**: hello@herodotus.dev
