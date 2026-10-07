---
name: nfcore-component-reuse
description: Analyze a Nextflow functional specification before implementation planning to identify reusable local and nf-core modules or subworkflows, reusable compositions, and functionality that requires new implementation. Use from planning-spec before designing the final Nextflow component structure.
---

# Purpose

Determine what existing Nextflow components can satisfy a functional specification before
`planning-spec` designs the final implementation.

Do not design the final Nextflow structure or implement missing components.

# Workflow

## 1. Derive functional requirements

Read the specification and identify:

- inputs and outputs
- processing operations and dependencies
- explicitly required methods or tools
- file and channel semantics
- relevant behavioral constraints

Keep this as a functional decomposition. Do not assign module or subworkflow boundaries yet.

Treat explicitly specified methods and tools as hard requirements.

## 2. Find reusable components

Search the current repository first for modules and subworkflows that can satisfy individual
requirements or groups of requirements.

For requirements not fully covered locally, run:

    python scripts/search_nfcore.py <search terms>

Use multiple searches when useful. Search by tool, operation, input/output format and relevant
synonyms. Do not start a new search until a previous search has completed and returned results.

The script uses the available `nf-core/tools` installation and returns structured metadata for
candidate nf-core modules and subworkflows.

If nf-core must be checked but the script cannot query it, stop. Do not infer that new implementation
is required.

## 3. Verify candidates and compositions

Verify plausible candidates against their interfaces and behavior. Inspect `main.nf` when metadata is
not sufficient.

Do not accept a component based only on its name.

Consider:

1. one component covering several functional requirements
2. compositions of existing components
3. individual components for remaining requirements

Do not require one Nextflow component per preliminary functional operation.

For each plausible local or nf-core component, inspect its supported
configuration and composition surface before rejecting reuse. Check, when
applicable:

- optional inputs and outputs;
- `task.ext.args`, `task.ext.args2`, `task.ext.prefix`, and `task.ext.when`;
- process aliases and scoped `withName` configuration;
- configurable output modes already represented by the process or stub;
- whether missing behavior can be supplied by local wiring rather than by
  changing or duplicating the component.

A difference in invocation arguments is not evidence that a new component is
required when the existing component intentionally exposes those arguments as
per-invocation configuration.


When tests are available for a plausible reusable component, inspect them as supporting evidence.
Record useful test fixture paths, companion files, derived prerequisites, and setup or generation
commands that may help implementation planning resolve test data. Treat these as evidence and
candidates, not as requirements of the functional specification.



## 4. Identify gaps

Only after considering existing components and compositions, classify uncovered executable
requirements as `new-required`.

Do not design those components. `planning-spec` owns the final component design and converts these
gaps into `new` modules or subworkflows when appropriate.

# Output

Return the analysis using
[`references/reuse-analysis.template.yaml`](references/reuse-analysis.template.yaml).

Use:

- `reuse-local` for compatible components already present in the repository
- `import-nf-core` for compatible nf-core components
- `composition` when several existing components jointly satisfy a requirement
- `new-required` only for functionality not satisfied by existing components or compositions

Record compatibility evidence for every resolution, including relevant upstream test evidence
when inspected. For nf-core components, record the exact component name and checked
`nf-core/modules` commit SHA.

Do not generate Nextflow code or an implementation plan.
