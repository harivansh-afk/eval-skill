# eval-skill

Verification-first development for Claude Code. Define what success looks like, then let Claude build and verify.

## Why

> *"How will the agent know it did the right thing?"*

Without a feedback loop, Claude implements and hopes. With one, Claude implements, checks, and iterates until it's right.

## How It Works

```
You: "Build auth with email/password"
        │
        ▼
┌─────────────────────────────────────┐
│  Skill: eval                        │
│  Generates:                         │
│    • verification spec (tests)      │
│    • building spec (what to build)  │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  Agent: builder                     │
│  Implements from building spec      │
│  Clean context, focused on code     │
└─────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────┐
│  Agent: verifier                    │
│  Runs checks, collects evidence     │
│  Returns pass/fail                  │
└─────────────────────────────────────┘
        │
        ▼
    Pass? Done.
    Fail? → Builder fixes → Verifier checks → Loop
```

Each agent has isolated context. Builder doesn't hold verification logic. Verifier doesn't hold implementation details. Clean, focused, efficient.

## Install

```bash
git clone https://github.com/yourusername/eval-skill.git
cd eval-skill
./install.sh           # Current project
./install.sh --global  # All projects
```

## Usage

### Step 1: Create Specs

```
Create evals for user authentication with email/password
```

Creates `.claude/evals/auth.yaml`:

```yaml
name: auth

building_spec:
  description: Email/password auth with login/signup
  requirements:
    - Password hashing with bcrypt
    - JWT tokens on login
    - /login and /signup endpoints

verification_spec:
  - type: command
    run: "npm test -- --grep auth"
    expect: exit_code 0
    
  - type: file-contains
    path: src/auth/password.ts
    pattern: "bcrypt"
    
  - type: agent
    name: login-flow
    prompt: |
      1. POST /api/login with valid creds
      2. Verify JWT in response
      3. POST with wrong password
      4. Verify 401 + helpful error
    generate_test: true
```

### Step 2: Build

```
/eval build auth
```

Spawns builder agent → implements → spawns verifier → checks → iterates until pass.

### Step 3: Run Generated Tests (Forever)

```bash
pytest tests/generated/
```

Agent checks become deterministic tests. First run costs tokens. Future runs are free.

## Commands

| Command | What it does |
|---------|--------------|
| `/eval list` | List all evals |
| `/eval show <name>` | Display spec |
| `/eval build <name>` | Build + verify loop |
| `/eval verify <name>` | Just verify, no build |

## Why Context Isolation Matters

**Without isolation:**
```
Main Claude context:
  - All verification logic
  - All implementation code  
  - All error history
  - Context bloat → degraded performance
```

**With isolation:**
```
Builder context: building spec + current failure only
Verifier context: verification spec + current code only
Main Claude: just orchestration
```

Each agent gets exactly what it needs. Nothing more.

## Check Types

**Deterministic** (fast, no agent):
```yaml
- type: command
  run: "npm test"
  expect: exit_code 0
  
- type: file-contains
  path: src/auth.ts
  pattern: "bcrypt"
```

**Agent** (semantic, generates tests):
```yaml
- type: agent
  name: ui-login
  prompt: "Navigate to /login, submit form, verify redirect"
  evidence:
    - screenshot: after-login
    - url: contains "/dashboard"
  generate_test: true
```

Agent checks produce evidence (screenshots, responses) and become executable tests.

## Directory Structure

```
.claude/
├── skills/eval/       # Generates specs
├── agents/
│   ├── eval-builder.md
│   └── eval-verifier.md
├── commands/eval.md
└── evals/
    ├── auth.yaml
    └── .evidence/     # Screenshots, logs

tests/generated/       # Tests from agent checks
```

## Requirements

- Claude Code
- For UI testing: `npm install -g @anthropic/agent-browser`

## License

MIT
