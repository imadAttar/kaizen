---
name: verify
description: "Quick verification of changes just made by /implement. Validates correctness, side effects, and test coverage of the implementation against the original plan. Lighter than /review — scoped to the current session's changes only. Use this skill right after implementing changes to catch bugs before committing. Also triggers on: verify, vérify, check my changes, valide l'implémentation, vérifie le code, est-ce que c'est bon."
user-invocable: true
argument-hint: "[optional: specific file or concern to focus on]"
---

# Verify — Quick implementation review

Quick review of changes produced by `/implement`. Scoped to the current session's diff only.

## Input

$ARGUMENTS

This skill expects `/implement` to have run in the same conversation. It uses the conversation context to know what was planned vs what was implemented.

If no prior context exists, fall back to reviewing uncommitted changes (`git diff`).

## Protocol

### Phase 1: Collect the diff

Get all changes from this session:
```bash
git diff          # unstaged changes
git diff --cached # staged changes
git status        # lists new untracked files — do NOT skip this
```

If already committed:
```bash
git diff HEAD~1   # last commit
```

**Important**: `git diff` does NOT show new files. Always run `git status` and explicitly read any untracked files that belong to this session — they are part of the changes to review.

### Phase 2: Plan vs Implementation

Compare what was planned (from `/investigate` or `/analyze` output in the conversation) against what was actually implemented. If no plan is available in context, skip this phase and note it as a gap in the output.

| Planned change | Implemented? | Correct? |
|----------------|-------------|----------|
| [from plan] | yes/no/partial | ok/issue |

Flag any **drift** — changes that weren't in the plan, or planned changes that were skipped.
Minor adjustments (imports, type adaptations) are acceptable drift — only flag significant deviations.

### Phase 3: Impact check

For each modified file, verify:
1. **Callers** — Grep for all callers of modified methods. Are they still compatible?
2. **Side effects** — Does the change affect shared state, events, or configurations?
3. **Regression risk** — Could existing features break? Check related tests.

### Phase 4: Test review

1. Were tests added for the new/modified code?
2. Do the tests cover the **happy path** and at least one **error path**?
3. For `[manual]` tests (from `/investigate` Phase 1.5 or `/analyze` plan) — are they documented with clear verification steps for the user?
4. Are existing tests still passing? (check if `/implement` reported test results)

### Phase 5: Bugs & correctness

For each change in the diff, verify the logic:
- **Off-by-one errors**, wrong comparisons, inverted conditions
- **Null/empty handling** — can any input be null/undefined/None where not expected?
- **Resource leaks** — opened handles not closed (streams, connections, file descriptors, DB cursors, UI resources like SWT widgets)
- **Race conditions** — shared mutable state accessed from multiple threads/async contexts without synchronization
- **Error paths** — are errors caught and handled correctly, or silently swallowed? (try/catch, .catch(), error callbacks, Result types)

### Phase 6: Formatting & conventions check

If the project has a formatter/linter configured (.prettierrc, .eslintrc, checkstyle.xml, rustfmt.toml, .editorconfig, pyproject.toml, etc.):
- Check if modified files conform to project formatting rules
- Flag violations as P3 (minor)
- If no formatter/linter is configured, skip

### Phase 7: Performance quick-check

Only if the change touches hot paths (loops, data processing, DB queries, UI rendering):
- **O(n²) or worse** in loops over collections
- **N+1 queries** — DB calls inside loops
- **Unnecessary allocations** — objects created in tight loops that could be reused
- **Missing pagination/limits** — unbounded queries or list processing

Skip if changes are in cold paths (config, init, one-time operations).

### Phase 8: Quick security scan

Only for code at system boundaries (user input, external APIs, file I/O):
- Injection risks (SQL, XPath, command)
- Null/empty input handling
- Resource cleanup (streams, connections)

Skip if changes are purely internal logic.

## Output format

```
## Plan compliance
| Planned | Status | Notes |
|---------|--------|-------|
| ... | done/partial/missing/drift | ... |

## Findings
| Sev | File:line | Issue | Suggestion |
|-----|-----------|-------|------------|
| P1/P2/P3 | ... | ... | ... |

Omit this table entirely if no findings.

P1 = blocker (wrong behavior, data loss, security)
P2 = significant (perf regression, missing error handling, weak test)
P3 = minor (style, naming, non-critical improvement)

## Test coverage
- [x/missing] Tests for [change description]
- Manual verification needed: [list for user, if any]

## Verdict

**If no P1/P2 findings and plan is fully implemented:**
> GOOD TO COMMIT — [one sentence confirmation]. Ready for `/commit`.

**If P1/P2 findings or missing plan items:**
## Correction plan (ordered by priority: P1 first, then P2)
### Fix 1: [title] — P1
- **File**: `path/to/File.java:line`
- **Issue**: [what's wrong]
- **Fix**: [what to do]

### Fix 2: [title] — P2
- ...

> FIX NEEDED — [N] P1 and [M] P2 findings. The correction plan above will be applied by re-running `/implement`.
```

## Rules

- **Scoped** — only review this session's changes. Do not review pre-existing code.
- **Plan-first** — the plan is the source of truth. Significant drift from the plan is a finding.
- **No fixes** — report findings, do not apply changes. When used inside `/code`, the orchestrator applies corrections via `/implement`.
- **Fast** — this is a quick check, not a full `/review`. Skip deep architecture analysis.
- **Graceful degradation** — if test results aren't available (couldn't run tests), note it as a gap rather than blocking.
- **Respond in the user's language**.
