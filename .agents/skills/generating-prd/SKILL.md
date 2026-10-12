---
name: generating-prd
description: Create or update a Product Requirements Document for product-level discovery, scope, and requirements work. Do not use for a single implementation task with an existing specification.
--- 
# Generating a PRD

Resolve `{Root_Folder}`, `{Agents_file}`, `{Project_Folder}`, and `{Briefing_file}` from global
instructions. Stop if a required placeholder or requested input cannot be resolved. Understand
the product idea, stakeholders, target users, and business objectives before drafting.

## Context

You can be working on either a greenfield or brownfield project.

### Greenfield scenario

Starting a new project from scratch.

Use the provided project idea and briefing at `{Briefing_file}`. Inspect other existing repository
documentation only when it adds relevant product context.

### Brownfield scenario

Working on a legacy or existing project.

Use the current product and repository files as evidence. Review `{Agents_file}`, the existing
`{Project_Folder}/PRD.md`, `{Project_Folder}/ADD.md`, related specifications, and any relevant
documentation that actually exists. README, changelog, and documentation folders are optional
sources; do not assume their names or locations.

### PRD output template

Read and follow any specific [PRD template](PRD.template.md) to generate the document.

## Steps to follow:

### Step 1: Clarifying Questions

- [ ] Ask only critical questions where the context is ambiguous. 
  - Focus on:
    - Goal: What problem does this solve?
    - Target: Who will use this product?
    - Scope: What won't it do?
    - Core: What are the key features?
    - Solution: What is expected?

### Step 2: Drafting the PRD

- [ ] Draft the PRD following the [PRD template](PRD.template.md)
  - Do not write more than necessary, keep it concise and to the point.
  - Specifically cover:
    - Between 3 and 9 Functional Requirements (less is better)
    - Between 1 and 5 Technical Requirements (less is better)

### Step 3: Review and Finalize

- [ ] Review the PRD for completeness and clarity.
- [ ] Ensure all sections of the PRD template are filled out appropriately.
- [ ] On brownfield projects, update PRD feature status.
  - Mark existing features as Implemented.
  - New features should be marked as NotStarted. 
- [ ] Write the final PRD at `{Project_Folder}/PRD.md`.

## Output Checklist

- [ ] A comprehensive P.R.D. at `{Project_Folder}/PRD.md`.
