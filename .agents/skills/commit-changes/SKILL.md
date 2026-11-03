---
name: commit-changes
description: Create reviewed local commits when requested or after an active builder verifies a completed implementation or direct-import cycle. Never publish or rewrite history.
---

# Committing Changes Skill

Use this skill only when the user explicitly asks for a local commit or the active builder has
verified a completed cycle. A normal cycle requires RED, GREEN and REFACTOR; a profile-authorized
direct-import cycle requires successful import and validation without implementation delegates.

Commit completed preparatory cycles before any later human review. Do not commit a failing or
incomplete cycle. When authorized:

1. **Check for uncommitted changes**:
  - Use `git status` to see if there are any uncommitted changes.
2. **Group changes**:
  - If there are multiple files changed, group them logically if possible.
  - Decide on meaningful commit messages for each group.
3. **Stage changes**:
  - Stage only reviewed files for each group.
  - Avoid `git add .` unless the user explicitly asks to include every change.
4. **Commit changes**:
  - Commit the staged changes using [conventional commit messages](./conventional-commits.md) guidelines.
5. **Keep commits local**:
  - Do not push, merge into the default branch, or rewrite history unless explicitly requested.

Report the reviewed files, commit hash and message, remaining worktree state, and any
blocker. Do not include unrelated changes in the commit.
