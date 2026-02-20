# Herodotus AI Skills

Vendor-neutral AI skill playbooks for building with [Herodotus Cloud Services](https://docs.herodotus.cloud). These skills provide architecture patterns, implementation workflows, anti-hallucination guardrails, and reference examples for every Herodotus product.

## Quick Install

Run the installer and pick the tools you use from an interactive selector (auto-detects what's installed):

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash
```

Or skip the selector and install for specific tools directly:

```bash
# Claude Code only
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --claude

# Cursor only
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --cursor

# Codex / Gemini CLI (both use .agents/skills standard)
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --codex

# Google Jules
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --google

# Google Antigravity
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --antigravity

# Cursor into current project (instead of global)
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --cursor --project

# Codex into current project (instead of global)
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --codex --project

# Antigravity into current project (instead of global)
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --antigravity --project
```

## Per-Tool Setup

### Claude Code

Uses the native [plugin marketplace](https://docs.anthropic.com/en/docs/claude-code/skills):

```bash
# In Claude Code CLI
/plugin marketplace add HerodotusDev/ai-skills
/plugin install herodotus-skills@herodotus
```

Then invoke any skill:

```
/herodotus-skills:herodotus              # full stack overview — start here
/herodotus-skills:atlantic-api
/herodotus-skills:data-processor
/herodotus-skills:storage-proof-api
```

### Cursor

Skills are installed as `SKILL.md` files under a `herodotus/` folder. The installer places them in `~/.cursor/skills/herodotus/` (global) or `.cursor/skills/herodotus/` (per-project).

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --cursor
```

Or manually copy any skill:

```bash
mkdir -p .cursor/skills/herodotus/atlantic-api
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/atlantic-api/SKILL.md \
  -o .cursor/skills/herodotus/atlantic-api/SKILL.md
```

### Codex / Gemini CLI

Both [Codex](https://developers.openai.com/codex/skills/) and [Gemini CLI](https://geminicli.com/docs/cli/skills/) read skills from the `.agents/skills/` standard path. One install covers both tools.

Skills are installed under `~/.agents/skills/herodotus/` (global) or `.agents/skills/herodotus/` (per-project).

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --codex
# or equivalently:
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --gemini-cli
```

Or install into the current project:

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --codex --project
```

Or manually copy any skill:

```bash
mkdir -p .agents/skills/herodotus/atlantic-api
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/atlantic-api/SKILL.md \
  -o .agents/skills/herodotus/atlantic-api/SKILL.md
```

### Google Jules

Downloads an `AGENTS.md` file into your project root:

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --google
```

Or copy it manually:

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/AGENTS.md -o AGENTS.md
```

### Google Antigravity

Skills are installed under `~/.gemini/antigravity/skills/herodotus/` (global) or `.agent/skills/herodotus/` (per-project):

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --antigravity
```

Or install into the current project:

```bash
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --antigravity --project
```

Or manually copy any skill:

```bash
mkdir -p .agent/skills/herodotus/atlantic-api
curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/atlantic-api/SKILL.md \
  -o .agent/skills/herodotus/atlantic-api/SKILL.md
```

### Manual Download

Download any individual skill directly:

| Skill                      | Download                                                                                                                                      |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Herodotus (Full Stack)     | [SKILL.md](https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/herodotus/SKILL.md)                  |
| Atlantic API               | [SKILL.md](https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/atlantic-api/SKILL.md)               |
| Data Processor             | [SKILL.md](https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/data-processor/SKILL.md)             |
| Data Processor API         | [SKILL.md](https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/data-processor-api/SKILL.md)         |
| Storage Proof API          | [SKILL.md](https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/storage-proof-api/SKILL.md)          |
| Satellite Contracts        | [SKILL.md](https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/satellite-contracts/SKILL.md)        |
| Data Structure Indexer API | [SKILL.md](https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/plugins/herodotus-skills/skills/data-structure-indexer-api/SKILL.md) |

## Available Skills

| Skill                          | Purpose                                                                                                         |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| **Herodotus (Full Stack)**     | **Start here** — complete guide to the stack, helps pick the right products, cross-product composition patterns |
| **Atlantic API**               | Submit Cairo proving jobs, track query/job lifecycle, download artifacts, integrate L1/L2 verification          |
| **Data Processor (HDP)**       | Build Cairo modules consuming proof-backed chain data, run dry-run/fetch-proofs/sound-run pipelines             |
| **Data Processor API**         | Orchestrate HDP tasks/modules via HTTP, manage task lifecycle and module registry                               |
| **Storage Proof API**          | Request proof-backed data, track completion, consume verified values on-chain via Satellite                     |
| **Satellite Contracts**        | Integrate ISatellite in Solidity, read verified historical on-chain values with safe access patterns            |
| **Data Structure Indexer API** | Discover accumulators/remappers, plan proof-backed workflows from indexed data                                  |

## Repository Structure

```
ai-skills/
├── .claude-plugin/
│   └── marketplace.json              # Claude Code marketplace catalog
├── plugins/
│   └── herodotus-skills/
│       ├── .claude-plugin/
│       │   └── plugin.json           # Claude Code plugin manifest
│       └── skills/
│           ├── herodotus/SKILL.md          # full stack overview
│           ├── atlantic-api/SKILL.md
│           ├── data-processor/SKILL.md
│           ├── data-processor-api/SKILL.md
│           ├── storage-proof-api/SKILL.md
│           ├── satellite-contracts/SKILL.md
│           └── data-structure-indexer-api/SKILL.md
├── AGENTS.md                          # Google Jules agent instructions
├── install.sh                         # Universal installer script
└── README.md
```

## Links

- **Docs**: https://docs.herodotus.cloud
- **Console**: https://www.herodotus.cloud
- **GitHub**: https://github.com/HerodotusDev
- **Support**: hello@herodotus.dev

## License

MIT
