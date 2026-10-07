---
name: documenting-code
description: Add or update documentation attached to source code and generate language-specific documentation artifacts. Use when the user requests code or API documentation, or during a release that changes documented public interfaces. Do not use for README files, changelogs, or general product documentation.
---

# Documenting Code

Document public contracts and non-obvious behavior without changing runtime behavior.

## Inputs

- Resolve `{Root_Folder}`, `{Project_Folder}`, and other path placeholders from the project's global instructions.
- Accept one or more Markdown language or framework profiles by path.
- If a required placeholder cannot be resolved, stop and report it instead of guessing a universal directory.

Apply conventions in this order:

1. Explicit task instructions.
2. Existing repository conventions.
3. Supplied Markdown profiles.
4. This skill's generic rules.

Use [references/r.md](references/r.md) for R when applicable. Additional profiles may be supplied without modifying this skill.

## Workflow

1. Inspect the requested scope, relevant diff, public interfaces, and existing documentation conventions.
2. Identify contracts, constraints, errors, side effects, and behavior that are not evident from the code.
3. Add or update source documentation. Avoid comments that merely restate implementation details.
4. Run the documentation generator required by the applicable profile.
5. Review generated artifacts and exclude unrelated generated changes.
6. Run documentation validation and relevant tests defined by the repository or profile.
7. Report documented source files, generated artifacts, and commands run.

Do not update product documentation, changelogs, version files, branches, or commits as an implicit side effect.
