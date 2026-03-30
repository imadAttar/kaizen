# Plugins Checklist

| Check | How to detect | Suggestion if missing |
|-------|--------------|----------------------|
| LSP for project language | Detect language (pom.xml → Java/jdtls, package.json/tsconfig → TypeScript/typescript-language-server, Cargo.toml → Rust/rust-analyzer, pyproject.toml → Python/pylsp, go.mod → Go/gopls) then check `enabledPlugins` or `mcp_ide` tools available in session | **High priority if absent**: "No LSP detected for [language]. Without LSP, skills (review, investigate, code) navigate blindly — no go-to-definition, no find-references. Enabling [appropriate LSP] lets skills use real code intelligence instead of grep." Suggest the right LSP based on detected language. Offer to add it to settings. |
| Context7 | `context7` in enabledPlugins | "Enable Context7 for up-to-date library docs in context" |
