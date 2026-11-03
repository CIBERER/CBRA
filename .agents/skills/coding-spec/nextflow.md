# Nextflow implementation guidelines

These guidelines apply to general Nextflow pipelines, modules, subworkflows, and configuration.
Project conventions take precedence. For nf-core code, apply these guidelines together with
[`nf-core.md`](./nf-core.md).

The keywords "MUST", "MUST NOT", "SHOULD", etc. are to be interpreted as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).

## Language and syntax

- New code MUST use DSL2 and SHOULD be valid under the strict syntax parser.
- Code MUST be free of Nextflow parser, lint, and runtime warnings supported by the repository's
  pinned Nextflow version.
- Variables MUST be declared with `def` or an explicit type. Do not create variables through an
  undeclared assignment.
- Deprecated features, including the `shell:` process section, MUST NOT be introduced.
- Experimental features MUST NOT be used unless the repository explicitly enables and tests them.

## Pipeline structure

- The entry workflow SHOULD coordinate data flow, validation, and component invocation. It SHOULD NOT contain command implementation details.
- Reusable processes and named workflows MUST declare explicit inputs and named outputs.
- Pipeline parameters SHOULD be read and validated at the entry boundary, then passed explicitly to workflows and processes. Included modules MUST NOT depend on implicit access to parent `params`.
- A process or named workflow can only be invoked once in a calling workflow. Import it under an
  alias when multiple independent invocations are required.

```nextflow
include { ALIGN as ALIGN_TUMOR; ALIGN as ALIGN_NORMAL } from './modules/align'

workflow ALIGN_PAIR {
    take:
    tumor_reads
    normal_reads

    main:
    ALIGN_TUMOR(tumor_reads)
    ALIGN_NORMAL(normal_reads)

    emit:
    tumor_bam  = ALIGN_TUMOR.out.bam
    normal_bam = ALIGN_NORMAL.out.bam
}
```

## Processes

- Every file or directory used by a task MUST be declared as a `path` input or created by the task. A process MUST NOT reach into another task's work directory or rely on a host-specific path.
- Use `val` for scalar data, `path` for staged files, and `tuple` when values belong to one logical record. Tuple shape and element order MUST remain stable across a workflow boundary.
- Inputs and outputs SHOULD use descriptive names. Outputs consumed downstream SHOULD use `emit`.
- Output patterns MUST be as narrow as practical so logs, inputs, and unrelated files are not
  published accidentally.
- Declare `arity` when the number of expected input or output files is part of the contract and the repository's pinned Nextflow version supports it.
- Mark an output `optional: true` only when absence is a valid, documented result.
- Conditional routing SHOULD happen in the calling workflow with branching or filtering. Use a
  conditional process script only when the selected command is inherently part of that process.
- A process script MUST fail when its command fails. Do not mask failures with unconditional
  `|| true`; handle an exceptional exit code with a specific validation of the expected result.
- Bash variables in an interpolated process script MUST be escaped. Use single-quoted strings when no Nextflow interpolation is required.

```nextflow
process SUMMARIZE {
    tag "${sample_id}"

    input:
    tuple val(sample_id), path(report)

    output:
    tuple val(sample_id), path("${sample_id}.summary.tsv"), emit: summary

    script:
    """
    summarize \
        --threads ${task.cpus} \
        --input ${report} \
        > ${sample_id}.summary.tsv
    """
}
```

## Channels and data flow

- Treat channels as asynchronous data streams. Code MUST NOT rely on task completion order or item arrival order unless it applies an explicit ordering operation.
- Distinguish queue channels from reusable value channels. A process invocation SHOULD receive at most one queue channel; other inputs SHOULD be values or should be combined upstream.
- Related values SHOULD travel together in a tuple rather than in separate channels that must remain positionally synchronized.
- Keyed records MUST be combined with a keyed operator such as `join`, `combine(by:)`, or `groupTuple`.  Do not use `merge` to associate records by arrival order.
- Operators SHOULD be pure: return transformed values instead of mutating input maps or collections.
- Use `map`, `filter`, `branch`, and `groupTuple` to express data flow. Use `collect` only when a  downstream task truly requires the entire stream, because it introduces a synchronization point.
- Channel shapes SHOULD be documented at workflow boundaries and after non-obvious transformations.
- Debug output such as `view` MUST NOT remain in production code unless it is an intentional part of  the user-facing logging behavior.

```nextflow
reads
    .map { meta, read_files -> tuple(meta.id, meta, read_files) }
    .join(reference_by_id, by: 0)
    .map { id, meta, read_files, reference -> tuple(meta, read_files, reference) }
    .set { reads_with_reference }
```

## Functions and workflow logic

- Helper functions SHOULD be deterministic and free of file-system, network, and process side
  effects. External commands belong in a process.
- Functions and operator closures SHOULD return new values and MUST NOT mutate shared workflow state.
- Closure parameters SHOULD be named explicitly whenever an item has multiple fields or `it` would
  be ambiguous.
- Complex domain logic SHOULD live in a separately testable script or library instead of growing
  inside channel closures.

## Configuration and portability

- Executor, queue, storage, container runtime, and site-specific paths MUST be configured outside
  process implementations.
- Processes SHOULD use semantic labels. Configuration SHOULD use `withLabel` for classes of tasks and
  `withName` only for targeted overrides.
- Resource requests SHOULD use Nextflow units such as `4.GB` and `2.h`. Commands SHOULD consume
  allocated resources through `task.cpus`, `task.memory`, and related task properties.
- Dynamic retry resources SHOULD be bounded by explicit limits and based on `task.attempt` or the
  previous task trace, according to the repository's supported Nextflow version.
- Software dependencies MUST be reproducible. Pin container tags or digests and package versions;
  do not introduce mutable tags such as `latest`.
- Secrets MUST use the repository's supported secret mechanism and MUST NOT be committed, embedded in
  command strings, or printed to logs.
- Configuration includes and profiles SHOULD remain composable. Be aware of config precedence and
  inspect the resolved configuration when changing selectors or profiles.

## Parameters and validation

- Every public parameter MUST have a documented type, default or required status, and accepted range
  or values.
- Required parameters and incompatible combinations MUST be validated before expensive processes are
  launched.
- File parameters SHOULD be converted to `Path` values with the appropriate channel factory and
  checked for existence where failure would otherwise be obscure.
- Boolean values MUST be treated as booleans. Do not encode them as strings or infer them from a
  non-empty string.
- Defaults SHOULD describe portable pipeline behavior; environment-specific values belong in profiles.

## Reproducibility and publication

- Task outputs MUST be determined by declared inputs, parameters, software, and configuration. Hidden
  dependencies on the launch directory, current time, or mutable remote resources SHOULD be avoided.
- Randomized tools SHOULD receive an explicit seed when reproducibility is expected.
- `publishDir` or workflow outputs SHOULD publish declared process outputs only. Downstream processes
  MUST consume channels, not published paths.
- Output names SHOULD be deterministic and unique within their publication scope.

## References

- [Nextflow scripts](https://docs.seqera.io/nextflow/script)
- [Nextflow processes](https://docs.seqera.io/nextflow/process)
- [Nextflow workflows](https://docs.seqera.io/nextflow/workflow)
- [Nextflow operators](https://docs.seqera.io/nextflow/reference/operator)
- [Nextflow configuration](https://docs.seqera.io/nextflow/config)
