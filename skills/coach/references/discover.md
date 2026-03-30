# Discover Mode — Deep Convention Mining

Extract tribal knowledge from codebase + PR review comments and generate `.claude/rules/` files.

## Core Loop

**Focus Area Selection → Pattern Analysis → PR Review Mining → Commit History Mining → Q&A Loop per Rule → Rule File Creation → Continue or Exit**

## Principles

- **Always ask before deciding.** Use AskUserQuestion throughout
- **One rule at a time.** Process each fully before moving to next
- **Write for AI consumption.** Rules must be scannable, actionable, concise
- **Native output.** Generate `.claude/rules/<domain>/` files with `paths:` frontmatter — no custom format

## What to Look For

Analyze the codebase for:
- **Unusual conventions** — naming patterns, file organization, import ordering
- **Opinionated choices** — specific libraries chosen over alternatives, custom wrappers
- **Repeated patterns** — error handling, logging, API response formats, test structure
- **Inconsistencies** — areas where the code diverges (may indicate evolving standards)
- **Things newcomers wouldn't discover** — tribal knowledge, hidden dependencies, implicit rules

## Step-by-Step Process

### 1. Focus Area Selection

Ask the user what area to analyze, or suggest areas based on project structure:
- API patterns, database access, error handling, testing, UI components, state management, authentication, etc.

### 2. Pattern Analysis

Explore the codebase in the chosen area. Identify 3-7 candidate patterns worth documenting.

Present findings to user: "I found these patterns in your codebase. Which should we document as rules?"

### 3. PR/Code Review Mining (if available)

Check if a code review tool is available (e.g., `gh` for GitHub, or other platform CLI). If yes:

1. **Fetch recent merged PRs/changesets** in the focus area
2. **Filter** to those touching files in the selected focus area
3. **Read review comments** for each relevant PR/changeset
4. **Extract implicit conventions** from comments:
   - Recurring reviewer corrections → undocumented conventions
   - "Why we do it this way" explanations → rationale for a rule
   - Pattern rejections → anti-patterns to document
   - Applied suggestions → team-validated patterns
5. **Cross-reference with code patterns** from step 2:
   - Confirms a code pattern → strengthens confidence
   - Contradicts a code pattern → flag the inconsistency
   - New pattern absent from code → recent convention not yet widespread
6. **Present findings** to user and ask which to include as rules

If no code review tool is available, inform user and skip to next step.

### 4. Commit/Change History Mining

Analyze recent commit or change history in the focus area for convention signals. Adapt commands to the detected VCS (git log, svn log, hg log, etc.).

1. **Fetch recent history** for the focus area (last ~6 months, ~100 entries)
2. **Analyze commit message patterns**:
   - Recurring fixes on same module/area → fragile zone, may need stricter rules
   - Refactor clusters → conventions evolving, check if old patterns still valid
   - Consistent scoping (e.g., `feat(api):`) → team conventions to document
   - Repeated similar descriptions → undocumented convention that keeps being missed
3. **Check for convention evolution** — frequently modified files, large renames/moves
4. **Cross-reference with code + review findings**:
   - Confirms a code convention → strengthens confidence
   - Reveals a gap → convention exists in practice but not documented
   - Shows evolution → old rule may need updating
5. **Present findings** to user and ask which to include

### 5. Q&A Loop (per rule)

For each selected pattern:

1. **Ask 1-2 clarifying "why" questions**
   - "Why does the team use X instead of Y?"
   - "Is this intentional or organic?"
   - "Should new code follow this pattern?"

2. **Draft the rule** as a `.claude/rules/` file:
   - Add appropriate `paths:` frontmatter targeting relevant files
   - Write actionable directives (NEVER/ALWAYS/MUST format)
   - If from PR comment, note the source briefly
   - Apply pertinence test: every line must prevent a concrete mistake

3. **Present draft to user for approval**
   - Show the full markdown content
   - Ask: "Does this capture the convention correctly? Any edits?"

4. **Create file** in `.claude/rules/<domain>/<rule-name>.md`
   - Use kebab-case for filenames
   - Group into domain subdirectories (api/, database/, testing/, ui/, etc.)
   - Target under 80 lines per file

### 6. Continue or Exit

Ask: "Want to document another rule in this area, switch to a different area, or stop?"

### 7. Final Report

After all rules are created, run the **Rules Audit** (Step 1.7 from main SKILL.md) on the newly created files to validate quality.

## Output

Each discovered convention produces:
- A `.claude/rules/<domain>/<rule-name>.md` file with `paths:` frontmatter
- Validated against pertinence scoring (must score 6+/10)
