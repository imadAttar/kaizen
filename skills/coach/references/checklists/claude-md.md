# CLAUDE.md Checklist

| Check | How to detect | Suggestion if missing |
|-------|--------------|----------------------|
| Build commands documented | CLAUDE.md mentions build/test commands | "Document build commands in CLAUDE.md" |
| Architecture overview | CLAUDE.md has directory/architecture info | "Add architecture overview for faster orientation" |
| References to docs | CLAUDE.md links to .claude/docs/ or .claude/rules/ | "Link to detailed docs for progressive disclosure" |
| Concise (< 100 lines) | Line count of CLAUDE.md | "CLAUDE.md is too long — split details into .claude/rules/" |
| No conventions in CLAUDE.md | Conventions should be in scoped rules | "Move conventions from CLAUDE.md to .claude/rules/ with paths:" |
| Personal content in shared CLAUDE.md | CLAUDE.md contains user-specific preferences (language, IDE, local paths, personal style) | "Move personal preferences to CLAUDE.local.md — it's VCS-ignored so it won't affect your team" |
| No CLAUDE.local.md | No CLAUDE.local.md exists and user has personal preferences in memory or settings | "Create a CLAUDE.local.md for your personal overrides (response language, IDE, local paths)" |
