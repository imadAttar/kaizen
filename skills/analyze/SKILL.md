---
name: analyze
description: "Complete analysis of a feature, refactoring, or evolution ticket. Produces a detailed implementation plan with impact analysis, side effects, and effort estimation — without writing any code. Use this skill whenever the user wants to plan a change before implementing it, even if they say 'how should I do this', 'what's the impact of', 'plan this feature', 'étude d'impact', or just paste a ticket and ask for a plan. Also triggers on: analyze, analyse, plan feature, analyser ce ticket."
user-invocable: true
argument-hint: "<ticket ID | URL | description>"
---

# Analyze — Feature & Impact Analysis

## Input

$ARGUMENTS

Accepts: Jira ticket, GitHub issue/PR, GitLab issue/MR, URL, or free-text description.

Reuse the input parsing protocol from the `investigate` skill (adaptive: MCP → CLI → ask user to paste).

## Protocol

### Phase 1: Understand the request

1. **Restate** the goal in one clear sentence
2. **Identify the type**: new feature | evolution | refactoring | migration | deprecation
3. **Extract acceptance criteria** from the ticket (explicit or implicit)
4. **Clarify ambiguities** — if the ticket is vague, list what needs clarification and ask the user before proceeding

**CHECKPOINT** — Present the goal, type, and acceptance criteria. Wait for user validation before exploring the codebase.

### Phase 2: Map the existing code

Explore the codebase to understand what exists today. Use parallel Agent calls when exploring independent areas.

For each functional area impacted, identify:
- **Entry points**: handlers, commands, UI actions
- **Core logic**: services, managers, operations
- **Data layer**: stores, repositories, models
- **Configuration**: plugin.xml, MANIFEST.MF, pom.xml, package.json, etc.

**Existing patterns**: Search for similar features already implemented in the codebase. Identify conventions, base classes, or utilities to reuse rather than reinvent. Example: if adding a new Handler, find an existing Handler of the same type and follow its structure.

Use LSP if available (go-to-definition, find-references), otherwise fall back to Grep/Read.

### Phase 3: Impact analysis

For each change required:

1. **Direct impact** — files that must be modified
2. **Indirect impact** — files that depend on modified code (callers, subclasses, tests)
3. **Side effects** — what could break (other features, configurations, migrations, backward compatibility)
4. **Risks** — concurrency, performance, data loss, security
5. **Dependencies** — does this require new libraries, DB migrations, config changes, or build system modifications?
6. **Backward compatibility** — does this change any public API, data format, protocol, or contract?

Use Grep to find all callers/references before claiming something is safe to change.

### Phase 4: Architectural options

Before detailing a plan, propose **2-3 approaches** with trade-offs:

```
| Approach | Description | Pros | Cons |
|----------|-------------|------|------|
| A | ... | ... | ... |
| B | ... | ... | ... |
```

Recommend one approach with justification. If the choice is obvious (only one reasonable approach), state it briefly and skip the table.

**Scope check**: If the impact matrix reveals more than ~20 direct files or multiple independent sub-features, propose splitting the analysis into smaller scoped analyses before detailing a plan. Ask the user how to split.

### Phase 5: Implementation plan

Adapt the level of detail to the scope:
- **Small** (1-5 files): one-line steps with file:line references
- **Medium** (5-15 files): steps with What/Where/How
- **Large** (15+ files): grouped by functional area, with dependencies between groups

Each step must include at minimum:
- **Where**: exact file(s) and method(s)
- **What**: description of the change
- **Dependencies**: other steps that must complete first (use step numbers)
- **Tests**: what tests to add or update

**Testability check**: For each step, assess whether Claude can run the tests:
- **Auto-testable** (unit tests, CLI, scripts) → mark as `[auto]`
- **Manual testing required** (GUI, OSGi runtime, specific environment) → mark as `[manual]` and describe what the user should verify
- **No test infra** (no test framework set up for this area) → flag it and suggest setup if trivial, otherwise note it as a gap

### Phase 6: Summary & risks

Assess overall risk level, suggest PR strategy (single/multiple), and list key risks with mitigations.

## Output format

```
## Goal
[One-sentence restatement]

## Type
[feature | evolution | refactoring | migration | deprecation]

## Acceptance criteria
- [ ] ...

## Current state
| Area | Key classes | Role |
|------|------------|------|
| ... | file:line | ... |

[If existing patterns found:]
## Patterns to reuse
| Pattern | Example | Reuse for |
|---------|---------|-----------|
| ... | file:line | ... |

## Impact matrix
| File | Change type | Risk | Side effects |
|------|------------|------|-------------|
| path/to/File.java:42 | modify method X | low/medium/high | ... |

## Dependencies & prerequisites [omit if none]
- [ ] New library: [name, version, reason]
- [ ] DB migration: [description]
- [ ] Config change: [description]
- [ ] Breaking change: [what breaks, migration path]

## Approaches [skip if only one reasonable option]
| Approach | Description | Pros | Cons |
|----------|-------------|------|------|
| A | ... | ... | ... |
**Recommended**: A — [justification]

## Implementation plan
### Step 1: [title]
- **Where**: `path/to/File.java` — method `foo()`
- **What**: ...
- **Depends on**: — (or Step N)
- **Tests**: ... `[auto]` / `[manual: description]`

## Open questions [omit if none]
- [ ] [question that cannot be resolved by code analysis alone — needs product/business/external input]

## Summary
- **Steps**: N
- **Files impacted**: N (M direct, K indirect)
- **Estimated complexity**: small (1-3 files) / medium (4-10 files) / large (10+ files)
- **Risk level**: low / medium / high
- **Key risks**: [risk — mitigation]
- **Suggested approach**: single PR / multiple PRs / feature branch
- **Testing strategy**: unit tests `[auto]` / integration tests `[auto/manual]` / manual QA `[manual]`
```

## Rules

- **Analysis only** — this skill produces a plan, not code. Use `/implement` or `/code` to execute. Writing code here would bypass the user's validation checkpoint.
- **Evidence-based** — every claim must have a file:line reference. Vague statements lead to bad implementation plans.
- **Check callers before declaring a change safe** — Grep for all references. A method that looks unused may have callers via reflection, OSGi services, or plugin.xml.
- **Parallel exploration** — use Agent calls in parallel when exploring independent areas. This significantly reduces analysis time on medium/large scopes.
- **Graceful degradation** — if a tool/access is unavailable (no MCP, no LSP, can't access ticket system), adapt and ask the user to fill gaps rather than blocking the analysis.
- **Respond in the user's language**.
