---
name: generating-specs
description: Create or update one lifecycle specification for a defined work item, with testable acceptance criteria. Do not use for implementation planning or code changes.
---

# Generating Specs Skill

Write the specification to implement a feature, bug correction, or enhancement.

Include the problem definition, solution overview, and acceptance criteria.

Keep the problem definition clear, concise, and focused.

Do not enter implementation details.

Make the acceptance criteria specific, and testable.

Do not write any code or tests, just the specification.

## Context

Resolve `{Specs_Folder}` from global instructions before writing. Stop if
a required placeholder or input artifact cannot be resolved.

The feature, bug correction, or enhancement must be provided in the input.

If not, ask for it before proceeding.

Types of specifications to generate include:
- New or current feature : `feat`
- Bug correction : `fix`
- Enhancement or refactor : `chore`

### Specification output template

Read and follow the specific [spec template](spec.template.md) to generate the document.

For Nextflow work, also load [Nextflow specifications](./nextflow.md).

## Steps to follow:

### Step 1: Capture inputs:
  - [ ] Confirm `feat/fix/chore` to specify; if missing, ask.
  - [ ] Draft the issue title from the request; if unclear, ask.
### Step 2: Resolve the lifecycle specification:
  - [ ] Prefer an explicitly supplied specification path or identifier.
  - [ ] Otherwise search `{Specs_Folder}` for a specification that clearly represents the same work.
  - [ ] If exactly one exists, update it in place and preserve its path and identifier.
  - [ ] If none exists, create one specification and record its stable identifier.
  - [ ] If multiple candidates exist, stop and ask the user; do not create another file.
  - [ ] A fix, enhancement, or new revision of the same work belongs in its existing file.
  - [ ] When approved changes alter an existing specification, reopen that file at `Draft`.
### Step 3: Define the Problem:
  - [ ] Clearly outline the problem that we aim to solve.
### Step 4: List User Stories:
  - [ ] Up to 3 US that describe the problem from the user's perspective.
### Step 5: Outline the Solution:
  - [ ] Describe the simplest approach without technical details for:
    - User/App interface
    - Model and logic
    - Persistence
### Step 6: Set Acceptance Criteria:
  - [ ] Up to 9 criteria in EARS format that define when the spec is complete.
  - [ ] Follow the [EARS format guide](./EARS.md).
### Step 7: Resolve the spec-slug-id:
  - [ ] Reuse the existing specification identifier when updating its file.
  - [ ] Otherwise create a short-name identifier based on the type and title.
  - [ ] Example: `feat-booking-management`.
### Step 8: Write the Specification:
  - [ ] Use short sentences and bullet points where possible.
  - [ ] Keep the specification concise but complete.
  - [ ] Follow the [spec template](spec.template.md)
  - [ ] Write it in markdown format at `{Specs_Folder}/<spec-slug-id>.spec.md`.

## Output Checklist

- [ ] A specification markdown file named `{Specs_Folder}/<spec-slug-id>.spec.md`.
- [ ] Exactly one lifecycle specification for the work item, left at `Draft`.
- [ ] Report its stable identifier, path, whether it was created or updated, and that explicit
  human approval is required before builder starts.
