# kaizen

Most Claude Code plugins give you a dozen skills upfront. You enable them all, use two, and the rest just bloat your context.

**kaizen does the opposite.** It starts with a single skill — `/kaizen:coach` — that analyzes how you actually work and suggests only what you need: which skills to install, which hooks to wire, which rules to write, how to structure your CLAUDE.md. You build your setup progressively, based on your real usage, not someone else's defaults.

The philosophy: one central habit, continuous small improvements. That's kaizen.

---

## How it works

Run `/kaizen:coach` in any project. It will:

- Detect your project context (language, build system, VCS, test framework)
- Audit your current Claude Code setup (skills, hooks, rules, memory, CLAUDE.md, plugins)
- Score your setup on a deterministic 10-point rubric (see below)
- Identify what's missing or suboptimal — and explain *why* it matters for your workflow
- Implement accepted suggestions directly: create rules, wire hooks, update CLAUDE.md

Each run is logged in `.claude/coach-history.md` with its score, so you see the trend (↑/↓/=) across runs, not just a snapshot.

### What coach looks for

- **Skills** — Matched to your workflow? Any unused ones bloating context? User/project duplicates to merge?
- **Hooks** — Notifications (Stop, input needed), token optimization (RTK), usage tracking, build protection, file protection, session context
- **Rules** — Path scoping, LSP fallbacks, VCS conventions, test conventions, duplication with CLAUDE.md
- **Memory** — Stale entries, broken references to files/skills that no longer exist
- **CLAUDE.md** — Too long? Duplicating rules? Missing build commands or architecture overview? Personal content that should go to `CLAUDE.local.md`?
- **Plugins** — LSP for your language (auto-detected: Java, TypeScript, Rust, Python, Go), Context7 for live docs
- **Permissions** — Discovered from usage: commands you run repeatedly that could be pre-allowed
- **Conventions** — Mines your codebase and recent code reviews to extract implicit rules (`discover` mode)

---

## Scoring

Coach scores your setup on 10 binary criteria — same state always yields the same score, so trends are meaningful across runs:

- **Essentials (6 pts)** — Stop-hook notification, usage tracking, populated `.claude/rules/`, concise `CLAUDE.md`, structured `MEMORY.md`, permissions allowlist
- **Hygiene (2 pts)** — No broken references, no regressions since last settings backup
- **Advanced (2 pts)** — Token optimization (RTK), project-aware plugins (LSP, Context7…)

**9-10** excellent · **7-8** solid · **5-6** functional but missing core · **< 5** substantial gaps

---

## Usage

`/kaizen:coach` audits your environment, scores it, and suggests prioritized improvements. Accepted suggestions are implemented interactively.

### Modes

```
/kaizen:coach              # Full audit across all areas
/kaizen:coach health       # Cross-cutting analysis: stale config, friction, trends
/kaizen:coach skills       # Audit skills only
/kaizen:coach hooks        # Audit hooks only
/kaizen:coach rules        # Quick audit of .claude/rules/
/kaizen:coach rules-audit  # Deep audit: frontmatter, ROI trimming, redundancy
/kaizen:coach memory       # Audit memory only
/kaizen:coach permissions  # Audit permissions only
/kaizen:coach plugins      # Audit plugins only
/kaizen:coach init         # Scaffold a minimal CLAUDE.md (fast, no deep analysis)
/kaizen:coach optimize     # Deep CLAUDE.md + rules cleanup and rewrite
/kaizen:coach discover     # Mine codebase conventions → generate .claude/rules/
```

---

## Installation

Add the repo as a marketplace, then install:

```bash
/plugin marketplace add imadAttar/kaizen
/plugin install kaizen@imadAttar/kaizen
/reload-plugins
```

Then run `/kaizen:coach` in your project to get started.
