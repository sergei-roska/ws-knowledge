---
name: sync-mainline
description: Update local mainline branch from remote and merge it into the current branch with safe conflict handling. Use when user asks to sync from main/master/develop, merge latest mainline into feature branch, or resolve merge conflicts after syncing.
---

# Sync Mainline

Update the mainline branch from remote and merge it into the current feature branch.

## Quick Start

1. Run `bash /home/sr/.codex/skills/sync-mainline/scripts/git-sync-mainline.sh` from repository root.
2. If merge succeeds: report success, merge commit hash, `git status -sb`.
3. If conflicts occur: resolve them, then `git add <resolved-files>` and `git commit --no-edit`.

## Optional Arguments

```bash
bash /home/sr/.codex/skills/sync-mainline/scripts/git-sync-mainline.sh [remote] [main_branch]
```

- `remote`: default `origin`
- `main_branch`:
  - if passed by user/command, use it as-is (`main`, `master`, `develop`, etc.)
  - if omitted, auto-detect from `refs/remotes/<remote>/HEAD`
  - if auto-detection fails, stop and ask user to provide `main_branch` explicitly (no fallback)

Examples:
- Auto-detect mainline from origin HEAD: `bash /home/sr/.codex/skills/sync-mainline/scripts/git-sync-mainline.sh`
- Explicit master: `bash /home/sr/.codex/skills/sync-mainline/scripts/git-sync-mainline.sh origin master`
- Explicit develop from upstream: `bash /home/sr/.codex/skills/sync-mainline/scripts/git-sync-mainline.sh upstream develop`

## Conflict Resolution

1. Inspect conflicted files (listed in script output).
2. Remove all markers: `<<<<<<<`, `=======`, `>>>>>>>`.
3. Preserve intended behavior from both sides when possible.
4. Stage resolved files and finish merge: `git commit --no-edit`.
5. Never discard unrelated local changes.

## Output Contract

Report:
- Result: `merged` or `blocked`
- Merge commit hash (if created)
- Conflicted files (if any resolved)
- `git status -sb`
