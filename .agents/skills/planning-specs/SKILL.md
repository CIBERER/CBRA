---
name: planning-specs
description: Create or update the single implementation plan for an approved specification. Do not use for unscoped ideas or direct code edits.
---

# Generate Plan Skill

Resolve `{Specs_Folder}` and `{Plans_Folder}` from global instructions.
Stop if a required placeholder or input artifact cannot be resolved.

The plan will be a set of ordered steps, each with specific tasks to complete.

## Context

- [The Specification file]({Specs_Folder}/<spec-slug-id>.spec.md)

Each source specification owns one plan. Resolve an existing plan by its specification identifier
or path before choosing an output path.

For Nextflow work, also load [Nextflow planning](./nextflow.md) and [test-data discovery](./test_data.md).
## Steps to follow:

### Step 1: Think about the overall implementation.
 - [ ] Understand the specification requirements.
 - [ ] Consider relevant repository conventions and existing interfaces.
 - [ ] Choose the simplest viable approach to implement the spec.
### Step 2: Decompose the implementation in steps.
 - [ ] Break down the implementation into 3 to 9 steps 
 - [ ] Ensure each step is an ordered logical unit of work.
### Step 3: Define tasks for each step.
 - [ ] For each step, list outcome-oriented tasks (<= 5) needed to complete it.
 - [ ] Ensure tasks are clear and actionable.
 - [ ] Tasks should be verifiable by the delegated agent without prescribing internal implementation tactics.
### Step 4: Resolve and write the implementation plan.
 - [ ] Follow the format in the [Implementation Plan template](plan.template.md).
 - [ ] If exactly one plan already maps to the specification, update it in place and preserve its path.
 - [ ] If no plan maps to the specification, create `{Plans_Folder}/<spec-slug-id>.plan.md`.
 - [ ] If multiple candidates exist, stop and ask the user; do not create another plan.
### Step 5: Review and finalize the plan.
 - [ ] Ensure the plan is comprehensive and feasible.
 - [ ] Confirm that every field required by an applicable framework profile
is present and resolved for the complete implementation plan.
 - [ ] Map every acceptance criterion to one or more plan increments and their verification.
 - [ ] Leave the source specification status unchanged; lifecycle transitions belong to the caller.

## Output Checklist

- [ ] A detailed implementation plan at `{Plans_Folder}/<spec-slug-id>.plan.md`.
- [ ] Exactly one plan file associated with the source specification.
- [ ] Every acceptance criterion mapped to an implementation increment and verification.
- [ ] Every applicable framework-profile field present and resolved for the complete
  implementation plan before the plan is finalized.
- [ ] The source specification identifier, plan path, and whether it was created or updated reported
  to the caller.
