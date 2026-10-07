---
name: project-bootstrap
description: Initialize or refresh a project's global agent instructions, briefing, and changelog. Use only when explicitly invoked for project bootstrap.
---

# Project Bootstrap

Use [blueprint.md](./blueprint.md) to define the project's global placeholders and
[AGENTS.template.md](./AGENTS.template.md) to create or update `{Agents_file}`.
Use [CHANGELOG.template.md](./CHANGELOG.template.md) only when `{Root_Folder}/CHANGELOG.md` does
not already exist.

## Workflow

1. Resolve the required global path placeholders. Ask the user to confirm any value that cannot be
   resolved safely.
2. Review the existing `{Agents_file}`, `{Briefing_file}`, `{Root_Folder}/CHANGELOG.md`, repository
   structure, applicable technical profiles, and verified development commands.
3. Render `{Agents_file}` from the template. Replace named content placeholders, include the
   observed folder structure, and omit optional fields that do not apply.
4. Confirm that the generated file contains no anonymous or unresolved template placeholders.
5. Update `{Briefing_file}` with a short, feature-focused product summary.
6. Create `{Root_Folder}/CHANGELOG.md` from the changelog template when it is absent. Never replace
   or truncate an existing changelog.
7. Report the resolved global placeholders, selected profiles, commands, and changed files.

Do not infer paths that would move work outside `{Root_Folder}`. This skill is a manual
bootstrap workflow and must not be invoked implicitly by other agents.
