#!/bin/bash
# Usage tracking hook for Claude Code Coach
# Logs tool usage patterns to ~/.claude/coach-usage-log.jsonl
# Called as a PostToolUse hook — receives tool info via stdin JSON
#
# Note: head/tail are used below for truncation and log rotation.
# This is safe because this script runs as a direct shell hook, NOT through
# Claude's Bash tool — so RTK does not intercept these commands.

LOG_FILE="$HOME/.claude/coach-usage-log.jsonl"
MAX_LINES=1000

# jq is required for JSON parsing — exit silently if not available
command -v jq &>/dev/null || exit 0

# Read JSON input from stdin
INPUT=$(cat)

# Parse fields from stdin JSON
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Only log interesting tools (skip Read/Glob/Grep which are very frequent)
case "$TOOL_NAME" in
  Bash|Edit|Write|Agent|Skill)
    DETAIL=""
    if [ "$TOOL_NAME" = "Bash" ]; then
      DETAIL=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null | head -c 100 | tr '"' "'" | tr '\n' ' ')
    elif [ "$TOOL_NAME" = "Skill" ]; then
      DETAIL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)
    elif [ "$TOOL_NAME" = "Agent" ]; then
      DETAIL=$(echo "$INPUT" | jq -r '.tool_input.description // empty' 2>/dev/null | head -c 80 | tr '"' "'" | tr '\n' ' ')
    fi

    echo "{\"ts\":\"$TIMESTAMP\",\"tool\":\"$TOOL_NAME\",\"detail\":\"$DETAIL\",\"project\":\"$PROJECT_DIR\",\"session\":\"$SESSION_ID\"}" >> "$LOG_FILE"

    # Rotate if too large
    if [ -f "$LOG_FILE" ]; then
      LINES=$(wc -l < "$LOG_FILE" 2>/dev/null)
      if [ "$LINES" -gt "$MAX_LINES" ]; then
        tail -n 500 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
      fi
    fi
    ;;
esac

exit 0
