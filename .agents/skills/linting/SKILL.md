---
name: linting
description: Run lint checks and, when requested, fix lint findings using repository conventions.
---

# Linting

Use the repository's lint commands, pinned tools, and configuration for the requested scope.
For Nextflow projects, load [Nextflow](./nextflow.md).

- Run checks without automatic fixes unless the task includes corrections.
- When correcting, keep edits focused, review the diff, and re-run the affected checks.
- Do not disable rules merely to obtain a passing result.
- Report commands, results, remaining findings, and unavailable checks.
