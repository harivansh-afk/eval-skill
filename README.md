# eval-skill

Give Claude a verification loop. Define acceptance criteria before implementation, let Claude check its own work.

## The Problem

> *"How will the agent know it did the right thing?"*
> — [Thorsten Ball](https://x.com/thorstenball)

Without verification, Claude implements and hopes. With verification, Claude implements and **knows**.

## The Solution

```
┌─────────────────────────────────────────────────────────────┐
│  1. SKILL: eval                                             │
│     "Create evals for auth"                                 │
│     → Generates .claude/evals/auth.yaml                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  2. AGENT: eval-verifier                                    │
│     "/eval verify auth"                                     │
│     → Runs checks                                           │
│     → Collects evidence (screenshots, outputs)              │
│     → Generates executable tests                            │
│     → Reports pass/fail                                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  3. OUTPUT                                                  │
│     .claude/evals/.evidence/auth/  ← Screenshots, logs      │
│     tests/generated/test_auth.py   ← Executable tests       │
└─────────────────────────────────────────────────────────────┘
```

## Install

```bash
git clone https://github.com/yourusername/eval-skill.git
cd eval-skill

# Install to current project
./install.sh

# Or install globally (all projects)
./install.sh --global
```

## Usage

### 1. Create Evals (Before Implementation)

```
> Create evals for user authentication
```

Claude generates `.claude/evals/auth.yaml`:

```yaml
name: auth
description: Email/password authentication

test_output:
  framework: pytest
  path: tests/generated/

verify:
  # Deterministic
  - type: command
    run: "npm test -- --grep 'auth'"
    expect: exit_code 0
    
  - type: file-contains
    path: src/auth/password.ts
    pattern: "bcrypt|argon2"

  # Agent-based (with evidence + test generation)
  - type: agent
    name: ui-login
    prompt: |
      1. Go to /login
      2. Enter test@example.com / password123
      3. Submit
      4. Verify redirect to /dashboard
    evidence:
      - screenshot: after-login
      - url: contains "/dashboard"
    generate_test: true
```

### 2. Implement

```
> Implement auth based on .claude/evals/auth.yaml
```

### 3. Verify

```
> /eval verify auth
```

Output:

```
🔍 Eval: auth
═══════════════════════════════════════

Deterministic:
  ✅ command: npm test (exit 0)
  ✅ file-contains: bcrypt in password.ts

Agent:
  ✅ ui-login: Dashboard redirect works
     📸 Evidence: 2 screenshots saved
     📄 Test: tests/generated/test_auth_ui_login.py

═══════════════════════════════════════
📊 Results: 3/3 passed
```

### 4. Run Generated Tests (Forever)

```bash
pytest tests/generated/
```

The agent converted its semantic verification into deterministic tests.

## How It Works

### Non-Deterministic → Deterministic

Agent checks are semantic: "verify login works." But we need proof.

1. **Verifier runs the check** (browser automation, API calls, file inspection)
2. **Collects evidence** (screenshots, responses, DOM snapshots)
3. **Generates executable test** (pytest/vitest)
4. **Future runs use the test** (no agent needed)

```
Agent Check (expensive)    →    Evidence (proof)    →    Test (cheap, repeatable)
     ↓                              ↓                          ↓
"Login works"              screenshot + url check      pytest + playwright
```

### Evidence-Based Verification

The verifier can't just say "pass." It must provide evidence:

```yaml
- type: agent
  name: login-flow
  prompt: "Verify login redirects to dashboard"
  evidence:
    - screenshot: login-page
    - screenshot: after-submit
    - url: contains "/dashboard"
    - element: '[data-testid="welcome"]'
```

Evidence is saved to `.claude/evals/.evidence/<eval>/`:

```json
{
  "eval": "auth",
  "checks": [{
    "name": "login-flow",
    "pass": true,
    "evidence": [
      {"type": "screenshot", "path": "login-page.png"},
      {"type": "screenshot", "path": "after-submit.png"},
      {"type": "url", "expected": "contains /dashboard", "actual": "http://localhost:3000/dashboard"},
      {"type": "element", "selector": "[data-testid=welcome]", "found": true}
    ]
  }]
}
```

## Check Types

### Deterministic (Fast, No Agent)

```yaml
# Command + exit code
- type: command
  run: "pytest tests/"
  expect: exit_code 0

# Command + output
- type: command
  run: "curl localhost:3000/health"
  expect:
    contains: '"status":"ok"'

# File exists
- type: file-exists
  path: src/feature.ts

# File contains pattern
- type: file-contains
  path: src/auth.ts
  pattern: "bcrypt"

# File does NOT contain
- type: file-not-contains
  path: .env
  pattern: "sk-"
```

### Agent (Semantic, Evidence-Based)

```yaml
- type: agent
  name: descriptive-name
  prompt: |
    Step-by-step verification instructions
  evidence:
    - screenshot: step-name
    - url: contains "pattern"
    - element: "css-selector"
    - text: "expected text"
    - response: status 200
  generate_test: true  # Write executable test
```

## Commands

| Command | Description |
|---------|-------------|
| `/eval list` | List all evals |
| `/eval show <name>` | Display eval spec |
| `/eval verify <name>` | Run verification |
| `/eval verify` | Run all evals |
| `/eval evidence <name>` | Show collected evidence |
| `/eval tests` | List generated tests |
| `/eval clean` | Remove evidence + generated tests |

## Directory Structure

```
.claude/
├── skills/eval/SKILL.md       # Eval generation skill
├── agents/eval-verifier.md    # Verification agent
├── commands/eval.md           # /eval command
└── evals/
    ├── auth.yaml              # Your eval specs
    ├── checkout.yaml
    └── .evidence/
        ├── auth/
        │   ├── evidence.json
        │   └── *.png
        └── checkout/
            └── ...

tests/
└── generated/                  # Tests written by verifier
    ├── test_auth_ui_login.py
    └── test_auth_api_login.py
```

## Requirements

- Claude Code with skills/agents/commands support
- For UI testing: `npm install -g @anthropic/agent-browser`

## Philosophy

**TDD for Agents:**

| Traditional TDD | Agent TDD |
|----------------|-----------|
| Write tests | Write evals |
| Write code | Claude writes code |
| Tests pass | Claude verifies + generates tests |

**Why generate tests?**

Agent verification is expensive (tokens, time). But once verified, we encode that verification as a test. Future runs use the test — no agent needed.

**Mix deterministic and semantic:**

- Deterministic: "tests pass", "file exists", "command succeeds"
- Semantic: "UI looks right", "error is helpful", "code is readable"

Use deterministic where possible, semantic where necessary.

## License

MIT
