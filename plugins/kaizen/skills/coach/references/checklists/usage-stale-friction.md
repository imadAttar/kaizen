# Usage Patterns, Stale Config & Friction Detection

## Usage Pattern Detection

When usage log exists (`~/.claude/coach-usage-log.jsonl`), detect patterns and suggest improvements based on what the user *actually does*, not a predefined list.

| Pattern | Signal | Suggestion approach |
|---------|--------|-------------------|
| Repeated manual command | Same Bash command pattern appears >3 times | Check if an existing skill covers this. If yes, remind the user. If no, suggest creating one. |
| Low skill adoption | <5% of tool calls are Skill | "You have skills available but rarely use them — here are the ones that match your recent work: [list relevant ones from their installed skills]" |
| Repeated corrections | >2 feedback memories on same topic | "This keeps coming up — consider strengthening the rule in .claude/rules/" |
| Skill never used | Skill exists but 0 invocations in log over 2+ weeks | "Consider archiving to reduce context cost — hasn't been used recently" |
| High-cost operations in main agent | Build/test commands consuming many tokens in main context | "Consider delegating this to a sub-agent skill to keep the output out of your context window" |

## Stale Config Detection

Config drifts as the codebase evolves. These checks catch config that no longer matches reality.

| What to check | How to detect | Suggestion |
|---------------|--------------|-----------|
| Rules with dead paths | Read `paths:` frontmatter from each rule in `.claude/rules/`, check if those dirs/files exist | "This rule targets paths that no longer exist — update or remove it" |
| CLAUDE.md stale commands | Extract build/test commands from CLAUDE.md, try to verify they exist (e.g., check package.json scripts, Makefile targets) | "CLAUDE.md references a command that may no longer exist — verify and update" |
| Old project memories | Memory files with type=project, check dates in content or file modification time >30 days | "This project memory is about work completed over a month ago — still relevant?" |
| Agents with moved scopes | Read agent .md files, check if the source directories in their scope still exist | "This agent references directories that were moved or deleted" |
| Orphan hook scripts | Compare hook scripts in `~/.claude/hooks/` and `.claude/hooks/` against what settings.json references | "This hook script exists but isn't configured (or is configured but the script is missing)" |

## Cross-Reference Analysis

Each config area can look fine alone but conflict with another. These checks surface inconsistencies across areas.

| Cross-reference | How to detect | Suggestion |
|----------------|--------------|-----------|
| Feedback memory → no rule | Feedback memory says "don't do X" but no rule in `.claude/rules/` covers it | "This feedback keeps coming up — promote it to a rule for reliable enforcement" |
| Hook ↔ permission conflict | A permission allows `Bash(cmd)` but a PreToolUse hook blocks it (or vice versa) | "Permission and hook contradict each other — decide which one should win" |
| Agent missing LSP | Agent scope covers code files, MCP IDE is configured, but agent tools don't include `LSP` | "This agent would benefit from LSP — add it to its tools list" |
| Rule with no matching files | Rule has `paths:` but the glob matches 0 files in the project | "This rule's path pattern doesn't match any current files — update the pattern or remove the rule" |
| Memory duplicates rule | Memory content overlaps with an existing rule | "This memory duplicates a rule — remove the memory to avoid redundancy" |
| Memory references missing file | Memory mentions a rule, config, or script by name — verify the file exists | "This memory references a file that was deleted or never created — update the reference" |

## Friction Point Detection

Patterns in the usage log that suggest the user is fighting their setup instead of being helped by it.

| Pattern | Signal | Suggestion |
|---------|--------|-----------|
| Edit correction loops | Same file appears in 3+ Edit calls within a short window | "You're editing the same file repeatedly — check if a rule is causing corrections or if the initial instruction needs clarifying" |
| Manual-heavy sessions | >50 Bash/Edit calls with 0 Skill calls in a session | "This session was very manual — check if existing skills could have helped" |
| Repeated permission approvals | Same command pattern appears in log but not in permissions.allow | "You keep approving this — consider adding it to permissions" |
