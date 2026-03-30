# kaizen

Most Claude Code plugins give you a dozen skills upfront. You enable them all, use two, and the rest just bloat your context.

**kaizen does the opposite.** It starts with a single skill — `/kaizen:coach` — that analyzes how you actually work and suggests only what you need: the right skills, the right hooks, the right rules, a well-structured CLAUDE.md. You build your setup progressively, based on your real usage, not someone else's defaults.

The philosophy: one central habit, continuous small improvements. That's kaizen.

---

## How it works

Run `/kaizen:coach` in any project. It will:

- Detect your project context (language, build system, VCS, test framework)
- Audit your current Claude Code setup (skills, hooks, rules, memory, CLAUDE.md, plugins)
- Identify what's missing or suboptimal — and explain *why* it matters for your workflow
- Implement accepted suggestions directly: create rules, wire hooks, update CLAUDE.md

Over time, coach tracks what you've done and what changed — so each run focuses on new gaps, not already-addressed items.

### What coach looks for

- **Skills** — Are skills matched to your workflow? Any unused ones bloating context? User/project duplicates to merge?
- **Hooks** — Notifications (Stop, input needed), token optimization (RTK), usage tracking, build protection, file protection, session context
- **Rules** — Path scoping, LSP fallbacks, VCS conventions, test conventions, duplication with CLAUDE.md
- **Memory** — Stale entries, broken references to files/skills that no longer exist
- **CLAUDE.md** — Too long? Duplicating rules? Missing build commands or architecture overview? Personal content that should go to `CLAUDE.local.md`?
- **Plugins** — LSP for your language (auto-detected: Java, TypeScript, Rust, Python, Go), Context7 for live docs
- **Permissions** — Discovered from usage: commands you run repeatedly that could be pre-allowed

---

## Skills

### `/kaizen:coach`
The entry point. Audit your Claude Code environment and get actionable, prioritized suggestions. Implements accepted changes interactively.

**Modes:**
```
/kaizen:coach              # Full audit across all areas
/kaizen:coach health       # Cross-cutting analysis: stale config, friction, trends
/kaizen:coach skills       # Audit skills only
/kaizen:coach hooks        # Audit hooks only
/kaizen:coach rules        # Audit rules only
/kaizen:coach memory       # Audit memory only
/kaizen:coach permissions  # Audit permissions only
/kaizen:coach plugins      # Audit plugins only
/kaizen:coach init         # Scaffold a minimal CLAUDE.md (fast, no deep analysis)
/kaizen:coach optimize     # Deep CLAUDE.md + rules cleanup and rewrite
/kaizen:coach discover     # Mine codebase conventions → generate .claude/rules/
```

### `/kaizen:code`
Once your environment is set up, use `/kaizen:code` for end-to-end resolution of bugs and features: diagnose → implement → verify → commit in a single flow.

**Usage:** `/kaizen:code fix the login bug` or `/kaizen:code PROJ-123`

### Sub-skills (orchestrated by `/kaizen:code`)

| Skill | Role |
|-------|------|
| `/kaizen:investigate` | Root cause analysis — bugs, regressions, errors |
| `/kaizen:analyze` | Implementation plan — features, refactoring |
| `/kaizen:implement` | Execute a validated plan |
| `/kaizen:verify` | Quick verification of just-implemented changes |
| `/kaizen:review` | Full branch code review |
| `/kaizen:commit` | Smart conventional commits |

---

## Installation

```bash
/plugin install kaizen@claude-plugins-official
```

Or directly from GitHub:

```bash
/plugin install github:imadAttar/kaizen
```

Then run `/kaizen:coach` in your project to get started.
