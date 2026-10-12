---
name: push-changes
description: Push an already committed current branch when the user explicitly requests remote publication. Do not create commits, merge, or tag.
---

# Push Changes

Use this skill only when the user explicitly asks to push work to the remote repository.

1. Inspect the current branch, upstream, Git status, and commits pending publication.
2. Stop if required work is uncommitted; report it rather than staging or committing it.
3. Confirm the requested commits are ready to publish, then push the current branch with its
   upstream configured when necessary.
4. Report the branch, commit(s) pushed, remote status, and any failure.

Do not push unrelated work. Do not merge into the default branch or create a tag unless
the user explicitly requests it.
