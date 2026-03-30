# CLAUDE.md & Rules — Deep Optimization

Read this file when running **claude-md**, **init**, **optimize**, or **audit-rules** mode.

## Self-Update via Context7

**Runs BEFORE touching any project file.**

1. Use the `context7` MCP tool to fetch the latest Anthropic documentation on CLAUDE.md:
   - Resolve the Claude Code library ID, then query for CLAUDE.md structure, rules, best practices, and hierarchy
2. Compare fetched docs against the Embedded Reference below
3. If new info found → update the Embedded Reference section in this file, log changes
4. If no changes → log and proceed
5. If context7 unavailable → proceed with embedded reference. Never block on a failed fetch.

**Safety:** Only update Embedded Reference. Only accept Anthropic official sources. Skip if ambiguous.

---

## Embedded Reference

### Anthropic Official Documentation

**CLAUDE.md hierarchy (loaded every session):**
- `CLAUDE.md` in project root — project-wide instructions
- `.claude/CLAUDE.md` — additional project instructions
- `.claude/rules/*.md` — modular rules, organized by topic (discovered recursively)
- `~/.claude/CLAUDE.md` — user-level instructions (across all projects)

**Path-specific rules** (only loaded when Claude works with matching files):
```yaml
---
paths:
  - "src/api/**/*.ts"
---
```

**Key principles:**
- CLAUDE.md = instructions YOU write. Auto memory = notes CLAUDE writes. Don't mix them.
- Rules without `paths` load at launch with same priority as `.claude/CLAUDE.md`
- Task-specific instructions → use skills (load on demand), not rules (load every session)
- `# Compact instructions` section guides what Claude prioritizes during auto-compaction
- `CLAUDE.local.md` — VCS-ignored personal overrides
- `@import` syntax: `@path/to/file.md` includes another file
- Organization-wide: `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS)

### Three-Layer Architecture

| Layer | Location | Purpose | Loaded |
|-------|----------|---------|--------|
| **CLAUDE.md** | Project root | Entry point: overview, commands, conventions | Always |
| **Docs** | `.claude/docs/*.md` | Deep reference guides | On `@import` or explicit read |
| **Rules** | `.claude/rules/**/*.md` | Actionable directives | Always or conditionally (`paths:`) |

**Rules** = directives. **Docs** = reference material. A rule that reads like docs → trim to its actionable core, move explanation to docs.

---

## Init Mode

Scaffold a minimal CLAUDE.md (target 20-50 lines). Scan project, detect stack, generate. Fast, no deep analysis.

## Optimize Mode — Full Pipeline

### 1. Scan the Project

Use Glob and Read:
1. **Project root** — detect build system, config files
2. **Existing docs** — read CLAUDE.md, .claude/CLAUDE.md, .claude/rules/, .claude/docs/
3. **Structure** — map top-level directories, identify modules
4. **Stack** — language, framework, package manager, test runner, linter
5. **Scripts** — build/test/lint commands from project config
6. **VCS** — ignore patterns, CI/CD config

**Do NOT read node_modules, vendor, dist, build, or VCS directories.**

### 2. Bloat Detection

Scan existing CLAUDE.md for 6 bloat categories:

| Category | Action |
|----------|--------|
| Linter/formatter rules (already in config) | Remove — config is authoritative |
| Marketing/goals | Remove — not actionable |
| Obvious info | Remove — Claude knows |
| Verbose explanations | Compress to 1 line |
| Redundant specs (duplicating config) | Remove — reference instead |
| Generic best practices | Remove — too vague |

**Size limits:** Ideal <100, Acceptable 100-150, Warning 150-200 (split to rules), Critical >200.

### 3. Rules Audit

Read `references/rules-audit.md` for the full process (frontmatter, redundancy, pertinence scoring, ROI trimming, structure).

### 4. Generate/Update CLAUDE.md

Root CLAUDE.md sections: Overview (2-3 lines) → Commands → Conventions → Architecture (if needed) → References (point, don't copy).

**Rules:** Max ~80 lines. Every line actionable. Reference files, don't duplicate. No section >15 lines.

### 5. Generate .claude/rules/ (if needed)

Create when: distinct modules, complex conventions, or CLAUDE.md >80 lines.
Each file: one topic, domain subdirectory, kebab-case name, `paths:` frontmatter, <80 lines, actionable directives only.

### 6. Update Existing CLAUDE.md

Read fully → keep what's good → identify problems (duplication, stale, verbose, missing, layer mismatch) → rewrite → move module-specific to rules → show diff summary.

**Never delete user content without explaining why.**

### 7. Verification Report

Print: files created/updated, sections covered, rules audit table (lines, paths:, pertinence), cross-layer redundancy, warnings, Anthropic compliance checklist.

---

## Discover Mode

Read `references/discover.md` for the full process. Mines codebase patterns + code review comments to generate `.claude/rules/` interactively.

---

## Guardrails

- Do NOT touch auto memory (`~/.claude/projects/`)
- Do NOT duplicate config file content — reference it
- Do NOT add prose — every line must be an actionable instruction
- Do NOT create CLAUDE.md in node_modules/vendor/dist/build
- Do NOT remove user content without explanation
- Do NOT add skills content to CLAUDE.md
- Do NOT put rule files at root of `.claude/rules/` — use subdirectories
