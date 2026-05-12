---
name: sync-mainline
description: Rules and workflow for updating the local mainline branch from remote and safely merging it into the current feature branch. Trigger when asked to sync, before creating PRs, or when resolving out-of-date branch issues.
---

# Sync Mainline

Workflow rule for updating the mainline branch (e.g., `main`, `master`, `develop`) from the remote and merging it cleanly into the current feature branch.

## 1. Intents / When to Use

- **Explicit Request:** The user explicitly asks to sync master/main or merge latest.
- **PR Preparation:** Before creating a Pull Request, to ensure the feature branch is up to date and tests pass.
- **Stale Branch:** When you notice the current branch is far behind mainline or has known missing upstream dependencies.

## 2. Pre-flight Checks (Must Do)

**You MUST NOT run the sync script on a dirty working tree if it risks conflicts.**
1. Run `git status` to ensure there are no uncommitted tracked file changes that might interfere with checkout or merge.
2. If there are uncommitted changes, either `git commit` them (if they represent a logical unit of work) or `git stash` them before proceeding.
3. Ensure you are currently checked out on the feature branch that needs to receive the update.

## 3. Execution

Execute the companion script located in this skill's `scripts/` directory. By default, it auto-detects the remote and mainline branch.

```bash
# General format (resolve <SKILL_DIR> to the absolute path of this skill directory):
bash <SKILL_DIR>/scripts/git-sync-mainline.sh [remote] [main_branch]

# Examples:
bash <SKILL_DIR>/scripts/git-sync-mainline.sh
bash <SKILL_DIR>/scripts/git-sync-mainline.sh origin master
bash <SKILL_DIR>/scripts/git-sync-mainline.sh upstream develop
```

## 4. Conflict Resolution Protocol

If the script exits with conflicts (`=== Merge conflicts detected ===`), you MUST follow these steps to resolve them:

1. **Understand both sides:** Open each conflicted file and examine the git conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`). Do NOT simply delete the markers. Analyze what the mainline changed versus what the feature branch changed.
2. **Synthesize:** Make the necessary logical source code changes to integrate both sets of intentions. Preserving intended behavior from both sides when possible.
3. **Verify:** Check for syntax errors. No conflict markers should remain in the file.
4. **Finalize:**
   - Run `git add <resolved-files>`.
   - Run `git commit --no-edit` to complete the merge.
   - Never discard unrelated local changes.

## 5. Output Contract

After a successful sync (and conflict resolution, if any), you MUST report to the user:
- The result (`merged cleanly`, `already up to date`, or `conflicts resolved`).
- The merge commit hash (if created).
- A list of any files that had conflicts resolved.
- A summary of current state: run `git status -sb` and share the output.
