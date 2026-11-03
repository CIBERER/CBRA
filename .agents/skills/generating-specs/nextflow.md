# Nextflow specifications

Use this profile when the requested behavior will be implemented with Nextflow or nf-core.
Product owner writes one functional specification only. When the request is for a subworkflow,
specify that subworkflow's external behavior and do not decompose it into internal modules. Module
boundaries, implementation choices and reuse decisions belong to the implementation plan.

Add a `Test data` section to the specification:

- Define the smallest meaningful scenario that exercises each required behavior.
  Prefer one sample and a restricted genomic region when that preserves the same
  functional behavior.

- For each functional input role, describe only the properties required by the
  behavior: format, semantic constraints, cardinality, metadata relationships,
  and compatibility requirements.

- Record an exact file or source location only when the user or functional
  requirement explicitly requires it.

- Do not resolve concrete fixtures, implementation-specific companion files,
  derived test prerequisites, reference-generation methods, or expected
  reference artifacts. These belong to implementation planning.