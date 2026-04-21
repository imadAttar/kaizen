---
name: coach
description: "Maintenance skill for the Claude Code environment. Audits the full setup — skills, hooks, rules, memory, permissions, plugins, CLAUDE.md — scores it, and produces a prioritized list of concrete, ready-to-apply improvements."
when_to_use: "Use when the user asks to improve, audit, or maintain their Claude Code environment. English triggers: 'coach me', 'what am I missing', 'check my setup', 'optimize my CLAUDE.md', 'discover conventions', 'is my config good', 'health check', 'what could be better'. French triggers: 'audite mon setup', 'améliore ma config', 'que puis-je améliorer', 'check ma config', 'fais un check', 'optimise mon CLAUDE.md', 'c'est le bordel', 'ma config est-elle bonne'. Also use proactively when the user is struggling with repetitive instructions, missing automations, or an outdated config — even if they don't explicitly ask for a coach run."
argument-hint: "[skills|hooks|rules|rules-audit|memory|permissions|plugins|health|init|optimize|discover|all]"
---

# Claude Code Coach

Be a transparent coach — explain *why* each suggestion helps and let the user decide.

## Routing

The routing rules below check `$ARGUMENTS` (set when the skill is called as `/coach <mode>`). When `$ARGUMENTS` is empty or doesn't match a pattern (e.g., user sends a free-form message like "mon CLAUDE.md est le bordel"), infer the intended mode from the user's actual message before falling back to Default.

**Priority**: check more specific patterns BEFORE shorter ones. For example, `rules-audit` must be checked before `rules` (otherwise `/coach rules-audit` wrongly matches the basic `rules` rule). The list below is already ordered correctly — respect the order.

### Deep modes (most specific — check first)
- `$ARGUMENTS` contains "rules-audit" → Deep audit of `.claude/rules/` only: frontmatter coverage, cross-layer redundancy, pertinence scoring, ROI trimming. Read `references/rules-audit.md`. Does not touch CLAUDE.md.
- `$ARGUMENTS` contains "optimize" or "claude-md" → Deep CLAUDE.md + rules cleanup (self-update, bloat detection, rules audit, rewrite). Read `references/claude-md-optimize.md` section "Optimize Mode".
- `$ARGUMENTS` contains "discover" → Mine codebase + code reviews for conventions → generate `.claude/rules/`. Read `references/discover.md`.
- `$ARGUMENTS` contains "init" → Scaffold a minimal CLAUDE.md (fast, no deep analysis). Read `references/claude-md-optimize.md` section "Init Mode".

### Health mode (cross-cutting analysis)
- `$ARGUMENTS` contains "health" → Read `references/checklists/usage-stale-friction.md`. Run stale config detection, cross-reference analysis, friction detection, and trend analysis.

### Audit modes (single area)
- `$ARGUMENTS` contains "skills" → Read `references/checklists/skills.md`, audit skills only
- `$ARGUMENTS` contains "hooks" → Read `references/checklists/hooks.md`, audit hooks only
- `$ARGUMENTS` contains "rules" → Read `references/checklists/rules.md`, audit rules only
- `$ARGUMENTS` contains "memory" → Read `references/checklists/memory.md`, audit memory only
- `$ARGUMENTS` contains "permissions" → Read `references/checklists/permissions.md`, audit permissions only
- `$ARGUMENTS` contains "plugins" → Read `references/checklists/plugins.md`, audit plugins only

### Default (full audit)
- No arguments or "all" → Full audit across all areas. Read ALL checklist files in `references/checklists/`. If deep CLAUDE.md optimization is overdue (see Phase 0), suggest running it.

## Phase 0: Delta Detection

Check what changed since last coach run — this avoids re-suggesting things the user already addressed or declined.

1. Read `.claude/coach-history.md` in the **project directory** — extract:
   - **Last coach run**: date and score
   - **Last deep CLAUDE.md optimization**: date (tracked separately)
   - If `.claude/coach-history.md` doesn't exist, also check `${CLAUDE_SKILL_DIR}/references/history.md` as legacy fallback — if found there, migrate it to `.claude/coach-history.md` and overwrite the old file with a stub: a single line `Moved to .claude/coach-history.md` so subsequent runs don't re-migrate
2. If a previous run exists, note days since last run

3. **Check optimization staleness**: if last deep CLAUDE.md optimization was >3 weeks ago (or never), flag it as a priority suggestion: "Your CLAUDE.md and rules haven't been deeply optimized in X days — want me to run an optimization now?"
   - If the user accepts → switch to optimize mode, then resume the regular audit after
   - If the user declines → note the decline date, don't re-suggest for 2 weeks

4. Compare current state against last run's changes — focus on NEW gaps, not already-addressed items

5. If no history exists anywhere, treat as first run

## Phase 1: Detect Project Context

Auto-detect the project type to adapt suggestions:

```
Check for:
├── VCS type            → Detect .git/, .svn/, CVS/, .hg/ — adapt VCS-related suggestions to detected type
├── .claude/agents/     → Multi-agent project
├── .claude/rules/      → Rules-aware project (check scoping, duplication)
├── .claude/skills/     → Has project skills (check for user/project duplicates)
├── Build system        → pom.xml, package.json, Cargo.toml, pyproject.toml, Makefile, etc.
└── CLAUDE.md           → Has instructions (check conciseness, progressive disclosure)
```

Announce detected context briefly (the new score is computed later in Phase 4 — only show the previous score here):
> **Project**: [type] | **Last coach**: [date, X days ago] | **Last optimize**: [date, X days ago] | **Last score**: [X/10]

## Phase 2: Inventory Current Setup

Collect current state silently (no output yet):

1. **Settings** — Read `~/.claude/settings.json` and `.claude/settings.json` and `.claude/settings.local.json`
2. **Settings diff** — If `~/.claude/settings.json.bak` or `.claude/settings.local.json.bak` exists, compare with the corresponding current settings file to detect recent regressions (hooks removed, plugins disabled, permissions changed). This catches unintentional removals. (`settings.json.bak` is created automatically by Claude Code before writing to settings — it's a one-step rollback file.)
3. **Skills** — List `~/.claude/skills/` (user) and `.claude/skills/` (project)
4. **Hooks** — List `~/.claude/hooks/` and hook configs in all settings files. Cross-check: are there hook scripts on disk not wired in settings? Are there settings entries pointing to missing scripts?
5. **Rules** — List `.claude/rules/` — check for `paths:` frontmatter
6. **Memory** — Read memory index from project memory MEMORY.md
7. **CLAUDE.md** — Read all that exist: `~/.claude/CLAUDE.md` (user global), root `CLAUDE.md`, `CLAUDE.local.md`, and `.claude/CLAUDE.md` — count lines for each
8. **Permissions** — Check `permissions.allow` in all settings files
9. **Plugins** — Check `enabledPlugins` in settings. Note specifically whether any `skill-creator` plugin is enabled (regardless of marketplace) — this affects skill creation delegation in Phase 5.
10. **Usage log** — Use the **Read tool** (not Bash) to read `~/.claude/coach-usage-log.jsonl` if it exists. Prefer Read tool over Bash for reading files — shell commands like `tail`/`head`/`cat` may be intercepted or filtered by hooks (e.g. token optimization hooks) and can silently truncate or fail. If the file is absent or empty, note it in the report and suggest wiring the PostToolUse tracking hook (see hooks checklist) — without it, usage-based suggestions are unavailable.
11. **Disk footprint** — Check size of `~/.claude/` and flag large consumers (debug/, todos/, paste-cache/, session-env/) that can be cleaned up

## Phase 3: Analyze Gaps

For each area in scope, read the relevant checklist(s) from `references/checklists/` and compare against current state. Identify:

- **Missing essentials** — things most users benefit from
- **Workflow-specific gaps** — based on detected project type and usage patterns
- **Optimization opportunities** — existing config that could be improved
- **Skill duplication** — user-level skills that duplicate project-level skills (suggest adaptive merge)
- **Context cost** — skills/rules loaded but rarely used (suggest archiving)
- **Stale items** — memory entries older than 30 days, unused skills in usage log
- **Regressions** — things that existed in settings.bak but were removed from current settings (hooks, plugins, permissions)

For targeted modes (single area), read ONLY that area's checklist plus `usage-stale-friction.md` for cross-reference checks related to that area.

## Scoring Rubric

Compute the setup score deterministically from 10 binary criteria (each 0 or 1, sum = score out of 10). Determinism is the point — same state always yields the same score — so trends between runs are meaningful. If a criterion genuinely doesn't apply to this project (e.g., solo repo with no permissions needed), treat it as satisfied.

### Essentials (6 points)
1. **Completion notification** — A hook on `Stop` event is wired in settings
2. **Usage tracking** — A `PostToolUse` hook writes to `~/.claude/coach-usage-log.jsonl` (without it, usage-based suggestions are unavailable)
3. **Rules directory** — `.claude/rules/` exists and contains ≥ 1 rule file
4. **CLAUDE.md concise** — Root `CLAUDE.md` exists and is ≤ 150 lines (bloat threshold)
5. **Memory structured** — `MEMORY.md` exists and has ≥ 3 indexed entries
6. **Permissions allowlist** — `permissions.allow` is non-empty in at least one settings file

### Hygiene (2 points)
7. **No broken references** — Every file path mentioned in memory/rules/CLAUDE.md actually exists
8. **No regressions** — No hooks/plugins/permissions removed since the last `settings.json.bak` (or no bak file = first run, pass)

### Advanced (2 points)
9. **Token optimization** — RTK installed AND wired as a `PreToolUse` hook, OR user explicitly declined in `coach-history.md`
10. **Project-aware plugins** — ≥ 1 plugin relevant to the detected project is enabled (LSP for the main language, Context7 for doc-heavy stacks, etc.)

### Interpretation
- **9-10**: Excellent — minor polish only
- **7-8**: Solid — a few gaps to fill
- **5-6**: Functional but missing core automations
- **< 5**: Substantial gaps — suggest `/coach init` or `/coach optimize` first

### Trend tracking
Log the current score in `.claude/coach-history.md` at each run. The `↑/↓/=` arrow in Phase 4 compares current score to the last logged score.

## Phase 4: Present Suggestions

Output format — group by priority:

```
## Coach Report

### Context
- **Project**: [detected type] | **Last coach**: [date] | **Last optimize**: [date] | **Delta**: [X days]
- **Skills**: X user + Y project | **Rules**: Z (W scoped) | **Hooks**: N

### Setup Score: X/10
Brief assessment + trend vs last run (↑/↓/=).

### Quick Wins (< 2 min each)
| # | Area | Suggestion | Why |
|---|------|-----------|-----|
| 1 | ... | ... | ... |

### Recommended Improvements
| # | Area | Suggestion | Why | Effort |
|---|------|-----------|-----|--------|
| 1 | ... | ... | ... | ~Xmin |

### Advanced (power user)
| # | Area | Suggestion | Why | Effort |
|---|------|-----------|-----|--------|
| 1 | ... | ... | ... | ~Xmin |

### Already Great
- [list what's well configured — positive reinforcement]

### Usage Insights
- Skill adoption: X% (Y/Z tool calls) [trend: ↑/↓/=]
- Top skills: [list from actual usage log]
- Friction detected: [patterns if any]
- Unused skills: [list] — consider archiving

### Config Health
- Stale items: [rules/memory/agents referencing things that no longer exist]
- Cross-reference issues: [inconsistencies between config areas]
- Config growth: [X rules, Y skills — trend vs last run]
- Regressions: [things removed since last settings backup]
```

**Score >= 8/10 with few gaps**: Keep the report short. Say something like "Your setup is solid" and only list the 2-3 minor points. Don't force Advanced suggestions just to fill the template.

**Delta = 0 since last run**: If nothing meaningful changed since last coach run, say "Nothing new since last check" with the date, and only flag new stale items or regressions.

## Phase 5: Interactive Implementation

After presenting the report:

1. Ask: "Which suggestions would you like me to implement? (numbers, 'all quick wins', or 'skip')"
2. For each accepted suggestion, implement it directly (create files, update settings, etc.). **Settings writes**: follow the scope rules in `references/checklists/hooks.md` (section "Settings file hierarchy") — hooks coach creates on its own initiative go in `.claude/settings.local.json`; explicit user requests override and go wherever the user intends.
3. **Show, don't tell** — When a suggestion involves creating or modifying a file (rule, memory, CLAUDE.md), provide the complete file content ready to use, not just "create a file for X". The user should be able to approve and move on, not fill in blanks.
4. **Skill creation/modification — delegate to skill-creator** — When an accepted suggestion involves creating a new skill or making substantial changes to an existing one (new SKILL.md, or edits touching more than ~30% of the skill body), do NOT write the skill yourself. Instead:
   - **If a `skill-creator` plugin is enabled** (detected in Phase 2, any marketplace): hand off to `/skill-creator` with full context — skill name, objective, and the gap the coach identified. Say: "I'll delegate this to `/skill-creator` so it follows Anthropic's standards (evals, description optimization, iteration loop)."
   - **If skill-creator is NOT enabled but available in any plugin cache** (check `~/.claude/plugins/cache/*/skill-creator/`): offer to install it first — "skill-creator is available but not installed. Want me to install it so this skill gets proper evals and description optimization?" If the user accepts, install it then hand off. If they decline, fall back to writing the skill directly.
   - **If skill-creator is not installed and not cached**: note it in the report as a recommended plugin and fall back to writing the skill directly, with a disclaimer that evals and description optimization won't be applied.
5. After implementation, briefly confirm what was done
6. **Update `.claude/coach-history.md`** in the project directory:
   - Add accepted suggestions with today's date
   - Update "Last coach run" header with date and score
   - If a deep optimization was performed (init/optimize/discover), update "Last deep CLAUDE.md optimization" date
   - Create the file if it doesn't exist
   - Archive entries older than 30 days to `.claude/coach-history-archive.md`

## Coach Rules

- **Tone**: Match the user's language. Start with what's good, then improve. Coach, don't criticize.
- **Explain why**: Every suggestion needs a "Why" — connect to real benefit
- **Respect existing choices**: Don't suggest removing things the user intentionally configured
- **Concrete outputs**: Every suggestion must be specific and actionable. When proposing a new file (rule, memory, CLAUDE.md section), provide the full content — never leave placeholders like "[your preference here]". Use what you know from the current config and usage patterns to fill in real values.
- **Don't overwhelm**: Max 13 suggestions total per audit. Distribute across categories as needed
- **Idempotent**: Running `/coach` twice should not duplicate suggestions — always check `.claude/coach-history.md` first
- **History**: Log accepted/declined suggestions to `.claude/coach-history.md` in the project directory. When it exceeds 40 entries, archive entries older than 30 days to `.claude/coach-history-archive.md`
- **Adaptive skill principle**: When a user skill and project skill overlap, suggest merging into a single adaptive user skill with context detection — a skill that reads the current project context at runtime and adjusts its behavior accordingly (e.g., different lint commands per build system), rather than maintaining two separate skills

## Reference Files

Checklists are split by domain — read only what's needed for the current mode:
- `references/checklists/skills.md` — Skills gap detection
- `references/checklists/hooks.md` — Hook purpose coverage
- `references/checklists/rules.md` — Rule quality checks
- `references/checklists/memory.md` — Memory completeness + broken reference detection
- `references/checklists/permissions.md` — Permission discovery from usage
- `references/checklists/plugins.md` — Plugin coverage
- `references/checklists/claude-md.md` — CLAUDE.md quality checks
- `references/checklists/usage-stale-friction.md` — Usage patterns, stale config, cross-reference, friction (always read for full audit and health mode)

Deep-dive references (read only when the matching mode is triggered):
- `references/claude-md-optimize.md` — Full CLAUDE.md optimization pipeline (self-update, bloat, scan, generate, report, guardrails)
- `references/rules-audit.md` — Rules audit process (frontmatter, redundancy, pertinence scoring, ROI trimming)
- `references/discover.md` — Convention discovery from codebase + code reviews
