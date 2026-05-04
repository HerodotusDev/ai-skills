#!/usr/bin/env bash
set -euo pipefail

REPO="HerodotusDev/ai-skills"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"
SKILLS_PATH="plugins/herodotus-skills/skills"
MAIN_SKILL=herodotus
SUB_SKILLS=(herodotus-auth atlantic-api data-processor data-processor-api storage-proof-api satellite-contracts data-structure-indexer-api)

INSTALL_CLAUDE=false
INSTALL_CURSOR=false
INSTALL_CODEX=false
INSTALL_GOOGLE=false
INSTALL_ANTIGRAVITY=false
EXPLICIT_FLAGS=false
PROJECT_MODE=false

print_help() {
  cat <<'HELP'
Herodotus AI Skills Installer

Usage:
  install.sh [OPTIONS]

Options:
  --claude        Install for Claude Code (plugin marketplace)
  --cursor        Install for Cursor (skills directory)
  --codex         Install for Codex / Gemini CLI (.agents/skills standard)
  --gemini-cli    Alias for --codex (same .agents/skills path)
  --google        Install AGENTS.md for Google Jules
  --antigravity   Install for Google Antigravity (skills directory)
  --project       Install into current project instead of global home
  --help          Show this help message

If no tool flags are given, shows an interactive selector with auto-detection.

Examples:
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --claude --cursor
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --antigravity --project
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --cursor --project
  curl -fsSL https://raw.githubusercontent.com/HerodotusDev/ai-skills/main/install.sh | bash -s -- --codex --project
HELP
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --claude)       INSTALL_CLAUDE=true;       EXPLICIT_FLAGS=true; shift;;
    --cursor)       INSTALL_CURSOR=true;       EXPLICIT_FLAGS=true; shift;;
    --codex|--gemini-cli) INSTALL_CODEX=true;    EXPLICIT_FLAGS=true; shift;;
    --google)       INSTALL_GOOGLE=true;       EXPLICIT_FLAGS=true; shift;;
    --antigravity)  INSTALL_ANTIGRAVITY=true;  EXPLICIT_FLAGS=true; shift;;
    --project) PROJECT_MODE=true; shift;;
    --help)    print_help;;
    *) echo "Unknown option: $1"; print_help;;
  esac
done

# ---------------------------------------------------------------------------
# Interactive multi-select (only when no explicit tool flags were given)
# ---------------------------------------------------------------------------
show_selector() {
  local -a labels=("Claude Code" "Cursor" "Codex / Gemini CLI" "Google Jules" "Google Antigravity")
  local -a checked=(false false false false false)
  local -a hints=("" "" "" "" "")
  local project_checked=false
  local num_tools=5
  local total_rows=7          # 5 tools + separator + project toggle
  local separator_idx=5
  local project_idx=6
  local cur=0

  # Auto-detect: "installed" = skills already present, "detected" = tool present
  if command -v claude &>/dev/null; then
    hints[0]="detected"; checked[0]=true
  fi

  if [[ -f "$HOME/.cursor/skills/herodotus/SKILL.md" ]] || [[ -f ".cursor/skills/herodotus/SKILL.md" ]]; then
    hints[1]="installed"; checked[1]=true
  elif [[ -d "$HOME/.cursor" ]] || command -v cursor &>/dev/null 2>&1; then
    hints[1]="detected"; checked[1]=true
  fi

  if [[ -f "$HOME/.agents/skills/herodotus/SKILL.md" ]] || [[ -f ".agents/skills/herodotus/SKILL.md" ]]; then
    hints[2]="installed"; checked[2]=true
  elif [[ -d "$HOME/.codex" ]] || command -v codex &>/dev/null 2>&1 || command -v gemini &>/dev/null 2>&1; then
    hints[2]="detected"; checked[2]=true
  fi

  if [[ -f "./AGENTS.md" ]]; then
    hints[3]="installed"; checked[3]=true
  fi

  if [[ -f "$HOME/.gemini/antigravity/skills/herodotus/SKILL.md" ]] || [[ -f ".agent/skills/herodotus/SKILL.md" ]]; then
    hints[4]="installed"; checked[4]=true
  elif [[ -d "$HOME/.gemini/antigravity" ]] || [[ -d ".agent" ]]; then
    hints[4]="detected"; checked[4]=true
  fi

  # We need /dev/tty for interactive input (stdin may be a pipe from curl)
  if [[ ! -e /dev/tty ]]; then
    echo "  No interactive terminal available — installing for all detected tools."
    echo "  Use explicit flags (--help) for non-interactive installs."
    INSTALL_CLAUDE=true; INSTALL_CURSOR=true; INSTALL_CODEX=true
    INSTALL_GOOGLE=true; INSTALL_ANTIGRAVITY=true
    return
  fi

  # Set terminal to character-at-a-time mode; save state for restore.
  # Using stty (once) instead of read -s avoids per-read terminal toggling
  # that breaks multi-byte escape sequences and signal delivery.
  local old_stty
  old_stty=$(stty -g </dev/tty 2>/dev/null)

  tui_cleanup() {
    stty "$old_stty" </dev/tty 2>/dev/null || true
    printf '\e[?25h' >/dev/tty 2>/dev/null || true
  }
  trap tui_cleanup EXIT
  trap 'tui_cleanup; exit 130' INT
  trap 'tui_cleanup; exit 143' TERM

  stty -icanon -echo </dev/tty
  printf '\e[?25l' >/dev/tty

  printf '\n  Select tools to install/update:\n' >/dev/tty
  printf '  ↑↓ navigate · space toggle · enter confirm\n\n' >/dev/tty

  draw() {
    [[ "${1:-}" == "redraw" ]] && printf '\e[%dA' "$total_rows" >/dev/tty
    local i
    for i in $(seq 0 $((total_rows - 1))); do
      if [[ $i -eq $separator_idx ]]; then
        printf '    ─────────────────────────────────\e[K\n' >/dev/tty
        continue
      fi

      local arrow="  "
      [[ $i -eq $cur ]] && arrow="▸ "

      if [[ $i -lt $num_tools ]]; then
        local mark=" "
        [[ "${checked[$i]}" == "true" ]] && mark="✓"
        local hint=""
        [[ -n "${hints[$i]}" ]] && hint="  (${hints[$i]})"
        printf '  %s[%s] %s%s\e[K\n' "$arrow" "$mark" "${labels[$i]}" "$hint" >/dev/tty
      else
        local mark=" "
        [[ "$project_checked" == "true" ]] && mark="✓"
        printf '  %s[%s] Install to current project\e[K\n' "$arrow" "$mark" >/dev/tty
      fi
    done
  }

  draw first

  while true; do
    local key=""
    IFS= read -rn1 key </dev/tty 2>/dev/null || true

    case "$key" in
      $'\x03') # Ctrl+C
        tui_cleanup
        exit 130
        ;;
      $'\e')
        local b1="" b2=""
        IFS= read -rn1 b1 </dev/tty 2>/dev/null || true
        IFS= read -rn1 b2 </dev/tty 2>/dev/null || true
        if [[ "$b1" == "[" ]]; then
          case "$b2" in
            A) # up
              cur=$((cur - 1))
              [[ $cur -eq $separator_idx ]] && cur=$((cur - 1))
              [[ $cur -lt 0 ]] && cur=$((total_rows - 1))
              ;;
            B) # down
              cur=$((cur + 1))
              [[ $cur -eq $separator_idx ]] && cur=$((cur + 1))
              [[ $cur -ge $total_rows ]] && cur=0
              ;;
          esac
        fi
        ;;
      " ")
        if [[ $cur -lt $num_tools ]]; then
          [[ "${checked[$cur]}" == "true" ]] && checked[$cur]=false || checked[$cur]=true
        elif [[ $cur -eq $project_idx ]]; then
          [[ "$project_checked" == "true" ]] && project_checked=false || project_checked=true
        fi
        ;;
      ""|$'\n'|$'\r')
        break
        ;;
    esac

    draw redraw
  done

  stty "$old_stty" </dev/tty
  printf '\e[?25h\n' >/dev/tty
  trap - EXIT INT TERM

  # Build summary of what was selected
  local -a chosen=()
  for i in $(seq 0 $((num_tools - 1))); do
    [[ "${checked[$i]}" == "true" ]] && chosen+=("${labels[$i]}")
  done
  if [[ ${#chosen[@]} -gt 0 ]]; then
    local IFS=", "
    printf '\n  Selected: %s\n' "${chosen[*]}" >/dev/tty
  else
    printf '\n  Nothing selected.\n' >/dev/tty
  fi

  INSTALL_CLAUDE="${checked[0]}"
  INSTALL_CURSOR="${checked[1]}"
  INSTALL_CODEX="${checked[2]}"
  INSTALL_GOOGLE="${checked[3]}"
  INSTALL_ANTIGRAVITY="${checked[4]}"
  PROJECT_MODE="$project_checked"
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
echo ""
echo "  Herodotus AI Skills Installer"
echo "  =============================="

if $EXPLICIT_FLAGS; then
  echo ""
else
  show_selector
  echo ""
fi

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
download_skills() {
  local target_dir="$1"

  # Main skill → <target>/herodotus/SKILL.md
  mkdir -p "$target_dir/herodotus"
  if curl -fsSL "$BASE_URL/$SKILLS_PATH/$MAIN_SKILL/SKILL.md" -o "$target_dir/herodotus/SKILL.md" 2>/dev/null; then
    echo "    + herodotus"
  else
    echo "    ! Failed to download herodotus"
  fi

  # Sub-skills → <target>/herodotus/<skill>/SKILL.md
  for skill in "${SUB_SKILLS[@]}"; do
    mkdir -p "$target_dir/herodotus/$skill"
    if curl -fsSL "$BASE_URL/$SKILLS_PATH/$skill/SKILL.md" -o "$target_dir/herodotus/$skill/SKILL.md" 2>/dev/null; then
      echo "    + herodotus/$skill"
    else
      echo "    ! Failed to download $skill"
    fi
  done
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
  download_skills "$TARGET"
  echo "    Done."
  echo ""
  installed_count=$((installed_count + 1))
fi

# --- Codex / Gemini CLI ---
if $INSTALL_CODEX; then
  echo "  [Codex / Gemini CLI]"
  if $PROJECT_MODE; then
    TARGET=".agents/skills"
    echo "    Installing to project: ./$TARGET/"
  else
    TARGET="$HOME/.agents/skills"
    echo "    Installing to global: $TARGET/"
  fi
  download_skills "$TARGET"
  echo "    Done."
  echo ""
  installed_count=$((installed_count + 1))
fi

# --- Google Jules ---
if $INSTALL_GOOGLE; then
  echo "  [Google Jules]"
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
  download_skills "$TARGET"
  echo "    Done."
  echo ""
  installed_count=$((installed_count + 1))
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
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
