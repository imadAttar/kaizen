---
name: commit
description: "Smart commit: analyze uncommitted changes, group by functional cohérence, and create one or multiple conventional commits. Never pushes unless asked. Triggers on: commit, git commit, save changes, commite, commiter, committer, sauvegarde les changements, faire un commit."
user-invocable: true
argument-hint: "[optional: commit message or scope hint]"
---

# Commit — Smart functional grouping

## Input

$ARGUMENTS

If the user provides a message, use it for a single commit of all changes.
If no message, analyze and group automatically.

## Protocol

### Phase 1: Collect changes

```bash
git status
git diff --stat
git diff --cached --stat
```

If nothing to commit, report and stop.

### Phase 2: Analyze & group

Examine each modified file and understand **what it does functionally** (not just its path):
- Read the diff of each file to understand the nature of the change
- Group files that belong to the **same functional change** (e.g., a Handler + its Messages + its test = one commit)

Grouping criteria:
- Files that implement the **same feature or fix** → one commit
- Files that are **independent changes** (e.g., a fix + an unrelated refactor) → separate commits
- Test files go with the **production code they test**, not in a separate commit
- Config files (pom.xml, MANIFEST.MF, plugin.xml) go with the **code they support**

If all changes are functionally cohérent → **one single commit**.

### Phase 3: Present the plan

```
Je propose :

Commit 1: fix(migration): prevent double migration on git branch switch
  - ProjectMigrationListener.java
  - ImportBonitaProjectOperation.java
  - ProjectMigrationListenerTest.java

Commit 2: test(migration): add test for clone migration path
  - ImportClonedRepositoryTest.java
```

Or if single commit:
```
Je propose un seul commit :

fix(migration): prevent double migration on git branch switch
  - 4 files
```

**Wait for user validation.** The user may regroup, rename, or skip.

### Phase 4: Execute commits

For each validated commit group:
1. `git add <files>` — only the files in this group
2. `git commit` with HEREDOC format
3. Verify with `git status`

Never `git add -A` or `git add .` — always explicit file list.

### Phase 5: Report

```
Done:
- [commit hash] fix(migration): prevent double migration on git branch switch (3 files)
- [commit hash] test(migration): add test for clone migration path (1 file)

Not pushed. Run `git push` when ready.
```

## Commit message format

Follow `.claude/rules/workflow/commit-conventions.md`:
- `type(scope): description` — imperative, < 72 chars, lowercase
- Types: feat, fix, refactor, chore, test, docs
- No `Co-Authored-By: Claude`
- No emojis

## Rules

- **Never push** unless the user explicitly asks
- **Never amend** — always new commits
- **Never `git add -A`** — always explicit file list
- **Never stage files that look like secrets** (.env, credentials, tokens) — warn instead
- **Checkpoint before committing** — always present the plan first
- **Respond in the user's language**
