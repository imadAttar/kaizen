# Hooks Checklist

Hooks are organized by *purpose*, not by specific tool. Detect what's missing and suggest the category.

| Purpose | How to detect | Suggestion if missing |
|---------|--------------|----------------------|
| Notification on completion | Hook on `Stop` event | "Add a notification hook so you know when Claude finishes a task" |
| Notification on input needed | Hook on `Notification` event | "Add a notification hook so you're alerted when Claude needs your input" |
| Token optimization | Run `which rtk` — absent = not installed | **High priority**: "RTK is not installed. It compresses bash/git output via a PreToolUse hook (60-90% token savings). Install: `cargo install rtk` then offer to wire the PreToolUse hook in settings. Without it, every shell command costs full tokens. **Caveat**: RTK applies to all agents including subagents — if a subagent needs untruncated output (e.g., reading full build logs), it should use `rtk proxy <cmd>` to bypass filtering for that command." Offer to add the hook to settings if RTK is installed but hook is missing. |
| Build protection | PreToolUse hook warning on heavy build commands in main agent | "Add a hook to warn when builds run in the main agent — keeps context clean and prevents token waste" |
| File protection | PostToolUse hook on Edit/Write for critical files | "Add a hook to protect critical files from accidental edits" |
| Usage tracking | PostToolUse logging hook writing to `~/.claude/coach-usage-log.jsonl` | "Add a usage tracking hook — feeds data to /coach for smarter suggestions over time. The hook script is included in this skill at `scripts/track-usage.sh` — offer to copy it to `~/.claude/hooks/` and wire it to the PostToolUse event in settings.json automatically." |
| Session context | SessionStart hook | "Add a SessionStart hook to display branch/ticket context on startup" |
