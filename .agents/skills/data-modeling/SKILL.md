---
name: data-modeling
description: Define or update persistent entities, attributes, relationships, and cardinalities when a specification changes the system's data model. Do not use for transient DTOs or formatting-only changes.
---

# Data Modeling Skill

Resolve `{Specs_Folder}` and `{Project_Folder}` from global instructions before writing.
Stop if a required placeholder or input artifact cannot be resolved.

The model will be a set of entities (with attributes) and relationships (with cardinalities).

Respect the current ER model if it exists. Change only entities and relationships required by
the supplied specification; do not redesign unrelated data.

Apply this skill when the specification introduces or changes persistent entities, attributes,
relationships, or cardinalities. When it applies and no current ER model exists, create
`{Project_Folder}/ERM.md`; the absence of the file is not a reason to skip modeling. When it does
not apply, leave the model untouched and report the concrete reason.

## Context

- [The specification file]({Specs_Folder}/<spec-slug-id>.spec.md)
- [Current ER Model]({Project_Folder}/ERM.md) (if exists)

## Steps to follow:

### Step 1: Analyze the specification and current model.
 - [ ] Identify the key entities involved in the system based on the specifications.
 - [ ] Consider relevant repository conventions and existing persistence interfaces.
### Step 2: Define entities and attributes.
 - [ ] For each identified entity, list its attributes and their data types.
### Step 3: Define relationships and cardinalities.
 - [ ] Identify the relationships between entities and specify their cardinalities (e.g., one-to-many, many-to-many).
### Step 4: Write the ER model.
 - [ ] Follow the format in the [ER Model template](ERM.template.md).
### Step 5: Review and finalize the ER model.
 - [ ] Ensure the ER model accurately reflects the specification and existing model.

## Output Checklist

- [ ] An Entity-Relationship (ER) model at `{Project_Folder}/ERM.md`.
- [ ] The ER model should include all relevant entities, attributes, and relationships required by the specification.
- [ ] The created or updated ER-model path is reported to the caller.
