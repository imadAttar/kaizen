---
name: coach
description: "The maintenance skill for your Claude Code environment. Audits your full setup — skills, hooks, rules, memory, permissions, plugins, CLAUDE.md — scores it, and gives you a prioritized list of improvements with concrete, ready-to-apply outputs. Use this skill whenever the user wants to improve, audit, or maintain their Claude Code environment: 'coach me', 'what am I missing', 'check my setup', 'optimize my CLAUDE.md', 'discover conventions', 'is my config good', 'health check', 'what could be better'. Also use it proactively when the user seems to be struggling with repetitive instructions, missing automations, or an outdated config — even if they don't explicitly ask for a coach run."
user-invocable: true
argument-hint: "[skills|hooks|rules|memory|permissions|plugins|health|init|optimize|discover|all]"
---

# Claude Code Coach

The single maintenance skill for your entire Claude Code environment. Analyze configuration and usage patterns, optimize CLAUDE.md and rules, discover conventions, and suggest improvements. Be a transparent coach — explain *why* each suggestion helps and let the user decide.

## Routing

### Audit modes (diagnose + suggest for a specific area)
- `$ARGUMENTS` contains "skills" → Read `references/checklists/skills.md`, audit skills only
- `$ARGUMENTS` contains "hooks" → Read `references/checklists/hooks.md`, audit hooks only
- `$ARGUMENTS` contains "rules" → Read `references/checklists/rules.md`, audit rules only
- `$ARGUMENTS` contains "memory" → Read `references/checklists/memory.md`, audit memory only
- `$ARGUMENTS` contains "permissions" → Read `references/checklists/permissions.md`, audit permissions only
- `$ARGUMENTS` contains "plugins" → Read `references/checklists/plugins.md`, audit plugins only

### Health mode (cross-cutting analysis)
- `$ARGUMENTS` contains "health" → Read `references/checklists/usage-stale-friction.md`. Run stale config detection, cross-reference analysis, friction detection, and trend analysis.

### CLAUDE.md modes (operate on CLAUDE.md + rules)
- `$ARGUMENTS` contains "init" → Scaffold a minimal CLAUDE.md (fast, no deep analysis). Read `references/claude-md-optimize.md` section "Init Mode".
- `$ARGUMENTS` contains "optimize" or "claude-md" → Deep CLAUDE.md + rules cleanup (self-update, bloat detection, rules audit, rewrite). Read `references/claude-md-optimize.md` section "Optimize Mode".
- `$ARGUMENTS` contains "discover" → Mine codebase + code reviews for conventions → generate `.claude/rules/`. Read `references/discover.md`.

### Default (full audit)
- No arguments or "all" → Full audit across all areas. Read ALL checklist files in `references/checklists/`. If deep CLAUDE.md optimization is overdue (see Phase 0), suggest running it.

## Phase 0: Delta Detection

Check what changed since last coach run — this avoids re-suggesting things the user already addressed or declined.

1. Read `.claude/coach-history.md` in the **project directory** — extract:
   - **Last coach run**: date and score
   - **Last deep CLAUDE.md optimization**: date (tracked separately)
   - If `.claude/coach-history.md` doesn't exist, also check `references/history.md` as legacy fallback — if found there, migrate it to `.claude/coach-history.md` and leave a pointer in the old location
   - History is stored per-project so each project tracks its own coach runs independently and the history can be shared with the team via version control

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

Announce detected context briefly:
> **Project**: [type] | **Last coach**: [date, X days ago] | **Last optimize**: [date, X days ago] | **Score**: [X/10 → Y/10]

## Phase 2: Inventory Current Setup

Collect current state silently (no output yet):

1. **Settings** — Read `~/.claude/settings.json` and `.claude/settings.json` and `.claude/settings.local.json`
2. **Settings diff** — If `settings.json.bak` exists, compare with current `settings.json` to detect recent regressions (hooks removed, plugins disabled, permissions changed). This catches unintentional removals. (`settings.json.bak` is created automatically by Claude Code before writing to settings — it's a one-step rollback file.)
3. **Skills** — List `~/.claude/skills/` (user) and `.claude/skills/` (project)
4. **Hooks** — List `~/.claude/hooks/` and hook configs in all settings files. Cross-check: are there hook scripts on disk not wired in settings? Are there settings entries pointing to missing scripts?
5. **Rules** — List `.claude/rules/` — check for `paths:` frontmatter
6. **Memory** — Read memory index from project memory MEMORY.md
7. **CLAUDE.md** — Read root CLAUDE.md, CLAUDE.local.md, and .claude/CLAUDE.md (if they exist) — count lines
8. **Permissions** — Check `permissions.allow` in all settings files
9. **Plugins** — Check `enabledPlugins` in settings. Note specifically whether `skill-creator@claude-plugins-official` is enabled — this affects skill creation delegation in Phase 5.
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

For targeted modes (single area), read ONLY that area's checklist plus `usage-stale-friction.md` for cross-reference checks related to that area. This keeps the analysis focused and token-efficient.

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

**Score >= 8/10 with few gaps**: Keep the report short. Say something like "Your setup is solid" (match the user's language) and only list the 2-3 minor points. Don't force Advanced suggestions just to fill the template.

**Delta = 0 since last run**: If nothing meaningful changed since last coach run, say "Nothing new since last check" (match the user's language) with the date, and only flag new stale items or regressions.

## Phase 5: Interactive Implementation

After presenting the report:

1. Ask: "Which suggestions would you like me to implement? (numbers, 'all quick wins', or 'skip')"
2. For each accepted suggestion, implement it directly (create files, update settings, etc.)
3. **Show, don't tell** — When a suggestion involves creating or modifying a file (rule, memory, CLAUDE.md), provide the complete file content ready to use, not just "create a file for X". The user should be able to approve and move on, not fill in blanks.
4. **Skill creation/modification — delegate to skill-creator** — When an accepted suggestion involves creating a new skill or making substantial changes to an existing one (new SKILL.md, or edits touching more than ~30% of the skill body), do NOT write the skill yourself. Instead:
   - **If `skill-creator@claude-plugins-official` is enabled** (detected in Phase 2): hand off to `/skill-creator` with full context — skill name, objective, and the gap the coach identified. Say: "I'll delegate this to `/skill-creator` so it follows Anthropic's standards (evals, description optimization, iteration loop)."
   - **If skill-creator is NOT enabled but the cache exists** (`~/.claude/plugins/cache/claude-plugins-official/skill-creator/`): offer to install it first — "skill-creator is available but not installed. Want me to run `claude plugin install skill-creator` so this skill gets proper evals and description optimization?" If the user accepts, install it then hand off. If they decline, fall back to writing the skill directly.
   - **If skill-creator is not installed and not cached**: note it in the report as a recommended plugin (`claude plugin install skill-creator`) and fall back to writing the skill directly, with a disclaimer that evals and description optimization won't be applied.
5. After implementation, briefly confirm what was done
6. **Update `.claude/coach-history.md`** in the project directory:
   - Add accepted suggestions with today's date
   - Update "Last coach run" header with date and score
   - If a deep optimization was performed (init/optimize/discover), update "Last deep CLAUDE.md optimization" date
   - Create the file if it doesn't exist
   - Archive entries older than 30 days to `.claude/coach-history-archive.md`

## Coach Rules

- **Language**: Match the user's language
- **No fluff**: Each suggestion must be concrete and actionable
- **Explain why**: Every suggestion needs a "Why" — connect to real benefit
- **Respect existing choices**: Don't suggest removing things the user intentionally configured
- **Don't overwhelm**: Max 13 suggestions total per audit. Distribute across categories as needed
- **Idempotent**: Running `/coach` twice should not duplicate suggestions — check `.claude/coach-history.md`
- **Track suggestions**: Log accepted/declined suggestions to `.claude/coach-history.md` in the project directory
- **Archive old history**: When coach-history.md exceeds 40 entries, move entries older than 30 days to `.claude/coach-history-archive.md`
- **Positive tone**: Start with what's good, then improve. Coach, don't criticize.
- **Adaptive skill principle**: When a user skill and project skill overlap, suggest merging into a single adaptive user skill with context detection — a skill that reads the current project context at runtime and adjusts its behavior accordingly (e.g., different lint commands per build system), rather than maintaining two separate skills
- **Concrete outputs**: When suggesting a new file (rule, memory, CLAUDE.md section), always provide the full content — never leave placeholders like "[your preference here]". Use what you know from the current config and usage patterns to fill in real values.
- **Skill delegation**: When a suggestion involves creating a new skill or substantially rewriting an existing one, always delegate to skill-creator — it ensures evals, description optimization, and Anthropic standards are applied. Don't try to write the skill inline.

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
