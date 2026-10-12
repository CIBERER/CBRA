---
name: importing-nf-core
description: Import an approved nf-core module or subworkflow with nf-core tools. Use only for implementation-plan items classified as import-nf-core; do not reimplement or modify imported components.
---

# Import nf-core components

Require the plan's exact component type, remote name, pinned `nf-core/modules` commit SHA, and
pipeline root. Stop if any value is missing or the remote cannot be checked.

From the pipeline root, or with `--dir <pipeline-dir>`, run exactly one applicable command:

```console
nf-core modules install <module> --sha <commit-sha>
nf-core subworkflows install <subworkflow> --sha <commit-sha>
```

Do not use `--force` unless replacement is explicitly approved. Never hand-copy, reimplement, or
edit the installed component. Validate the installed files, provenance metadata, and all
transitive changes with the applicable repository and nf-core lint checks. If the pinned component
is unavailable or incompatible, stop instead of creating a local substitute.

Report the command, component and SHA, every changed file, validation result, and blockers to
builder. Do not implement consuming wiring or perform Git operations.
