---
name: implement
description: Implement iOS/SwiftUI features from eval specs. Use when building iOS features. Triggers on "/implement", "build ios feature", or "implement [feature] for ios".
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task
---

# Implement Skill (iOS/SwiftUI)

I implement iOS features from eval specs. I build - I do NOT verify.

## Critical Rule

**NEVER test or verify my own work.** After implementation, I spawn the `eval-verifier` agent to check my work. This separation ensures honest verification.

## Workflow

```
Read eval spec -> Implement -> Spawn eval-verifier -> Report results
```

### Step 1: Find Eval Spec

Look for the eval in `.claude/evals/<name>.yaml`

If no eval exists, tell user to create one first:
```
No eval spec found for "<name>".
Run: /eval <name>
to create the building and verification spec first.
```

### Step 2: Read Building Spec

Extract from eval YAML:
- `building_spec.description` - what to build
- `building_spec.requirements` - specific requirements
- `building_spec.constraints` - rules to follow
- `building_spec.files` - suggested file paths

### Step 3: Reference SwiftUI Guide

Before implementing, check `.claude/axiom-skills-guide.md` for:
- SwiftUI patterns and conventions
- Project-specific iOS guidelines
- Architecture preferences (MVVM, etc.)

If guide doesn't exist, use standard SwiftUI best practices.

### Step 4: Implement

Build the feature following:
1. Requirements from eval spec
2. Constraints from eval spec
3. SwiftUI best practices
4. Project conventions

**iOS/SwiftUI Guidelines:**
- Use `@State`, `@Binding`, `@ObservedObject` appropriately
- Prefer `async/await` over completion handlers
- Use `@MainActor` for UI updates
- Keep Views small and composable
- Extract reusable components
- Use proper error handling with `Result` or `throws`

### Step 5: Spawn Verifier

After implementation complete, spawn the eval-verifier agent:

```
Task tool call:
  subagent_type: general-purpose
  prompt: |
    You are the eval-verifier agent. Read the agent instructions from:
    agents/eval-verifier.md

    Then verify the implementation against:
    .claude/evals/<name>.yaml

    Run all verification checks, collect evidence, and report pass/fail.
```

### Step 6: Handle Results

**If verifier passes:**
```
Implementation complete: <name>
All checks passed.

Files created:
  + path/to/file.swift

Files modified:
  ~ path/to/existing.swift
```

**If verifier fails:**
Read failure feedback, fix specific issues, re-spawn verifier.
Max 5 iterations.

## Output Format

```
Implementing: <name>
---

[Reading eval spec...]

Building Spec:
  - Requirement 1
  - Requirement 2

[Implementing...]

Files Created:
  + Sources/Features/Login/LoginView.swift
  + Sources/Features/Login/LoginViewModel.swift

Files Modified:
  ~ Sources/App/ContentView.swift

[Spawning verifier...]

---
Verification Results:
  [verifier output here]
```

## Example

User: `/implement auth`

1. Read `.claude/evals/auth.yaml`
2. Check `.claude/axiom-skills-guide.md` for iOS patterns
3. Implement:
   - `LoginView.swift` - SwiftUI form
   - `LoginViewModel.swift` - business logic
   - `AuthService.swift` - API calls
4. Spawn eval-verifier
5. Report results

## What I Do NOT Do

- Skip reading the eval spec
- Verify my own work (verifier does this)
- Collect evidence (verifier does this)
- Generate tests (verifier does this)
- Add features not in the spec
- Assume verification passed without running verifier
