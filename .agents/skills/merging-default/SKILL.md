---
name: merging-default
description: Merge a reviewed task branch into the default branch only when the user explicitly requests that local history operation. Remote publication remains separate.
---

# Merge into the Default Branch

1. Inspect the current branch, default branch, worktree, and commits to integrate.
2. Stop if the worktree is dirty, either branch is unresolved, or the requested source branch
   cannot be identified safely.
3. Update remote references only when the user separately authorizes network access. Do not
   pull or push as an implied part of a local merge.
4. Check out the default branch and merge the reviewed source branch without rewriting
   existing history.
5. If conflicts occur, stop and report them; do not guess at resolution intent.
6. Verify the resulting history and relevant tests, then report the branches and merge commit.

Do not delete branches, push, tag, or release unless those actions were explicitly requested.
