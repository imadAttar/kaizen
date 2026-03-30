---
name: implement
description: "Implement changes based on a prior diagnosis from /investigate or a plan from /analyze. Does not re-analyze — trusts the validated plan and executes it. Use this skill whenever the user wants to apply a plan, execute a fix, or says 'go', 'lance', 'applique', 'fais-le', 'implement this'. Also triggers on: implement, implementer, applique le fix, applique le plan, execute the plan."
user-invocable: true
argument-hint: "[optional: specific step or scope to implement]"
---

# Implement — Execute a validated plan

## Input

$ARGUMENTS

This skill expects a **prior diagnosis or plan** already present in the conversation context:
- A root cause + proposed fix from `/investigate`
- An implementation plan from `/analyze`
- Or an explicit description from the user

If no prior context exists, ask the user in their language: "What is the plan to implement?" Do not re-analyze from scratch — use `/investigate` or `/analyze` first.

## Protocol

### Phase 1: Confirm scope

Extract from the conversation context:
- **What to do**: the fix or plan steps
- **Files to modify**: from the proposed fix or implementation plan
- **Tests to add/update**: from the plan or inferred
- **Step dependencies**: which steps depend on others (from the plan's `Depends on` field)

Present a brief summary (in the user's language):
```
I will implement:
- [change 1] in `file:line`
- [change 2] in `file:line`
- Tests: [what to test]
- Execution order: [parallel groups and sequential dependencies]
```

Wait for user validation unless the scope is trivial (1-2 files, obvious fix) or the plan was already validated by an orchestrator's checkpoint (e.g., `/code` CHECKPOINT 1).

### Phase 2: Implement

Apply changes following project conventions:
- Follow `CLAUDE.md` (root or `.claude/`) and `.claude/rules/` if present for code style, conventions, etc.
- Follow existing patterns in the codebase (naming, structure, error handling)
- Strict scope — only what's in the plan. No "while I'm here" improvements.
- **Minor adjustments allowed**: imports, trivial type adaptations, or method signatures that the plan couldn't anticipate are OK without asking. If in doubt, ask.

For multi-step plans from `/analyze`:
- **Small** (1-5 steps): implement all in one pass
- **Large** (6+ steps): implement in batches, verify compilation after each batch, report progress:
  ```
  [Step 2/8] ✓ Created FooStore — compiles OK
  [Step 3/8] ✓ Updated FooHandler — compiles OK
  [Step 4/8] ✗ FooService — compilation error: missing import → fixing...
  ```

**Parallelization**: Before starting, analyze step dependencies from the plan. Steps that don't depend on each other can be implemented in parallel via Agent calls:
- 2 independent steps → 2 agents
- 3-4 independent steps → 3-4 agents
- Steps with dependencies → sequential, wait for the dependency to complete first
- **Steps that modify the same file must be sequential** — two agents writing to the same file will produce conflicts. Group same-file changes into one agent even if logically independent.

Example: "Add new Handler" and "Add i18n messages" are independent → parallel. "Update Handler to use new Store" depends on "Create new Store" → sequential.

**If something fails** (compilation error, test break): fix it within 2 attempts. If still failing, stop, report what broke and why, and ask the user before continuing. Do not silently diverge from the plan.

### Phase 3: Test & Verify

Adapt testing to what's available and feasible:

**Step 1: Assess test infrastructure**
- Does the project have a test framework set up? (check for test directories, test configs, existing tests)
- Can tests be run from CLI? (mvn test, npm test, pytest, etc.)
- Are some tests manual-only? (GUI, OSGi runtime, specific environment)

**Step 2: Write tests** for each change, following existing test patterns in the codebase:
- If test infra exists → write and run tests
- If test infra exists but tests require a specific runtime (OSGi, app server, GUI) → write the tests but flag them as `[manual]`: "These tests need to be run in [environment]. Please verify."
- If no test infra → skip writing tests, but document what SHOULD be tested

**Step 3: Run what's runnable**
1. Run new tests to confirm they pass (if auto-runnable)
2. Run existing tests related to modified files to detect regressions
3. Check compilation if applicable
4. If tests can't be run by Claude → tell the user what commands to run and what to verify

**Step 4: Formatting & linting**
If the project has a formatter/linter configured (check for .prettierrc, .eslintrc, checkstyle.xml, rustfmt.toml, .editorconfig, pyproject.toml, etc.):
- Run the formatter on modified files only (e.g., `npx prettier --write <files>`, `mvn checkstyle:check`)
- If a linter fails, fix the issues before proceeding
- If no formatter/linter is configured, skip — do not add one

**Step 5: Self-review**
Re-read the diff against the original plan — did we miss anything? Did we add anything not in the plan?

### Phase 4: Report

```
## Done
- [x] [change 1] — `file:line`
- [x] [change 2] — `file:line`
- [x] Tests added/updated

## Tests
- Auto-run: N passed, M failed
- Manual verification needed: [list what the user should test and how]

## Not done [omit if everything was implemented]
- [ ] [what was skipped and why]

## Ready for
- `/verify` — quick review of changes
- `/commit` — commit changes
```

## Rules

- **Trust the plan** — the prior diagnosis/plan was already validated by the user. Re-analyzing would waste time and context. If the plan seems wrong during implementation, stop and ask rather than silently diverging.
- **Strict scope** — implement only what's in the plan. Minor adjustments (imports, signatures) are OK because they're implicit requirements of the plan, not scope creep.
- **Fail fast** — on compilation or critical failure, stop and report immediately. Continuing with broken state compounds errors and makes recovery harder.
- **Graceful degradation** — if tests can't be run (no CLI runner, requires specific environment), document what needs manual verification instead of blocking. The user knows their environment better than you do.
- **Respond in the user's language** — all templates, confirmations, and reports must be in the user's language.
