---
name: start-task
description: Prepare a clean local task branch when explicitly requested or when an active builder workflow starts. Do not use for ordinary edits on an existing task branch.
---

# Start Task

Prepare the workspace only for a direct request or the initial step of an explicitly invoked
builder workflow.

1. Inspect Git status and the current branch.
2. If pending work exists, do not commit or move it automatically. The only exception is an active
   builder handoff containing exactly the specification path explicitly approved by the user: verify
   that diff and carry it unchanged onto the task branch. Any other pending path remains blocking
   and requires user direction.
3. Determine `feat`, `fix`, or `chore` from the task and create a concise slugged branch.
4. If the correct dedicated task branch is already active, preserve it instead of creating
   another one. Confirm the branch and final local status.

Keep work local. Do not pull, push, merge, or otherwise contact a remote unless the user
explicitly asks for that remote operation.
