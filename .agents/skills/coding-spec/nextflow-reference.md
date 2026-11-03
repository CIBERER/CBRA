# Nextflow reference implementation

Use this profile only when an approved Nextflow implementation plan has round `reference`.
The result is an independent reference implementation and concrete review data, not production
Nextflow code.

## Location and languages

- Keep generated inputs, outputs and manifests under
  `{Project_Folder}/reference-data/<spec-slug-id>/`, outside product source and excluded from
  version control. Never stage or commit them.
- Version only generation and validation scripts under
  `{Specs_Folder}/<spec-slug-id>.reference/`.
- Prefer Bash for orchestration and command execution. Use Python for structured parsing,
  non-trivial transformations or validations that would be fragile in shell. Keep both small,
  deterministic and parameterized; do not embed generated data in scripts.

## Reproducible execution

- Bash scripts use `set -euo pipefail`, quoted paths, explicit inputs and outputs, and fail before
  overwriting existing reference files. Python scripts expose explicit arguments and return a
  non-zero status on validation failure.
- Materialize the inputs selected by the specification with versioned Bash or Python scripts.
  Verify source revisions and checksums before use, fetch required companion files, and never
  modify user-supplied originals.
- Use the exact plan-selected image with Apptainer. Accept an existing SIF or pull its pinned
  OCI/Docker URI to the untracked data workspace. Do not use mutable tags such as `latest` or fall
  back to host-installed tools.
- Execute tools with `apptainer exec --cleanenv`; bind inputs read-only and outputs read-write:

  ```bash
  apptainer exec --cleanenv \
      --bind "${input_dir}:/inputs:ro" \
      --bind "${output_dir}:/outputs:rw" \
      "${image_path}" tool --input /inputs/example --output /outputs/result
  ```

- Record the Apptainer version, pinned image URI or digest, SIF checksum, tool versions, parameters,
  seeds and the exact reproduction command in an untracked manifest. Use multiple pinned images
  when a subworkflow's tools do not share a container.
- Implement the specified behavior independently with the underlying tools. Do not invoke, copy or
  translate the module or subworkflow being developed.

Check Bash with `bash -n`, Python with the repository's configured checks, and execute the reference
tests. The test harness may run on the host, but every command that exercises the reference
behavior must use the same `apptainer exec --cleanenv` image and bind mounts used for RED. Produce
every concrete input and output required by the plan, including companion files. Report paths,
checksums, commands and validation results to builder so it can commit the round and continue
automatically.
This round does not satisfy the Nextflow implementation or advance the specification to `Coded`.
