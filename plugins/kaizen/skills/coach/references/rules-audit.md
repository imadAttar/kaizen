# Rules Audit — Detailed Process

Read this file when running **optimize** or **audit-rules** mode.

## 1. Frontmatter Coverage

Scan every `.claude/rules/**/*.md` file and check for `paths:` frontmatter:

- **Has `paths:`** → verify patterns are meaningful (not overly broad like `**/*`)
- **No `paths:`** → flag as always-on. Acceptable only for:
  - Behavioral/workflow rules that have no file association
  - Very small rules (<15 lines) where always-on cost is negligible
- **`paths: ["**/*.java"]` or similar catch-all** → flag as effectively always-on. Suggest removing the frontmatter or narrowing the pattern

## 2. Cross-Layer Redundancy Detection

For each rule file, check if its content is already covered by:

1. **CLAUDE.md** — search for overlapping keywords/directives in root CLAUDE.md
2. **`.claude/docs/`** — search for matching sections in doc files
3. **Other rule files** — detect rules that overlap with each other

For each redundancy found:
- If the rule adds actionable specificity beyond the other source → keep, note the overlap
- If the rule is a strict subset of another source → recommend deletion
- If two rules partially overlap → recommend merging

## 3. Pertinence Scoring

**The decisive test — apply to EVERY line in a rule file:**

```
If Claude does NOT read this line, will it make a concrete mistake?
├── YES → keep in rule (directive)
│   "Never use Thread.sleep() in tests"
│   "Use StatusAssert for IStatus, not raw AssertJ"
└── NO → move to docs or delete (reference material)
    "SWTBot uses SWTGefBot for GEF diagram tests" (how-it-works)
    Full code example showing Mockito @ExtendWith setup (template)
```

**Content type routing:**

| Content type | Where it belongs | Example |
|-------------|-----------------|---------|
| "NEVER / ALWAYS / MUST" | **Rule** | "NEVER use assertEquals, use assertThat" |
| "When doing X, do it like Y" | **Rule** | "Use fluent builders, not constructors" |
| "Watch out for trap X" | **Rule** | "RealmWithDisplay is @Rule not @ExtendWith" |
| Full code template | **docs** | Handler, Store, Test boilerplate |
| "Here's how X works" | **docs** | Explanation of how a framework works |
| API examples / samples | **docs** | Library code samples |

Rate each rule file on a 0-10 scale:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Prevents real mistakes** | 3 | Does this rule prevent an error Claude would actually make? |
| **Not derivable from code** | 3 | Can Claude figure this out by reading the codebase? |
| **Actionable, not documentary** | 2 | Every line must be a directive, not reference material |
| **No low-ROI content** | 1 | Every block passes the ROI test (§4)? |
| **paths: accuracy** | 1 | Does the frontmatter target the right files? |

**Scoring thresholds:**
- **8-10**: Excellent rule, keep as-is
- **6-7**: Good rule, minor improvements possible
- **4-5**: Borderline — consider merging, trimming, or moving to docs
- **0-3**: Low value — recommend deletion or migration to docs

## 4. ROI-Based Trimming

Line counts are indicators, not hard limits. The 80-line target is a heuristic.

**Before removing or condensing any content, evaluate:**

```
Should I remove/condense this block?
├── Does it prevent a concrete mistake? → KEEP regardless of file length
├── Is it a lookup table or decision tree needed at point of use? → KEEP
├── Is it a code template showing the ONLY correct way? → KEEP
├── Is it a shorter reformulation of something in docs? → REMOVE
├── Is it prose/explanation with no directive? → MOVE to docs
└── Does condensing lose clarity for <5 line savings? → DON'T condense
```

**Common bad trims (avoid):**
- Condensing a config template into bullets — loses the exact format
- Removing a base-class table — Claude picks the wrong parent
- Inlining a multi-step workflow into prose — loses order and clarity

## 5. Structure Consistency

- All rules should be in subdirectories (no flat files at `.claude/rules/` root)
- Subdirectory names should be domain-based: `testing/`, `api/`, `deployment/`, etc.
- File names use kebab-case: `build-conventions.md`, `test-patterns.md`
