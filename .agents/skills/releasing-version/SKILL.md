---
name: releasing-version
description: Prepare version, changelog, and release documentation when the user explicitly requests a release. Do not merge, push, or tag unless separately requested.
---

# Prepare a Release

Resolve `{Root_Folder}`, `{Project_Folder}`, `{Specs_Folder}`, and other release paths from
the global project instructions before editing.

1. Review changes since the previous release and determine the version using
   [sem-ver.md](./sem-ver.md) plus project policy.
2. Identify the specifications included in the release. Require them to be `Verified`, then
   change them to `Released`; do not skip or regress states.
3. Update the configured version source and `{Root_Folder}/CHANGELOG.md`.
4. Update only documentation whose behavior, setup, or public contracts changed. Use
   `documenting-code` when a changed public API requires source or generated documentation.
5. Run the release validation commands defined by the project or supplied profile.
6. Create a local release commit only when the release request authorizes it.
7. Report the version, changelog entries, released specification paths, documentation,
   validation, and remaining delivery actions.

Merging, pushing, tagging, publishing packages, and rewriting history require separate explicit
authorization and are not part of this skill by default.
