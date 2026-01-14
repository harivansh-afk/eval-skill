---
name: eval
description: Generate evaluation specs for code verification. Use when setting up tests, defining acceptance criteria, or creating verification checkpoints before implementing features. Triggers on "create evals", "define acceptance criteria", "set up verification", or "how will we know this works".
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Eval Skill

Generate evaluation specs (YAML) that define what to verify. I do NOT run verification — that's the verifier agent's job.

## My Responsibilities

1. Understand what needs verification
2. Ask clarifying questions
3. Generate `.claude/evals/<name>.yaml` specs
4. Define checks with clear success criteria

## What I Do NOT Do

- Run tests or commands
- Collect evidence
- Generate test code
- Make pass/fail judgments

## Eval Spec Format

```yaml
name: feature-name
description: What this eval verifies

# Where generated tests should go
test_output:
  framework: pytest  # or vitest, jest
  path: tests/generated/

verify:
  # === DETERMINISTIC CHECKS ===
  # These run as-is, fast and reliable
  
  - type: command
    run: "npm test -- --grep 'auth'"
    expect: exit_code 0
    
  - type: file-exists
    path: src/auth/login.ts
    
  - type: file-contains
    path: src/auth/login.ts
    pattern: "export function login"
    
  - type: file-not-contains
    path: src/config.ts
    pattern: "API_KEY=sk-"

  # === AGENT CHECKS ===
  # Verifier agent runs these, collects evidence, generates tests
  
  - type: agent
    name: login-flow  # Used for evidence/test naming
    prompt: |
      Verify login with valid credentials:
      1. Navigate to /login
      2. Enter test@example.com / password123
      3. Submit form
      4. Verify redirect to /dashboard
      5. Verify welcome message visible
    evidence:
      - screenshot: after-login
      - url: contains "/dashboard"
      - element: '[data-testid="welcome"]'
    generate_test: true  # Verifier should write a test for this
```

## Check Types

### Deterministic (Verifier runs directly)

```yaml
# Command with exit code
- type: command
  run: "pytest tests/auth/"
  expect: exit_code 0

# Command with output check
- type: command
  run: "curl -s localhost:3000/health"
  expect: 
    contains: '"status":"ok"'

# File existence
- type: file-exists
  path: src/feature.ts

# File content
- type: file-contains
  path: src/feature.ts
  pattern: "export function"
  
# Negative file content
- type: file-not-contains
  path: .env.example
  pattern: "real-api-key"
```

### Agent (Verifier interprets, collects evidence, may generate test)

```yaml
- type: agent
  name: descriptive-name
  prompt: |
    Clear instructions for what to verify.
    Be specific about:
    - What to do
    - What to check
    - What success looks like
  evidence:
    - screenshot: step-name       # Capture screenshot
    - url: contains "pattern"     # Check URL
    - element: "selector"         # Check element exists
    - text: "expected text"       # Check text visible
    - response: status 200        # Check HTTP response
  generate_test: true|false       # Should verifier write a test?
```

## Workflow

### User asks to create evals

**User**: Create evals for user authentication

**Me**: I'll define verification criteria. Questions:
1. Auth method? (email/password, OAuth, magic link?)
2. Should I verify UI, API, or both?
3. Security requirements? (password hashing, rate limiting?)

**User**: Email/password, both UI and API, must hash passwords

**Me**: Creating `.claude/evals/auth.yaml`:

```yaml
name: auth
description: Email/password authentication with UI and API

test_output:
  framework: pytest
  path: tests/generated/

verify:
  # --- Deterministic ---
  - type: command
    run: "npm test -- --grep 'auth'"
    expect: exit_code 0
    
  - type: file-contains
    path: src/auth/password.ts
    pattern: "bcrypt|argon2|scrypt"
    
  - type: file-not-contains
    path: src/auth/
    pattern: "password.*=.*plaintext"

  # --- Agent: API Login ---
  - type: agent
    name: api-login
    prompt: |
      Test login API:
      1. POST /api/auth/login with {"email": "test@example.com", "password": "password123"}
      2. Verify 200 response with JWT token
      3. POST with wrong password
      4. Verify 401 with helpful error message
    evidence:
      - response: status 200
      - response: has "token"
      - response: status 401
    generate_test: true

  # --- Agent: UI Login ---
  - type: agent
    name: ui-login
    prompt: |
      Test login UI:
      1. Go to /login
      2. Enter valid credentials
      3. Submit
      4. Verify redirect to /dashboard
      5. Verify welcome message
    evidence:
      - screenshot: login-page
      - screenshot: after-submit
      - url: contains "/dashboard"
      - element: '[data-testid="welcome"]'
    generate_test: true

  # --- Agent: Error Handling ---
  - type: agent
    name: login-errors
    prompt: |
      Test error handling:
      1. Submit empty form - verify field validation
      2. Submit wrong password - verify error message is helpful
      3. Verify password field clears but email persists
    evidence:
      - screenshot: validation-errors
      - screenshot: wrong-password
      - text: "Invalid email or password"
    generate_test: true
```

Now run `/eval verify auth` to have the verifier agent:
1. Run deterministic checks
2. Execute agent checks with evidence collection
3. Generate tests in `tests/generated/`
4. Report results

## Best Practices

### Be Specific in Prompts
```yaml
# ❌ Vague
prompt: "Make sure login works"

# ✅ Specific
prompt: |
  1. Navigate to /login
  2. Enter test@example.com in email field
  3. Enter password123 in password field
  4. Click submit button
  5. Verify URL is /dashboard
  6. Verify text "Welcome" is visible
```

### Specify Evidence
```yaml
# ❌ No evidence
- type: agent
  prompt: "Check the UI looks right"

# ✅ Evidence defined
- type: agent
  prompt: "Check login form has email and password fields"
  evidence:
    - screenshot: login-form
    - element: 'input[type="email"]'
    - element: 'input[type="password"]'
```

### Enable Test Generation for Repeatables
```yaml
# UI flows → generate tests (repeatable)
- type: agent
  name: checkout-flow
  generate_test: true

# Subjective review → no test (human judgment)
- type: agent
  name: code-quality
  generate_test: false
  prompt: "Review error messages for helpfulness"
```

## Directory Structure

After running evals:

```
.claude/
├── evals/
│   ├── auth.yaml              # Eval spec (I create this)
│   └── .evidence/
│       ├── auth/
│       │   ├── ui-login-001.png
│       │   ├── ui-login-002.png
│       │   └── evidence.json   # Structured evidence
│       └── ...
tests/
└── generated/
    ├── test_auth_api_login.py   # Verifier generates
    ├── test_auth_ui_login.py    # Verifier generates
    └── ...
```
