# Memory Checklist

| Check | How to detect | Suggestion if missing |
|-------|--------------|----------------------|
| User profile | Memory file with type=user | "Save your role/expertise so Claude adapts its responses" |
| Feedback entries | Memory files with type=feedback | "Record corrections so Claude doesn't repeat mistakes" |
| Project context | Memory files with type=project | "Save project context for better-informed suggestions" |
| References | Memory files with type=reference | "Save pointers to external resources (Jira, Slack, docs)" |
| No stale entries | Memory files older than 30 days | "Review and update stale memory entries" |
| No duplication | Memory that duplicates rules | "Remove memory entries that duplicate .claude/rules/ content" |
| Broken references | Read each memory file and extract every file path mentioned (rules, configs, docs). Check that each path exists **exactly as written** — do not substitute the correct current path. List paths that don't exist verbatim. | "This memory references a file that doesn't exist at the stated path — update or remove the reference" |
| Cross-project duplication | Same user preferences duplicated in multiple projects | "Centralize user preferences in a global rule instead of duplicating per project" |
