---
name: review
description: "Structured code review of the current branch. Adapts to project context: multi-agent if agents exist, applies project conventions from rules. Triggers on: review, code review, review branch, review PR, check code quality, revue de code, revue PR, revue de branche, qualité du code."
user-invocable: true
argument-hint: "[optional: base branch, PR number, or specific files]"
---

# Code Review

Structured, multi-axis code review that adapts to the project context.

## Adaptive model selection

Before reviewing, classify the scope to pick the right model. Always delegate to an agent with the selected model.

| Scope | Signals | Model |
|-------|---------|-------|
| **Small** | ≤3 files changed, ≤100 lines diff, single concern | `model: "haiku"` |
| **Medium** | 4-15 files, 100-500 lines, 1-2 concerns | `model: "sonnet"` |
| **Large** | 15+ files, 500+ lines, cross-module, architecture change, security-sensitive | `model: "opus"` |

**How to classify:** Run `git diff --stat` first. Count files and lines. If security-sensitive files (auth, crypto, permissions) are in the diff, bump to Large regardless of size. When in doubt, default to sonnet.

**Override:** If the user specifies a model explicitly, use that model regardless of classification.

## Step 1: Detect context

Before starting, detect what's available:

```
Has .claude/agents/ with domain agents?
  → YES: Multi-agent mode (partition files by domain, parallel review)
  → NO:  Single-agent mode (review all files sequentially)

Has .claude/rules/?
  → YES: Load project conventions (testing, code style, OSGi, etc.)
  → NO:  Use generic best practices only

Has CLAUDE.md?
  → YES: Read project conventions, naming patterns, architecture
  → NO:  Infer from codebase
```

Announce the detected mode briefly:
> **Mode**: multi-agent / single-agent | **Conventions**: [loaded rules] | **Base**: origin/<branch>

## Step 2: Identify scope

- If user specifies files → review those files
- If user says "review PR" or gives a PR number → `gh pr diff <number>` or detect base via `gh pr view`
- If user says "review branch" or just `/review` → detect base branch:
  1. Check if branch tracks a remote: `git rev-parse --abbrev-ref @{upstream}`
  2. Check PR base: `gh pr view --json baseRefName -q .baseRefName`
  3. **Never assume `dev` or `main`** — always check the actual base
- `git log --oneline origin/<base>..HEAD` for commit list
- `git diff origin/<base>...HEAD` for full diff

For large diffs (>500 lines), prioritize by risk: API/auth > data models > business logic > UI > config.

## Step 3: Review

### Multi-agent mode (when `.claude/agents/` exists)

1. **Partition files by domain**: Match modified files to agent scopes (read each agent's `## Your scope` section)
2. **Launch parallel agents**: One agent per domain group. Each agent receives:
   - The git diff for its files (so it knows WHAT changed)
   - The list of files to read in full
   - Explicit LSP verification tasks
   - Instruction to read only changed files, not entire plugins
3. **Cross-cutting checks** (orchestrator, in parallel with agents):
   - `findReferences` on deleted/renamed methods → detect dead code
   - `grep` on duplicated method names → detect logic duplication
   - Verify cancel/undo paths for EMF mutations (if applicable)
4. After agents report, verify all 6 axes are covered. Handle gaps directly.

### Single-agent mode

Review all files sequentially across the 6 axes.

### The 6 axes

1. **Security** — Injection, auth gaps, secrets in code, unsafe deserialization
2. **Bugs & Correctness** — Logic errors, null access, race conditions, unhandled errors
3. **Performance** — N+1 queries, redundant computations, memory leaks
4. **Maintainability** — Dead code, long functions (>30 lines), magic numbers, inconsistent naming
5. **Architecture** — Separation of concerns, circular deps, logic in wrong layer
6. **Testing** — Untested critical paths, implementation-coupled tests, missing edge cases

## Step 4: Apply project conventions

If `.claude/rules/` or CLAUDE.md define project conventions, **do NOT flag established patterns as issues**. Examples:
- If the project uses JUnit 4, don't flag it as outdated
- If methods must be `public` for OSGi, don't flag as "should be package-private"
- If a pattern is used consistently across the codebase, it's a convention, not a smell

## LSP strategy

1. Try LSP first (hover, findReferences, goToDefinition) — ~50 tokens
2. Fall back to grep if LSP fails — ~500 tokens
3. Read full file only when needed — ~2000 tokens

## False positive prevention

Before reporting an issue, actively try to disprove it:
- Check for caching/lazy init/memoization
- Check for short-circuits
- Check established patterns (CLAUDE.md, existing code)
- Check git history (`git log` on the function)

If you can't disprove it with evidence, report as **hypothesis**, not bug.

## Output format

For each file:

### `path/to/File.java`
| Sev | Line | Issue | Suggestion | Verified |
|-----|------|-------|------------|----------|
| P1  | 42   | ...   | ...        | LSP/grep/read/hypothesis |

**Severities:**
- **P1**: Bugs, security flaws, data loss, crashes. Only real problems.
- **P2**: Questionable logic, missing null checks, resource leaks, poor error handling.
- **P3**: Naming, readability, minor style.

## Final summary

```
## Health: A/B/C/D/F

### Summary table
| Severity | Count | Top Issue |
|----------|-------|-----------|
| P1 | X | ... |
| P2 | X | ... |
| P3 | X | ... |

### Verification stats
| Method | Count |
|--------|-------|
| LSP verified | X |
| Grep verified | X |
| Read verified | X |
| Hypothesis | X |

### Dead code
[Methods/classes with 0 callers, if checked]

### Positive observations
[2-3 things done well — always include]

### Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
[1 sentence justification]
```

**Health score:**
- **A** = No P1, 0-1 P2 — ship it
- **B** = No P1, 2+ P2 — solid but needs polish
- **C** = 1 P1 or 3+ P2 — fix before merge
- **D** = 2+ P1 — significant rework needed
- **F** = Security breach, data loss risk, or fundamentally broken

## Rules

- **Always cite file:line** when raising an issue
- **Always suggest a fix**, not just flag the problem
- **Severity matters**: don't block a PR for a naming nitpick
- **Acknowledge good code**: every review must include positives
- **No false positives**: unsure → "hypothesis", not "bug"
- **Match project conventions**: don't enforce preferences over codebase patterns
- **Language**: respond in the user's language
- Do NOT auto-fix code unless the user explicitly asks
