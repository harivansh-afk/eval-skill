#!/bin/bash
set -euo pipefail

REPO="https://github.com/harivansh-afk/eval-skill"
TARGET_DIR=".claude"

for arg in "$@"; do
    case $arg in
        --global|-g) TARGET_DIR="$HOME/.claude" ;;
        --help|-h) echo "Usage: ./install.sh [--global]"; exit 0 ;;
    esac
done

echo "eval-skill → $TARGET_DIR"

# If not in repo, clone to temp
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" && pwd 2>/dev/null)" || SCRIPT_DIR=""
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/skills/eval/SKILL.md" ]]; then
    SCRIPT_DIR=$(mktemp -d)
    git clone --quiet --depth 1 "$REPO" "$SCRIPT_DIR"
    CLEANUP=true
else
    CLEANUP=false
fi

# Install
mkdir -p "$TARGET_DIR/skills/eval" "$TARGET_DIR/commands" "$TARGET_DIR/agents" "$TARGET_DIR/evals"
cp "$SCRIPT_DIR/skills/eval/SKILL.md" "$TARGET_DIR/skills/eval/"
cp "$SCRIPT_DIR/agents/eval-builder.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/agents/eval-verifier.md" "$TARGET_DIR/agents/"
cp "$SCRIPT_DIR/commands/eval.md" "$TARGET_DIR/commands/"

[[ "$CLEANUP" == "true" ]] && rm -rf "$SCRIPT_DIR"

echo "✓ Done"
echo ""
echo "  Create evals:  'Create evals for [feature]'"
echo "  Build+verify:  /eval build <name>"
