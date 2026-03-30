# Skills Checklist

Coach does NOT recommend specific skills by name. Instead, it discovers gaps from usage patterns and project context, then suggests what *kind* of skill would help.

## Discovery approach

1. **List existing skills** — `ls ~/.claude/skills/` (user) and `.claude/skills/` (project). Read each SKILL.md description to understand what's covered.
2. **Analyze usage log** — Look for repeated manual operations that an existing skill could handle, or patterns that no current skill covers.
3. **Detect project needs** — Based on build system, CI, test framework, does the user have skills that cover these workflows?

## What to look for

| Gap signal | How to detect | Suggestion pattern |
|------------|--------------|-------------------|
| No build delegation | Build commands run in main agent (usage log), no skill with `disable-model-invocation` | "Consider a build skill that delegates to sub-agents — keeps build output out of context" |
| Repeated manual workflow | Same sequence of commands appears 3+ times in usage log | "This looks like a pattern you could capture as a skill: [describe the pattern]" |
| Skill duplication | User-level and project-level skills with overlapping purpose | "These two skills overlap — consider merging into one adaptive skill with context detection" |
| Unused skills | Skill exists but 0 invocations in usage log over 2+ weeks | "Consider archiving [skill] to reduce context cost — it hasn't been used recently" |
| Context bloat | >20 skills loaded | "You have many skills loaded — review which ones you actually use and archive the rest" |

## First-time setup
If the user has very few global skills and asks about setting up their environment, suggest installing the **kaizen** plugin which bundles coach, code, and the full dev workflow pipeline: `/plugin install kaizen@claude-plugins-official`
