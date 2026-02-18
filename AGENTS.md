# Herodotus Cloud Services — Agent Instructions

When working with Herodotus products, follow the relevant skill playbook below. Each skill provides architecture patterns, implementation workflows, anti-hallucination guardrails, and reference examples.

## Available Skills

| Skill | Use When |
|-------|----------|
| [Herodotus (Full Stack)](plugins/herodotus-skills/skills/herodotus/SKILL.md) | **Start here** — understand the full stack, pick the right products, cross-product workflows |
| [Atlantic API](plugins/herodotus-skills/skills/atlantic-api/SKILL.md) | Submitting Cairo proving jobs, tracking lifecycle, downloading artifacts |
| [Data Processor](plugins/herodotus-skills/skills/data-processor/SKILL.md) | Building HDP modules, running dry-run/fetch-proofs/sound-run pipelines |
| [Data Processor API](plugins/herodotus-skills/skills/data-processor-api/SKILL.md) | Orchestrating HDP tasks/modules via HTTP, managing lifecycle |
| [Storage Proof API](plugins/herodotus-skills/skills/storage-proof-api/SKILL.md) | Requesting proof-backed data, consuming verified values on-chain |
| [Satellite Contracts](plugins/herodotus-skills/skills/satellite-contracts/SKILL.md) | Integrating ISatellite in Solidity, reading verified on-chain data |
| [Data Structure Indexer API](plugins/herodotus-skills/skills/data-structure-indexer-api/SKILL.md) | Discovering accumulators/remappers, planning proof-backed workflows |

## General Rules

1. Treat OpenAPI specs as source of truth for request/response shapes.
2. Never invent endpoints, statuses, chain support, or deployment addresses.
3. Keep chain/environment explicit in every workflow.
4. Use safe-read methods and fail-closed policies for business decisions.
5. If source conflicts exist, surface them explicitly and choose the stricter source.

## Cross-Stack Composition Patterns

- **HDP + Indexer + Satellite:** Use indexer for candidate discovery, HDP for constrained validation, Satellite for trusted consumption.
- **Storage Proof + Satellite:** Submit proof jobs, wait for terminal success, then read via safe Satellite methods.
- **Data Processor API + Atlantic:** Use API orchestration for queued jobs, Atlantic for proving lifecycle and artifacts.

## Documentation

- Docs: https://docs.herodotus.cloud
- Console: https://www.herodotus.cloud
- GitHub: https://github.com/HerodotusDev
