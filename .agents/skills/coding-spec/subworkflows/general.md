---
title: General
subtitle: Follow general subworkflow specifications
weight: 1
---

The keywords "MUST", "MUST NOT", "SHOULD", etc. are to be interpreted as described in [RFC 2119](https://tools.ietf.org/html/rfc2119).

## Minimum subworkflow size

Subworkflows SHOULD combine tools that make up a logical unit in an analysis step.
A subworkflow MUST contain at least two modules.

## Version reporting through topics

Use the contract from the [nf-core topic migration guide](https://nf-co.re/docs/tutorials/migrate_to_topics/update_pipelines).
Modules publish `(process, tool, version)` tuples to the `versions` topic; template-based
modules may publish a `versions.yml` path to that same topic.

Subworkflows MUST NOT require an `out.versions` file channel from migrated modules or mix and
re-emit their versions manually. The pipeline collects `channel.topic('versions')` and handles
tuple and file entries according to its template. Version collection is not a subworkflow
output contract.
