# Hooks Checklist

Hooks are organized by *purpose*, not by specific tool. Detect what's missing and suggest the category.

## Settings file hierarchy — CRITICAL: coach scope

Coach operates at **project scope only**. It must never touch `~/.claude/settings.json` (global user environment).

| File | Scope | Committed? | Coach can write? |
|------|-------|-----------|-----------------|
| `~/.claude/settings.json` | All projects, all machines | No (user-global) | **NO** — outside project scope |
| `.claude/settings.json` | This project, all devs | **Yes** (git) | **NO** for personal hooks — would land on every dev's machine, including those without coach |
| `.claude/settings.local.json` | This project, this machine | No (.gitignore) | **YES** — only place coach adds hooks |

**The rule**: Any hook coach creates *on its own initiative* goes exclusively into `.claude/settings.local.json`. Never into the committed `.claude/settings.json` (would propagate to all devs) and never into `~/.claude/settings.json` (global, out of scope).

**Exception**: If the user explicitly requests a change (e.g. "implement all", "disable this plugin", "add this hook globally"), execute it directly in the file they intend — including `~/.claude/settings.json`. Blocking an explicit user request is unhelpful.

**Duplication detection**: If a hook exists in `~/.claude/settings.json` (global) AND in `.claude/settings.local.json` (project local), it will run twice for this project. When flagging this:
- **Do NOT suggest removing from `settings.local.json`** — it is the correct project-local location
- **Do NOT suggest removing from `~/.claude/settings.json`** — that is outside coach's scope
- Instead, inform the user: "This hook runs twice — once from global settings, once from local. If you want it global (all projects), remove it from `settings.local.json`. If you want it project-local only, remove it from `~/.claude/settings.json` manually. Coach won't touch the global file."

| Purpose | How to detect | Suggestion if missing |
|---------|--------------|----------------------|
| Notification on completion | Hook on `Stop` event in `.claude/settings.local.json` | "Add a notification hook to `settings.local.json` so you know when Claude finishes a task" |
| Notification on input needed | Hook on `Notification` event in `.claude/settings.local.json` | "Add a notification hook to `settings.local.json` so you're alerted when Claude needs your input" |
| Token optimization | Run `which rtk` — absent = not installed | **High priority**: "RTK is not installed. It compresses bash/git output via a PreToolUse hook (60-90% token savings). Install: `cargo install rtk` then offer to wire the PreToolUse hook in `settings.local.json`. Without it, every shell command costs full tokens. **Caveat**: RTK applies to all agents including subagents — if a subagent needs untruncated output (e.g., reading full build logs), it should use `rtk proxy <cmd>` to bypass filtering for that command." |
| Build protection | PreToolUse hook in `.claude/settings.json` (shared) warning on heavy build commands | "Add a hook to warn when builds run in the main agent — this one goes in `settings.json` (shared) since it protects the whole team" |
| File protection | PreToolUse hook on Edit/Write for critical files in `.claude/settings.json` (shared) | "Add a hook to protect critical files — goes in `settings.json` (shared) since it applies to all devs" |
| Usage tracking | PostToolUse logging hook writing to `~/.claude/coach-usage-log.jsonl` — check `.claude/settings.local.json` | **Implement directly when accepted**: copy `${CLAUDE_SKILL_DIR}/scripts/track-usage.sh` to `.claude/hooks/track-usage.sh` and add the PostToolUse entry to `.claude/settings.local.json`. Create the file if it doesn't exist. |
| Skill recommender | Stop hook running `skill-recommender.sh` — check `.claude/settings.local.json` | **Implement directly when accepted**: add the Stop entry to `.claude/settings.local.json`. Create the file if it doesn't exist. |
| Session context | SessionStart hook in `settings.local.json` | **Implement directly when accepted**: add the SessionStart entry to `.claude/settings.local.json`. Create the file if it doesn't exist. |
