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

/code orchestrates multiple phases. Analysis and implementation phases delegate to sub-agents; Phase 0 and checkpoints run inline (no sub-agent, no model selection needed).

| Phase | Model |
|-------|-------|
| **Phase 0** (pre-check, inline) | — (no sub-agent spawned) |
| **Diagnose** (/investigate or /analyze) | Follows the sub-skill's own triage (haiku/sonnet/opus) |
| **Implement** | `model: "sonnet"` (best speed/quality for code writing) |
| **Verify** (/verify) | `model: "sonnet"` (scoped review, no deep architecture analysis) |
| **Corrections** | `model: "sonnet"` |

**Override:** If the user specifies a model explicitly, use that model for all phases.

## Progress Display

At EACH phase transition, display a progress banner. Phases 1–5 are the main work phases (Phase 0 is silent pre-check):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Phase N/5 — PHASE_NAME
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
   - If on `main`/`master`/`develop` → propose creating a feature branch: `git checkout -b <type>/<short-description-derived-from-input>`
   - If already on a feature branch → proceed
   - If user declines branch creation → proceed on current branch

## Phase 1 — DIAGNOSE

### Step 1: Classify the work type

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

### Step 2: Execute the chosen skill

Apply the selected skill's protocol. The sub-skill handles all input formats (Jira, GitHub, GitLab, PR, CI run, free text) and will ask the user if access is unavailable. Do not block the pipeline.

### CHECKPOINT 1 — Diagnostic validation

Present the output of `/investigate` or `/analyze`. Include:
- The diagnostic/plan summary
- Estimated complexity
- For bugs: reproduction status (reproduced / code analysis only / awaiting user confirmation)
- For features: testability assessment (auto / manual / mixed)
- Any information gaps that the user could fill

**Special case — FALSE POSITIVE**: If `/investigate` concluded the issue is a false positive, present the evidence clearly and **stop the pipeline here**. Ask the user to confirm whether to close the ticket or investigate further. Do not proceed to Phase 2.

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

`/implement` already ran targeted tests (new tests + related regression tests). This phase covers what it couldn't:

1. **If `/implement` reported failures** still unresolved after 2 attempts → diagnose and fix here before continuing.

2. **Broader regression check** — if a CLI runner is available and wasn't already triggered by `/implement`, run the module-level or full test suite to catch indirect regressions in unrelated parts of the code.

3. **Manual test checklist** — collect all `[manual]` items from two sources: `/implement`'s "Manual verification needed" list and the diagnostic plan's `[manual]` annotations. Deduplicate and present as a numbered checklist. Ask for user confirmation before proceeding to Phase 4. If there are none, proceed directly.

## Phase 4 — REVIEW

Apply `/verify` protocol.

`/verify` reports findings with severity (P1/P2/P3) and a correction plan if needed.

### If GOOD TO COMMIT → Phase 5
### If FIX NEEDED:
1. Apply the correction plan by re-running `/implement` on the fixes (not by `/verify` itself)
2. Re-run tests + `/verify` — these are internal correction iterations, do not display Phase banners again
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
