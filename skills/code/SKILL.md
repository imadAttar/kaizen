---
name: code
description: "Full resolution pipeline: orchestrate /investigate or /analyze, then /implement, /verify, and corrections in a single flow. Use this skill whenever the user wants end-to-end resolution of a bug or feature — from diagnosis to commit-ready code. Accepts free text, ticket ID, or URL. Also use when the user says 'fix this', 'resolve this ticket', 'corrige ça', 'résous ce bug', 'implement and review', or pastes a ticket and expects a complete solution."
user-invocable: true
argument-hint: "<problem description | ticket ID | URL>"
---

# Code — Full Pipeline

Orchestrate the full dev workflow: pre-check → diagnose → implement → test → review → commit.

## Input

$ARGUMENTS

Accepts: free text, ticket ID/URL (Jira, GitHub, GitLab), bug description, PR link, Slack thread link.

## Adaptive model selection

/code orchestrates multiple phases. Each phase delegates to an agent with the right model — never inline.

| Phase | Model |
|-------|-------|
| **Pre-check** (git status, env) | `model: "haiku"` (trivial checks) |
| **Diagnose** (/investigate) | Follows investigate's own triage (haiku/sonnet/opus) |
| **Implement** | `model: "sonnet"` (best speed/quality for code writing) |
| **Review** | Follows review's own triage (haiku/sonnet/opus) |
| **Corrections** | `model: "sonnet"` |

**Override:** If the user specifies a model explicitly, use that model for all phases.

## Progress Display

At EACH phase transition, display a progress banner:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase N/6 — PHASE_NAME
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Phase 0 — PRE-CHECK

Before any work, verify the environment is ready:

1. **Working tree status**: run `git status`. If uncommitted changes exist:
   - List the modified files
   - Ask the user (in their language): "Uncommitted changes exist. Stash, commit, or continue anyway?"
   - If user says stash → `git stash push -m "pre-code-pipeline"`
   - If user says continue → proceed but warn that changes will mix
2. **Branch strategy**: check the current branch
   - If on `main`/`master`/`develop` → propose creating a feature branch: `git checkout -b <type>/<short-description>`
   - If already on a feature branch → proceed
   - If user declines branch creation → proceed on current branch

## Phase 1 — DIAGNOSE

### Step 1: Parse the input

Delegate to the chosen skill's input parsing (adaptive: MCP → CLI → ask user to paste).
The sub-skills handle all input formats: Jira, GitHub, GitLab, PR, CI run, free text.

If a tool or access is unavailable, the sub-skill will ask the user to provide the information. Do not block the pipeline.

### Step 2: Classify the work type

After reading the input, EXPLICITLY explain your classification reasoning:

```
**Classification**: [bug / feature / refactoring / exploration]
**Why**: [1-2 sentences explaining what in the input led to this choice]
**Skill**: `/investigate` (root cause analysis) OR `/analyze` (implementation plan)
**Estimated complexity**: small (1-3 files) / medium (4-10 files) / large (10+ files)
```

Decision criteria:
- **Bug / regression / error / incident** → `/investigate` — focus on root cause, reproduction, fix
- **Feature / evolution / refactoring / exploration** → `/analyze` — focus on plan, impact, complexity
- If ambiguous → ask the user before proceeding

### Step 3: Execute the chosen skill

Apply the selected skill's protocol.

### CHECKPOINT 1 — Diagnostic validation

Present the output of `/investigate` or `/analyze`. Include:
- The diagnostic/plan summary
- Estimated complexity
- For bugs: reproduction status (reproduced / code analysis only / awaiting user confirmation)
- For features: testability assessment (auto / manual / mixed)
- Any information gaps that the user could fill

**Wait for user validation before continuing.** The user may:
- Validate → proceed to Phase 2
- Provide additional info → re-run relevant parts of Phase 1
- Adjust scope → update the plan before proceeding

## Phase 2 — IMPLEMENT

Apply `/implement` protocol on the validated plan.

`/implement` handles:
- Scope confirmation with step dependencies
- Batch execution with progress reporting for large plans
- Compilation checks between batches
- Test writing (auto-runnable tests + manual test documentation)

**Failure handling** (managed by `/implement`, escalated to `/code` if unresolved):
1. Stop immediately — do not continue with broken state
2. Report: which steps succeeded, which failed, and why
3. Propose: fix the blocker, adjust the plan, or rollback with `git checkout -- <files>`
4. Wait for user decision before resuming

## Phase 3 — TEST

`/implement` already writes and runs tests it can execute (Phase 3 of `/implement`). This phase handles what `/implement` couldn't:

1. **Check `/implement`'s test report** — read the "Tests" section from `/implement`'s output:
   - If all auto-tests passed and no manual tests needed → proceed to Phase 4
   - If auto-tests had failures → they should already be fixed by `/implement` (2 attempts). If still failing, diagnose here.

2. **Run broader test suite** if not already done by `/implement`:
   - Module-level or full test suite to catch indirect regressions
   - Only if CLI runner is available (mvn test, npm test, pytest, etc.)
   - If unavailable, skip — `/implement` already ran the targeted tests

3. **Manual test checklist** — consolidate all `[manual]` items from `/implement`'s report and `/analyze`'s plan:
   - Present a numbered checklist to the user with specific commands/steps
   - Ask for confirmation before proceeding to Phase 4
   - If no manual tests needed → proceed directly

This avoids re-running tests that `/implement` already executed.

## Phase 4 — REVIEW

Apply `/verify` protocol.

`/verify` reports findings with severity (P1/P2/P3) and a correction plan if needed.

### If GOOD TO COMMIT → Phase 5
### If FIX NEEDED:
1. Apply the correction plan by re-running `/implement` on the fixes (not by `/verify` itself)
2. Re-run Phase 3 (test) + Phase 4 (review)
3. Max 2 correction iterations before escalating to user

## Phase 5 — FINALIZE

```
## Summary

### Environment
- Branch: [branch name]
- Stashed: yes/no

### Diagnostic
- Type: bug / feature / refactoring
- Source: [ticket or description]
- Root cause / Goal: [one sentence]
- Complexity: small / medium / large

### Implementation
- Files modified: N
- Tests added/updated: N

### Tests
- Auto: N passed, M failed
- Manual verification: [checklist for user, if any]

### Review
- Verdict: GOOD TO COMMIT
- Correction iterations: 0/1/2

### Ready for
- `/commit` — commit changes
- `/review` — full branch review (optional, before PR)
- `/git:create-pr` — create pull request
```

### CHECKPOINT 2 — Final summary

Present the summary. Ask (in the user's language): "Ready to `/commit`?"

If stash was created in Phase 0, remind the user to `git stash pop` after the commit.

## Resuming a broken pipeline

If the user says "continue", "resume", "where were we", or the conversation was interrupted mid-pipeline:

1. Check `git status` and `git diff` to understand current state
2. Look at conversation context for the last completed phase
3. Present a brief status:
   ```
   Pipeline resumed.
   - Last completed phase: Phase N — [name]
   - Current state: [uncommitted changes / tests pending / review pending]
   - Next step: Phase N+1 — [name]
   ```
4. Ask the user to confirm before continuing from the next phase

This allows recovery without restarting the entire pipeline.

## Rules

- **2 checkpoints**: post-diagnostic and final summary. These are the user's control points — skipping them means the user loses visibility into what's happening.
- **Diagnose before implementing** — implementing without a validated diagnostic risks solving the wrong problem, which wastes more time than the diagnostic itself.
- **Testing is mandatory** — Phase 3 adapts to what's feasible (auto/manual/gap), but it's always present. Even documenting "what the user should test manually" counts.
- **Delegate to skills** — do not duplicate their logic. Apply their protocols directly. This keeps the orchestrator lean and the sub-skills maintainable.
- **Strict scope** — no improvements beyond the plan. Scope creep in an automated pipeline compounds unpredictably.
- **Max 2 correction loops** in Phase 4 before escalating to user — beyond 2 iterations, the issue is likely a plan flaw, not an implementation bug.
- **Fail fast** — on implementation failure, stop and report immediately. Continuing with broken state compounds errors and makes recovery harder.
- **Graceful degradation** — if tools, access, or environments are unavailable, ask the user to fill gaps rather than blocking. The pipeline must work in any context: a simple Node.js project, a complex Tycho/OSGi build, or a GUI-heavy desktop app.
- **Respond in the user's language** — all banners, questions, summaries, and templates must be in the user's language.
