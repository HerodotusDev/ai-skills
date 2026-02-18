#!/usr/bin/env bash
set -euo pipefail

REPO="HerodotusDev/ai-skills"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"
SKILLS_PATH="plugins/herodotus-skills/skills"
SKILLS=(herodotus atlantic-api data-processor data-processor-api storage-proof-api satellite-contracts data-structure-indexer-api)

INSTALL_CLAUDE=false
INSTALL_CURSOR=false
INSTALL_CODEX=false
INSTALL_GOOGLE=false
INSTALL_ANTIGRAVITY=false
INSTALL_ALL=true
PROJECT_MODE=false

print_help() {
  cat <<'HELP'
Herodotus AI Skills Installer

Usage:
  install.sh [OPTIONS]

Options:
  --claude        Install for Claude Code (plugin marketplace)
  --cursor        Install for Cursor (skills directory)
  --codex         Install for Codex / OpenAI (skills directory)
  --google        Install AGENTS.md for Google Gemini / Jules
  --antigravity   Install for Google Antigravity (skills directory)
  --project       Install into current project instead of global home
  --help          Show this help message

If no tool flags are given, installs for all detected tools.

Examples:
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --claude --cursor
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --antigravity --project
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --cursor --project
HELP
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --claude)       INSTALL_CLAUDE=true;       INSTALL_ALL=false; shift;;
    --cursor)       INSTALL_CURSOR=true;       INSTALL_ALL=false; shift;;
    --codex)        INSTALL_CODEX=true;        INSTALL_ALL=false; shift;;
    --google)       INSTALL_GOOGLE=true;       INSTALL_ALL=false; shift;;
    --antigravity)  INSTALL_ANTIGRAVITY=true;  INSTALL_ALL=false; shift;;
    --project) PROJECT_MODE=true; shift;;
    --help)    print_help;;
    *) echo "Unknown option: $1"; print_help;;
  esac
done

if $INSTALL_ALL; then
  INSTALL_CLAUDE=true
  INSTALL_CURSOR=true
  INSTALL_CODEX=true
  INSTALL_GOOGLE=true
  INSTALL_ANTIGRAVITY=true
fi

echo ""
echo "  Herodotus AI Skills Installer"
echo "  =============================="
echo ""

download_skill() {
  local skill_name="$1"
  local target_dir="$2"
  mkdir -p "$target_dir/$skill_name"
  if curl -fsSL "$BASE_URL/$SKILLS_PATH/$skill_name/SKILL.md" -o "$target_dir/$skill_name/SKILL.md" 2>/dev/null; then
    echo "    + $skill_name"
  else
    echo "    ! Failed to download $skill_name"
  fi
}

installed_count=0

# --- Claude Code ---
if $INSTALL_CLAUDE; then
  echo "  [Claude Code]"
  if command -v claude &>/dev/null; then
    echo "    Adding marketplace..."
    if claude plugin marketplace add "$REPO" 2>/dev/null; then
      echo "    Marketplace added."
    else
      echo "    Marketplace may already be added (or CLI unavailable)."
    fi
    echo "    Installing plugin..."
    if claude plugin install "herodotus-skills@herodotus" 2>/dev/null; then
      echo "    Plugin installed."
    else
      echo "    Plugin may already be installed."
    fi
    echo "    Usage: /herodotus-skills:atlantic-api"
    echo ""
    installed_count=$((installed_count + 1))
  else
    echo "    'claude' CLI not found — skipping."
    echo "    Install Claude Code first: https://docs.anthropic.com/en/docs/claude-code"
    echo ""
  fi
fi

# --- Cursor ---
if $INSTALL_CURSOR; then
  echo "  [Cursor]"
  if $PROJECT_MODE; then
    TARGET=".cursor/skills"
    echo "    Installing to project: ./$TARGET/"
  else
    TARGET="$HOME/.cursor/skills"
    echo "    Installing to global: $TARGET/"
  fi
  for skill in "${SKILLS[@]}"; do
    download_skill "$skill" "$TARGET"
  done
  echo "    Done."
  echo ""
  installed_count=$((installed_count + 1))
fi

# --- Codex ---
if $INSTALL_CODEX; then
  echo "  [Codex]"
  TARGET="$HOME/.codex/skills"
  echo "    Installing to: $TARGET/"
  for skill in "${SKILLS[@]}"; do
    download_skill "$skill" "$TARGET"
  done
  echo "    Done."
  echo ""
  installed_count=$((installed_count + 1))
fi

# --- Google (Gemini / Jules) ---
if $INSTALL_GOOGLE; then
  echo "  [Google Gemini / Jules]"
  echo "    Downloading AGENTS.md to current directory..."
  if curl -fsSL "$BASE_URL/AGENTS.md" -o "./AGENTS.md" 2>/dev/null; then
    echo "    + AGENTS.md"
  else
    echo "    ! Failed to download AGENTS.md"
  fi
  echo "    Done."
  echo ""
  installed_count=$((installed_count + 1))
fi

# --- Google Antigravity ---
if $INSTALL_ANTIGRAVITY; then
  echo "  [Google Antigravity]"
  if $PROJECT_MODE; then
    TARGET=".agent/skills"
    echo "    Installing to project: ./$TARGET/"
  else
    TARGET="$HOME/.gemini/antigravity/skills"
    echo "    Installing to global: $TARGET/"
  fi
  for skill in "${SKILLS[@]}"; do
    download_skill "$skill" "$TARGET"
  done
  echo "    Done."
  echo ""
  installed_count=$((installed_count + 1))
fi

echo "  =============================="
if [ $installed_count -gt 0 ]; then
  echo "  $installed_count tool(s) configured."
else
  echo "  No tools were installed. Use --help to see options."
fi
echo ""
echo "  Docs:    https://docs.herodotus.cloud/skills"
echo "  GitHub:  https://github.com/$REPO"
echo ""
