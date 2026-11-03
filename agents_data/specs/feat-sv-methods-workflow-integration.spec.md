# SV methods workflow integration and selection Specification
- **ID**: feat-sv-methods-workflow-integration
- **Type**: feat
- **Status**: Verified

Allowed status flow: Draft -> Approved -> Planned -> Coded -> Verified -> Released. A requested
revision of the same work reopens this file at Draft.

## Problem Description

CBRA has three structural-variant (SV) calling plus AnnotSV subworkflows that are wired
inconsistently into the main `SNVS` workflow (`workflows/snvs.nf`):

- `SV_CALLING` (`subworkflows/local/sv_calling`) runs Manta germline calling and AnnotSV. It is
  always run for `--svs true --ngs_type wgs`.
- `SV_CALLING_DELLY` (`subworkflows/local/sv_calling_delly`) runs Delly calling and AnnotSV. It is
  also always run for `--svs true --ngs_type wgs`.
- `GRIDSS_ANNOTSV` (`subworkflows/local/gridss_annotsv`) runs GRIDSS calling and AnnotSV. It is
  not included or invoked by the main workflow, has no publishing configuration in
  `conf/modules.config`, and is not reachable from a pipeline run.

Their names do not follow one convention, and users cannot choose which SV callers run: WGS runs
always execute both Manta and Delly and can never execute GRIDSS.

### User Stories

- As a rare-disease analyst, I want to **choose which SV callers run from the pipeline command
  line** so that I only spend compute on the methods I need.
- As a pipeline maintainer, I want **every SV subworkflow named `{method}_annotsv`** so that
  configuration, tests, and documentation are predictable.

## Solution Overview

### User/App interface

- New pipeline parameter `--sv_tools`:
  - Type: string, a comma-separated list of method names.
  - Accepted values: `manta`, `delly`, `gridss` (lowercase).
  - Default: `manta,delly,gridss` 
  - Surrounding whitespace around each name is ignored; a repeated name runs that method once.
  - Declared in `nextflow.config` and `nextflow_schema.json` with a description that lists the
    accepted values and the default.
- `--svs` remains the master switch for SV/CNV analysis; the `--sv_tools` selection only applies
  when `--svs true` and `--ngs_type wgs`. The value of `--sv_tools` is validated by the pipeline
  parameter schema in every run, so an unknown name fails any invocation.
- The WES path (`--ngs_type wes`, CNV calling with `CNVS_CALLING`) is unchanged and ignores the
  `--sv_tools` selection (a valid value has no effect on it).
- Existing SV parameters keep their meaning: `--manta_config` and `--manta_joint` apply to Manta;
  `--annotsv_annotations` / annotation installation applies to all selected methods;
  `--gene_transcripts`, `--candidate_genes`, `--false_positive_snv` keep feeding Manta and Delly
  AnnotSV runs as today.
- GRIDSS uses the BWA index supplied with `--index`; when no index is supplied, the pipeline
  derives one from `--fasta`, as the mapping step already does.
- `docs/usage.md`, `README.md`, and `docs/output.md` describe `--sv_tools`, the three methods, and
  their output locations.

### Model and logic

- Subworkflow naming convention: `{method}_annotsv` (directory, lowercase) and
  `{METHOD}_ANNOTSV` (workflow name). Final names:

  | Current directory / workflow | New directory / workflow | Caller run |
  | --- | --- | --- |
  | `gridss_annotsv` / `GRIDSS_ANNOTSV` | unchanged | GRIDSS |
  | `sv_calling_delly` / `SV_CALLING_DELLY` | `delly_annotsv` / `DELLY_ANNOTSV` | Delly |
  | `sv_calling` / `SV_CALLING` | `manta_annotsv` / `MANTA_ANNOTSV` | Manta (germline) |

- The rename covers every reference: `include` statements, workflow names, `meta.yml`,
  `conf/modules.config` process selectors, subworkflow test files, test configs, nf-test
  snapshots, tags, the Delly manual test helper and its README, and user documentation. No
  reference to `sv_calling`, `SV_CALLING`, `sv_calling_delly`, or `SV_CALLING_DELLY` remains in
  pipeline code, configuration, tests, or documentation (lifecycle artifacts in `agents_data/`
  are excluded).
- The rename does not change the external inputs and outputs of each subworkflow.
- Selection: for a WGS SV run, the main workflow invokes exactly the subworkflows whose method
  name is in `--sv_tools`, each on every input sample BAM (from mapping or from the samplesheet).
- Validation happens before any process starts:
  - An unknown name fails the run, whatever `--svs` and `--ngs_type` are, through
    `nextflow_schema.json` parameter validation, with an error message that names the invalid
    value and lists the accepted values.
  - An empty selection (empty string or only separators) while `--svs true` and
    `--ngs_type wgs` returns a message stating that no SV tools have been selected, so no SV results will be returned.  `--svs false` disables SV analysis, despite selecting `--sv_tools`. In both cases, the run continues.
- Several selected methods run independently on the same samples; there is no merge of their
  call sets in this work.
- Software versions of every selected method (caller, indexing, AnnotSV) are included in the
  pipeline's collated software-versions report and MultiQC; unselected methods contribute none.

### Persistence

- Workflow result files only. Each method publishes its raw calls and AnnotSV results under the
  pipeline output directory in method-specific locations, so outputs of different methods for the
  same sample never overwrite each other.
- Output files should go to a folder with the method name inside SVs. This folder contain raw and annotated (annotSV) results of each method:
- `SVs/manta/` contains Manta raw calls and AnnotSV results, `SVs/delly/` contains Delly raw calls and AnnotSV results, and `SVs/gridss/` contains GRIDSS raw calls and AnnotSV results.

## Test data

- **Scenario A (selection, stub):** one WGS sample with a coordinate-sorted, indexed BAM, a
  compatible reference FASTA and FAI, and an AnnotSV annotation directory. Run with `--svs true
  --ngs_type wgs` and different `--sv_tools` values (single method, all three, default, unknown
  name, empty). Stub execution is sufficient to verify which methods run and which fail fast.
- **Scenario B (subworkflow contract):** per renamed subworkflow, the smallest one-sample scenario
  already used by its existing test (Delly, GRIDSS) is reused under the new name; Manta, which has
  no test today, gets an equivalent one-sample scenario (stub at minimum).
- **BAM:** one sample, coordinate-sorted with index, contigs matching the FASTA.
- **FASTA/FAI:** a small reference compatible with the BAM; a BWA index is either supplied or
  derivable from the FASTA for GRIDSS.
- **AnnotSV annotations:** a directory compatible with the reference assembly; existing test
  resources may be reused.

## Acceptance Criteria

- [ ] THE System SHALL expose `--sv_tools` in `nextflow.config` and `nextflow_schema.json` with
  accepted values `manta`, `delly`, `gridss` and default `manta,delly,gridss`.
- [ ] WHILE `--svs true` and `--ngs_type wgs` THE System SHALL run `MANTA_ANNOTSV`,
  `DELLY_ANNOTSV`, and `GRIDSS_ANNOTSV` each only WHEN its method name is listed in `--sv_tools`,
  and SHALL run no process of an unlisted method.
- [ ] WHEN `--sv_tools` lists several methods THE System SHALL run each listed method once per
  sample and publish each method's caller and AnnotSV outputs to distinct method-specific
  locations without overwriting another method's files.
- [ ] IF `--sv_tools` contains a name other than `manta`, `delly`, or `gridss` THEN THE System
  SHALL stop before starting any process, whatever the values of `--svs` and `--ngs_type`, with a
  `nextflow_schema.json` validation error message that names the invalid value and lists the
  accepted values.
- [ ] IF `--sv_tools` resolves to no method while `--svs true` and `--ngs_type wgs` THEN THE System
  SHALL return a warning message stating that at least one SV tool  is required. The run should continue, but no SV results will be returned.
- [ ] WHEN `gridss` is selected THE System SHALL run GRIDSS with the `--index` BWA index, or with
  a BWA index derived from `--fasta` when `--index` is not supplied.
- [ ] WHILE `--ngs_type wes` THE System SHALL run the existing CNV calling path unchanged and
  ignore the selection made by a valid `--sv_tools` value.
- [ ] THE System SHALL name the SV subworkflows `gridss_annotsv`/`GRIDSS_ANNOTSV`,
  `delly_annotsv`/`DELLY_ANNOTSV`, and `manta_annotsv`/`MANTA_ANNOTSV`, and SHALL contain no
  reference to `sv_calling`, `SV_CALLING`, `sv_calling_delly`, or `SV_CALLING_DELLY` in
  workflows, subworkflows, configuration, schema, tests, snapshots, or documentation.
- [ ] THE System SHALL provide passing nf-test coverage consisting of a subworkflow test for each
  of `MANTA_ANNOTSV`, `DELLY_ANNOTSV`, and `GRIDSS_ANNOTSV`, and pipeline-level stub tests that
  verify single selection, multiple selection, the default, the unknown-name failure.

## Dependencies

- Existing subworkflows `gridss_annotsv` (spec `feat-gridss-annotsv-wgs-single-sample`, Verified),
  `sv_calling_delly`, and `sv_calling`.
- nf-core modules already installed: `manta/germline`, `delly/call`, `bcftools/index`,
  `gridss/gridss`, `tabix/tabix`, `annotsv/annotsv`, `annotsv/installannotations`, `bwa/index`.
- Note: `feat-gridss-annotsv-wgs-single-sample` stated that `SV_CALLING` stays unchanged. This
  work renames it (behavior preserved); that earlier specification is not reopened.

## User-confirmed Decisions

- Integrate `gridss_annotsv`, `sv_calling_delly`, and `sv_calling` into the general workflow.
- Name every SV method subworkflow `{method}_annotsv`; `gridss_annotsv` keeps its name and
  `sv_calling_delly` becomes `delly_annotsv`; rename all references.
- Users select the SV tools to run from the pipeline invocation, with a default and validation
  of unknown names.
- No new modules or subworkflows should be added by this specification. Only refactoring, renaming, and integration of existing subworkflows is in scope. No merging of call sets is in scope.
- An exception of the previous instructions is the modification of `gridss_annotsv` or their modules. This subworkflows and their modules can be modified to allow passing
  BWA index to GRIDSS, but no new functionality is in scope. An additional module can also 
be added to ensure this funcionality.

## Unresolved Questions

- None blocking.
