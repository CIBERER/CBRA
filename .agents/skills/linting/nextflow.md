# Nextflow linting with nf-core tools

Use the available nf-core tools installation and confirm options with the command's `--help`.
From the repository root, select the requested scope:

- Pipeline: `nf-core pipelines lint`.
- Module: `nf-core modules lint <module>`.
- Subworkflow: `nf-core subworkflows lint <subworkflow>`.

Use component names, not file paths; use `--all` only when all components are in scope.
Respect `.nf-core.yml`. For non-nf-core projects, report inapplicable conventions rather than
introducing nf-core structure solely to satisfy lint. These checks do not replace execution tests.

Official references: [pipelines](https://nf-co.re/docs/nf-core-tools/cli/pipelines/lint),
[modules](https://nf-co.re/docs/nf-core-tools/cli/modules/lint),
[subworkflows](https://nf-co.re/docs/nf-core-tools/cli/subworkflows/lint).
