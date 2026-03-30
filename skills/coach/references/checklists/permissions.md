# Permissions Checklist

Permissions should be discovered from actual usage, not prescribed from a template. The approach:

1. **Analyze usage log** — Look for Bash commands that the user runs frequently. If a command pattern appears 3+ times, it's a candidate for `permissions.allow`.
2. **Cross-check with friction detection** — Repeated permission approvals (same command, no entry in permissions) are the strongest signal.
3. **Check project tools** — If the project uses a build system (detected in Phase 1), check if the build command is in permissions. Same for CI tools, package managers, etc.

| Signal | How to detect | Suggestion |
|--------|--------------|-----------|
| Frequently approved commands | Same Bash command prefix in usage log 3+ times, not in permissions.allow | "You run this often — add it to permissions to skip the approval prompt" |
| Project build tool not allowed | Build system detected but no matching permission | "Your build tool isn't in permissions — add it for smoother workflows" |
| WebFetch for project domains | MCP tools or CLAUDE.md reference external domains not in permissions | "Add WebFetch for domains your project uses" |
