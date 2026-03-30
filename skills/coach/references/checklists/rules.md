# Rules Checklist

| Check | How to detect | Suggestion if missing |
|-------|--------------|----------------------|
| Path scoping | Rules have `paths:` frontmatter | "Add `paths:` frontmatter to rules to reduce context cost — rules without it load for every file" |
| LSP fallbacks | LSP plugin active (or `mcp_ide` tools available in session) AND `.claude/rules/tooling/lsp-fallbacks.md` absent | **High priority**: "LSP is active but `lsp-fallbacks.md` is missing. This rule is actively read by review, investigate and code skills during execution — it tells them which LSP operations work on this project and where to fall back to grep/read. Without it, skills probe blindly each session. Create it interactively: test hover, go-to-definition, find-references on a few project files, then document what works." Offer to create the file. |
| VCS conventions | Rule about commit format (adapt to detected VCS: git, svn, hg, cvs) | "Add a VCS conventions rule for consistent commits across the team" |
| Testing conventions | Rule about test patterns (if project has tests) | "Add testing conventions — naming, structure, what to cover" |
| No duplication | Rules that repeat CLAUDE.md content | "Move duplicated content from CLAUDE.md into scoped rules to reduce context bloat" |
