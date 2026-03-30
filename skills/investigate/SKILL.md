---
name: investigate
description: "Structured investigation of a bug or unexpected behavior. Use this skill whenever the user reports a symptom, a regression, a crash, an error, a CI failure, or any unexpected behavior — even if they don't say 'investigate'. Also use when the user pastes a stack trace, error log, or says something like 'this doesn't work', 'it broke', 'why is this happening'. Focuses on root cause analysis before any fix."
user-invocable: true
argument-hint: "<symptom description | ticket ID | PR number>"
---

# Investigate

Structured investigation of a bug or unexpected behavior.

## Input

The user describes a symptom, a code review finding, or a suspected issue.
Examples:
- Bug report: "this method crashes on null input", "wizard crashes on Finish click"
- Code review finding: "this method calls getChild() 6 times per fragment — performance issue"
- Suspected regression: "this refactoring may have changed behavior"
- CI failure: a PR number or run ID (e.g. "3848", "gh run 12345")
- Ticket: a Jira, GitHub, or GitLab ticket ID or URL

### Input parsing

**Adaptive**: use whatever tool is available. If a MCP tool exists (Jira, GitHub, GitLab), use it. Otherwise fall back to CLI (`gh`, `glab`) or ask the user to paste the ticket content.

**If the input is a ticket** (Jira, GitHub issue, GitLab issue):
- Try to fetch via MCP or CLI. If unavailable, ask the user (in their language) to paste the ticket content.
- Extract: summary, description, comments, attachments list, linked issues
- If attachments seem critical (logs, stacktraces), ask the user for the local file path

**If the input is a PR number or CI run ID**:
1. `gh pr view <PR> --json statusCheckRollup` or `gh run view <ID> --log-failed`
2. If `gh` unavailable, ask the user to paste the failure output
3. Use the failure output as the symptom

**If the input is free text**: use as-is.

## Adaptive model selection

Before investigating, classify complexity to pick the right model. Always delegate to an agent with the selected model — never run inline.

| Complexity | Signals | Model |
|-----------|---------|-------|
| **Simple** | Clear error with file:line, single-file issue (NPE, null, import, typo), stack trace points to exact location | `model: "haiku"` |
| **Medium** | Logic error across 2-5 files, state management bug, async/callback issue, test failure with unclear cause | `model: "sonnet"` |
| **Complex** | "app freezes", "intermittent", "sometimes works", perf/security/architecture, cross-layer, no clear error, "find all bugs", vague multi-symptom | `model: "opus"` |

**How to classify:**
1. Read the symptom (1 sentence)
2. If ≤1 file + clear error → Simple. If 2-5 files + specific symptom → Medium. If cross-system or vague → Complex.
3. When in doubt, default to sonnet — best compromise between speed and quality.
4. Spawn an Agent with the selected model. Pass the full Protocol (Phase 0–4), Output format, and Rules sections as the agent prompt, prefixed with the user's symptom.

**Override:** If the user specifies a model explicitly, use that model regardless of classification.

## Protocol

### Phase 0: Confirm the issue is real (false positive detection)
Before any investigation, actively try to **disprove** the reported issue:

**For bug reports:**
- Is the behavior documented/expected?
- Do existing tests validate this behavior?

**For code review findings / performance claims:**
- **Trace the actual execution path** — don't trust the reviewer's description. Read the code yourself.
- **Check for caching** — does the called method cache its result? (lazy init fields, memoization, singletons)
- **Check for short-circuits** — does the code path actually reach the expensive operation, or does it exit early?
- **Distinguish similar-looking paths** — two methods with similar names may have very different costs
- **Verify the blast radius** — is there actually a caller that triggers the problematic path? Check with `grep` for callers, subclasses, overrides.

**For copyright/date/naming issues:**
- **Check git history** — use `git log --diff-filter=A` to find when the file was truly created.
- **Check the current date** — don't assume the year from context.

If the issue is a **false positive**, state it clearly with evidence and mark it [FALSE POSITIVE]. Do NOT proceed to fix phases.

Attempting a fix before confirming the issue is real risks introducing unnecessary changes — confirm first, then fix.

### Phase 1: Understand before acting
1. **Restate** the symptom in one clear sentence
2. **List 3+ hypotheses** for possible root causes
3. For each hypothesis, describe the command/read that will verify it
4. **Make NO code changes** during this phase

When hypotheses are independent, verify them **in parallel** using multiple Agent calls in a single message. Reserve sequential exploration for cases where one result informs the next query.

### Phase 1.5: Reproduction assessment

Evaluate whether the bug can be reproduced programmatically:

| Reproducibility | Action |
|-----------------|--------|
| **CLI/script reproducible** (unit test, API call, script) | Write a minimal reproducer and run it |
| **Requires runtime environment** (app server, OSGi, GUI) | Ask the user (in their language) to reproduce the bug and confirm the symptom. Suggest specific steps. |
| **Cannot reproduce** (intermittent, env-specific, prod-only) | Proceed with code analysis only. State clearly that the investigation is code-analysis-only, no reproduction available. |
| **Needs user info** (logs, config, env details) | Ask the user to provide the missing context before proceeding |

**Do not block on reproduction.** If the user can't reproduce or doesn't have the info, continue with code-level analysis and lower confidence accordingly.

### Phase 2: Trace the data flow
Identify and document the complete code path involved:

```
Entry point (UI/Handler/Command/API)
  -> Service/Manager called
    -> Store/Repository accessed
      -> Operation performed (export, build, save...)
        -> Result produced
```

Use LSP if available (go-to-definition, find-references), otherwise fall back to Grep/Read.

Document every file and method traversed, and note the verification method used.

**Comparing parallel code paths**: When the bug involves two ways to reach the same outcome (e.g. clone vs switch, import vs migration, sync vs async), build a side-by-side comparison table:
| Step | Path A | Path B |
|------|--------|--------|
| Trigger | ... | ... |
| Migration call | ... | ... |
| Error handling | ... | ... |

**Reading log files**: When analyzing large logs (>200 lines), always start with a targeted Grep (`ERROR|Exception|STACK|migration|Closing|Starting`) to find the hot zones, then Read with offset only on relevant sections. Never read sequentially from line 1.

### Phase 2.5: Timeline (when did it break?)

When the bug is a regression, establish when it was introduced:
- `git log --oneline --since="2 weeks ago" -- <affected files>` to find recent changes
- If a specific commit is suspected, `git show <commit>` to confirm
- If the user can provide "it worked on version X", use that as a boundary

Skip this phase if the bug is a known design flaw, not a regression.

### Phase 3: Isolate the cause
- Update each hypothesis with [CONFIRMED] / [ELIMINATED] / [FALSE POSITIVE] / [NEEDS MORE]
- If all initial hypotheses are eliminated, formulate new ones based on findings
- **If the issue turns out to be a false positive**: stop here. Explain WHY with code evidence. Do NOT proceed to Phase 4.
- **If the bug is not reproducible or evidence is inconclusive**: state it clearly, explain what was tried, and ask the user for more context (logs, steps to reproduce, environment)
- Converge on the root cause(s) with concrete evidence (source code, logs, observed behavior). If multiple causes are chained (cause A triggers cause B triggers the symptom), document the full chain.

### Phase 3.5: Similar pattern scan

Once the root cause is confirmed, scan for the same bug pattern in nearby code — the same anti-pattern that caused one bug often appears multiple times in the same file or module, written by the same author at the same time.

1. **Same file**: Grep the confirmed file for the same pattern (e.g., if the bug is `.get(0)` without `isEmpty()`, search for all `.get(0)` in that file)
2. **Same package/module**: Quick grep of sibling files for the same pattern
3. **Report as "Related findings"** in the output — separate from the main root cause, so they don't confuse the scope but aren't lost either

This catches bugs like: a resource leak in `openManifest()` often means `extractBundleName()` in the same class has a null-safety issue too, because both were written with the same assumptions.

### Phase 4: Propose the fix
- Explain the root cause and the full chain leading to the bug
- Propose the MINIMAL fix needed
- Indicate the exact files and lines to modify
- **Estimated complexity**: small (1-3 files) / medium (4-10 files) / large (10+ files)
- If Phase 3.5 found related issues, list them as **"Related findings (out of scope)"** with file:line references — the user decides whether to include them
- **Wait for user validation** before editing anything

## Output format

```
## Symptom
[One-sentence restatement of the reported bug]

## Reproduction
[Reproduced by script/test | Confirmed by user | Code analysis only (no reproduction) | Awaiting user confirmation]

## Hypotheses
| # | Hypothesis | Verification | Verdict |
|---|-----------|--------------|---------|
| 1 | ... | ... | [CONFIRMED] / [ELIMINATED] / [FALSE POSITIVE] |

## Verdict: REAL ISSUE / FALSE POSITIVE
[If FALSE POSITIVE: explain why with code evidence, then STOP — no root cause / fix sections needed]

## Timeline (only if regression)
- Last known working state: [commit/version/date]
- Likely introduced by: [commit or change description]

## Root cause (only if REAL ISSUE)
[Explanation with evidence: file:line references, code snippets]
[If multiple chained causes: list them in causal order — cause 1 leads to cause 2 leads to the symptom]

## Data flow (only if REAL ISSUE)
Entry point -> ... -> Bug location -> Incorrect result
[If comparing two code paths, include the side-by-side table from Phase 2]

## Proposed fix (only if REAL ISSUE)
- **File**: `path/to/File.java:42`
- **Change**: [description of the minimal fix]
- **Complexity**: small / medium / large
[If multiple root causes: one fix per cause, ordered by priority]

## Related findings (out of scope) [omit if none]
[Same anti-pattern found elsewhere in the file/module — listed for awareness, not for immediate fix]
- `file:line` — [brief description of the same pattern]

## Confidence assessment
| Aspect | Confidence | Evidence |
|--------|-----------|----------|
| Symptom understood | X% | [what confirms it] |
| Root cause identified | X% | [file:line, code proof] |
| All code paths covered | X% | [which paths verified, which not] |
| Edge cases considered | X% | [which checked, which remain] |
| Fix completeness | X% | [what could be missed] |
| **Overall** | **X%** | |

If any aspect is below 80%: explicitly state what is missing and what action would raise confidence (reproduce, read specific file, check logs, ask user).
```

## Rules

- **False positive bias**: Assume the issue might be a false positive until proven otherwise — it's better to correctly identify a false positive than to propose an unnecessary fix.
- **Evidence-based only**: Every claim must be backed by a file:line reference. If you can't find evidence, say "unverified" not "likely". This prevents wasted effort on phantom bugs.
- **Graceful degradation**: If a tool/access is unavailable (no Jira MCP, no LSP, can't run tests, can't reproduce), adapt and continue with what's available. Ask the user to fill gaps rather than blocking — the investigation should always make progress.
- **Check caching/lazy-init**: Before claiming a performance issue, check if the called method caches its result (look for `if (field == null) { field = ... }` patterns). Many apparent "6 calls" are actually 1 real call + 5 cache hits.
- **Check git history for context**: Before claiming a file is "new", check `git log --diff-filter=A`. Before claiming a copyright year is wrong, verify the actual creation date.
- **Propose, don't apply**: Only propose fixes. Wait for user validation — the user may have context you don't (e.g., a related change in progress, a constraint from another team).
- **End with the confidence assessment table**: If confidence is low on any axis, explicitly list what would raise it before proposing a fix. Below 70% overall, state what's missing rather than guessing.
- Stay within the scope of the reported bug — no drive-by refactoring.
- Respond in the same language as the user.
