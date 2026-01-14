#!/bin/bash
set -euo pipefail

echo "eval-skill installer"
echo "===================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=".claude"

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g) TARGET_DIR="$HOME/.claude"; shift ;;
        --help|-h)
            echo "Usage: ./install.sh [--global]"
            echo "  --global, -g  Install to ~/.claude (all projects)"
            echo "  Default: ./.claude (current project)"
            exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

echo "Installing to: $TARGET_DIR"

# Create dirs
mkdir -p "$TARGET_DIR/skills/eval"
mkdir -p "$TARGET_DIR/commands"
mkdir -p "$TARGET_DIR/agents"
mkdir -p "$TARGET_DIR/evals"

# Install files
cp "$SCRIPT_DIR/skills/eval/SKILL.md" "$TARGET_DIR/skills/eval/SKILL.md"
cp "$SCRIPT_DIR/agents/eval-builder.md" "$TARGET_DIR/agents/eval-builder.md"
cp "$SCRIPT_DIR/agents/eval-verifier.md" "$TARGET_DIR/agents/eval-verifier.md"
cp "$SCRIPT_DIR/commands/eval.md" "$TARGET_DIR/commands/eval.md"

echo "✓ Installed"
echo ""
echo "Components:"
echo "  Skill:    $TARGET_DIR/skills/eval/"
echo "  Builder:  $TARGET_DIR/agents/eval-builder.md"
echo "  Verifier: $TARGET_DIR/agents/eval-verifier.md"
echo "  Command:  $TARGET_DIR/commands/eval.md"
echo "  Evals:    $TARGET_DIR/evals/"
echo ""
echo "Usage:"
echo "  Create evals:  'Create evals for [feature]'"
echo "  Build+verify:  /eval build <name>"
echo "  Verify only:   /eval verify <name>"
