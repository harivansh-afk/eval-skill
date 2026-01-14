---
description: Run eval commands - list, show, or verify evals
argument-hint: list | show <name> | verify [name]
allowed-tools: Read, Bash, Task
---

# /eval Command

Interface for the eval system. I dispatch to the right action.

## Commands

### /eval list

List all eval specs:

```bash
echo "Available evals:"
echo ""
for f in .claude/evals/*.yaml 2>/dev/null; do
  if [ -f "$f" ]; then
    name=$(basename "$f" .yaml)
    desc=$(grep "^description:" "$f" | head -1 | sed 's/description: *//')
    printf "  %-20s %s\n" "$name" "$desc"
  fi
done
```

If no evals exist:
```
No evals found in .claude/evals/

Create evals by asking: "Create evals for [feature]"
```

### /eval show <name>

Display an eval spec:

```bash
cat ".claude/evals/$1.yaml"
```

### /eval verify [name]

Run verification. This spawns the `eval-verifier` subagent.

**With name specified** (`/eval verify auth`):

Delegate to eval-verifier agent:
```
Run the eval-verifier agent to verify .claude/evals/auth.yaml

The agent should:
1. Read the eval spec
2. Run all checks in the verify list
3. Collect evidence for agent checks
4. Generate tests where generate_test: true
5. Report results with evidence
```

**Without name** (`/eval verify`):

Run all evals:
```
Run the eval-verifier agent to verify all evals in .claude/evals/

For each .yaml file:
1. Read the eval spec
2. Run all checks
3. Collect evidence
4. Generate tests
5. Report results

Summarize overall results at the end.
```

### /eval evidence <name>

Show collected evidence for an eval:

```bash
echo "Evidence for: $1"
echo ""
if [ -f ".claude/evals/.evidence/$1/evidence.json" ]; then
  cat ".claude/evals/.evidence/$1/evidence.json"
else
  echo "No evidence collected yet. Run: /eval verify $1"
fi
```

### /eval tests

List generated tests:

```bash
echo "Generated tests:"
echo ""
if [ -d "tests/generated" ]; then
  ls -la tests/generated/
else
  echo "No tests generated yet."
fi
```

### /eval clean

Clean evidence and generated tests:

```bash
rm -rf .claude/evals/.evidence/
rm -rf tests/generated/
echo "Cleaned evidence and generated tests."
```

## Workflow

```
1. Create eval spec
   > Create evals for user authentication

2. List evals
   > /eval list
   
3. Show specific eval  
   > /eval show auth

4. Run verification
   > /eval verify auth
   
5. Check evidence
   > /eval evidence auth

6. Run generated tests
   > pytest tests/generated/
```

## Output Examples

### /eval list

```
Available evals:

  auth                 Email/password authentication with UI and API
  todo-api             REST API for todo management
  checkout             E-commerce checkout flow
```

### /eval verify auth

```
🔍 Eval: auth
═══════════════════════════════════════

Deterministic Checks:
  ✅ command: npm test -- --grep 'auth' (exit 0)
  ✅ file-contains: bcrypt in password.ts

Agent Checks:
  ✅ api-login: JWT returned correctly
     📄 Test: tests/generated/test_auth_api_login.py
  ✅ ui-login: Dashboard redirect works
     📸 Evidence: 2 screenshots
     📄 Test: tests/generated/test_auth_ui_login.py

═══════════════════════════════════════
📊 Results: 4/4 passed
```
