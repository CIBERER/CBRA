---
name: generating-add
description: Create or update an Architecture Design Document when requested architecture work materially changes system structure. Do not use for routine code edits.
--- 
# Generating an ADD

To generate an Architecture Design Document (ADD), follow these steps:

## Context

Resolve `{Project_Folder}` and `{Agents_file}` from global instructions. Use the supplied PRD
and relevant current documentation. Stop if required context cannot be resolved.

### ADD output templates

Read and follow specific templates like [ADD template](ADD.template.md) 

Read and respect the current [AGENTS]({Agents_file}) file if it exists.

## Steps to follow:

### Step 1: Clarifying Questions

-[ ] Ask only critical questions where the initial prompt is ambiguous. Focus on:

  - System Requirements: What are the key technical requirements?
  - Constraints: Are there any technology or architecture constraints?
  - Non-Functional Requirements: Are there any security, or scalability needs?

### Step 2: Drafting the ADD

- [ ] Draft the ADD following the [ADD template](ADD.template.md)
  - Ensure each section is filled out with relevant information.
  - Keep the document concise, aiming for clarity and brevity.
  - Put a TOC at the start of the document.

### Step 4: Review and Finalize

- [ ] Review the documents for completeness and accuracy.
- [ ] Write the final Architecture Design Document (ADD) at `{Project_Folder}/ADD.md`. 

## Output Checklist 

- [ ] A concise, complete ADD at `{Project_Folder}/ADD.md`.

Do not update `{Agents_file}` as an implicit side effect. Report any instruction change that
may be needed so the caller can authorize it separately.
