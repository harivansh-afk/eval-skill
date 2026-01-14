#!/bin/bash
set -euo pipefail

# Eval Skill Installer
# Installs the eval system: skill + verifier agent + command

echo "╔══════════════════════════════════════╗"
echo "║       Eval Skill Installer           ║"
echo "╚══════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args
INSTALL_GLOBAL=false
TARGET_DIR=".claude"

while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            INSTALL_GLOBAL=true
            TARGET_DIR="$HOME/.claude"
            shift
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --global, -g    Install to ~/.claude (all projects)"
            echo "  --help, -h      Show this help"
            echo ""
            echo "Default: Install to ./.claude (current project)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "$INSTALL_GLOBAL" = true ]; then
    echo "📍 Installing globally: $TARGET_DIR"
else
    echo "📍 Installing to project: $(pwd)/$TARGET_DIR"
fi
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$TARGET_DIR/skills/eval"
mkdir -p "$TARGET_DIR/commands"
mkdir -p "$TARGET_DIR/agents"
mkdir -p "$TARGET_DIR/evals"

# Install skill
echo "Installing eval skill..."
cp "$SCRIPT_DIR/skills/eval/SKILL.md" "$TARGET_DIR/skills/eval/SKILL.md"
echo "  ✅ $TARGET_DIR/skills/eval/SKILL.md"

# Install verifier agent
echo "Installing eval-verifier agent..."
cp "$SCRIPT_DIR/agents/eval-verifier.md" "$TARGET_DIR/agents/eval-verifier.md"
echo "  ✅ $TARGET_DIR/agents/eval-verifier.md"

# Install command
echo "Installing /eval command..."
cp "$SCRIPT_DIR/commands/eval.md" "$TARGET_DIR/commands/eval.md"
echo "  ✅ $TARGET_DIR/commands/eval.md"

# Create example eval
if [ ! -f "$TARGET_DIR/evals/example.yaml" ]; then
    echo "Creating example eval..."
    cat > "$TARGET_DIR/evals/example.yaml" << 'EOF'
name: example
description: Example eval demonstrating the format

test_output:
  framework: pytest
  path: tests/generated/

verify:
  # === DETERMINISTIC CHECKS ===
  
  - type: file-exists
    path: README.md
    
  - type: command
    run: "echo 'hello world'"
    expect: exit_code 0

  # === AGENT CHECKS ===
  
  - type: agent
    name: readme-quality
    prompt: |
      Read README.md and verify:
      1. Has a title/heading
      2. Explains what the project does
      3. Has installation instructions
    evidence:
      - text: "# "
    generate_test: false  # Subjective, no test
EOF
    echo "  ✅ $TARGET_DIR/evals/example.yaml"
fi

# Check dependencies
echo ""
echo "Checking optional dependencies..."
if command -v agent-browser &> /dev/null; then
    echo "  ✅ agent-browser installed"
else
    echo "  ⚠️  agent-browser not found (needed for UI testing)"
    echo "     npm install -g @anthropic/agent-browser"
fi

# Success
echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Installation Complete          ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "What was installed:"
echo ""
echo "  📋 Skill: eval"
echo "     Generates eval specs (YAML)"
echo "     Location: $TARGET_DIR/skills/eval/"
echo ""
echo "  🤖 Agent: eval-verifier"
echo "     Runs checks, collects evidence, generates tests"
echo "     Location: $TARGET_DIR/agents/"
echo ""
echo "  ⌨️  Command: /eval"
echo "     CLI: list | show | verify"
echo "     Location: $TARGET_DIR/commands/"
echo ""
echo "  📁 Evals Directory: $TARGET_DIR/evals/"
echo "     Your eval specs go here"
echo ""
echo "Usage:"
echo ""
echo "  1. Create evals:"
echo "     > Create evals for user authentication"
echo ""
echo "  2. List evals:"
echo "     > /eval list"
echo ""
echo "  3. Run verification:"
echo "     > /eval verify auth"
echo ""
echo "  4. Run generated tests:"
echo "     > pytest tests/generated/"
echo ""
