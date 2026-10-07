## Implementation Plan for feat-gridss-annotsv-wgs-single-sample

- **Specification**: `agents_data/specs/feat-gridss-annotsv-wgs-single-sample.spec.md`
- **Pipeline root**: `/beegfs/home/cruizarenas/CBRA`
- **Ownership**: This is the sole plan for this specification. Tester owns fixtures, reference validation, production tests, and snapshots; coder owns imports and subworkflow wiring; cleaner owns post-GREEN refactoring only. Validate this subworkflow in isolation with its local test configuration. Pipeline workflow integration and global configuration are later work. `SV_CALLING` and its Manta contract are out of scope and must remain unchanged.

## Environment and reproducibility

- **Execution environment**: Use the selected Slurm allocation via `.codex-cluster/codex-srun` on `login01`; it loads `.codex-cluster/load-conda-environment.sh` and `nf-dev`. Run Nextflow DSL2 tests with `nf-test test <test-path> --ci` and repository configuration.
- **Containers**:
  - GRIDSS: `https://depot.galaxyproject.org/singularity/gridss:2.13.2--h270b39a_0`; observed SIF SHA-256 `c1d9336c481d0a460a8a320b30e8ed217c8315d53f5e553e9fd1f4ad8676c244`; use `apptainer exec --bind "$PWD:$PWD" --pwd "$PWD" <image> gridss ...`.
  - AnnotSV: `docker://community.wave.seqera.io/library/annotsv:3.5.3--71a461cb86d570b7`; observed SIF SHA-256 `6727ccdf9c97716965592e54c5a7dfb3cede5c13f05367137ab7cf9359175069`; use `--writable-tmpfs` and the same bind.
  - BCFtools stats: `https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0b/0b4d52ca9a56d07be3f78a12af654e5116f5112908dba277e6796fd9dfb83fe5/data`.
  - Reused Tabix: `https://depot.galaxyproject.org/singularity/htslib:1.20--h5efdd21_2`; reused version dumper: `docker://quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0`.

## Reuse analysis

```yaml
functional_requirements:
  - id: call-gridss-single-sample
    operation: Call SVs from one coordinate-sorted paired-end WGS BAM with its metadata.
    method: GRIDSS
    inputs: ["[meta,bam,bai]", "[reference_meta,fasta]", "[reference_meta,fai]", "optional BWA index"]
    outputs: ["[meta,gridss.vcf.gz]", "GRIDSS version evidence"]
  - id: index-gridss-vcf
    operation: Index GRIDSS VCF for consumers.
    method: tabix
    inputs: ["[meta,gridss.vcf.gz]"]
    outputs: ["[meta,gridss.vcf.gz.tbi]"]
  - id: audit-gridss-calls
    operation: Produce a per-sample call-set audit/metrics artifact.
    method: bcftools stats
    inputs: ["[meta,gridss.vcf.gz,tbi]"]
    outputs: ["[meta,vcf-stats.txt]"]
  - id: annotate-gridss-vcf
    operation: Annotate GRIDSS calls with configured GRCh38 AnnotSV content.
    method: AnnotSV
    inputs: ["[meta,vcf,tbi,empty-small-variants]", "[annotations_meta,annotations-directory]"]
    outputs: ["[meta,annotated.vcf]", "[meta,annotated.tsv]", "[meta,unannotated.tsv]"]
  - id: aggregate-versions
    operation: Consolidate software version evidence.
    method: CUSTOM_DUMPSOFTWAREVERSIONS
    inputs: ["collected versions.yml files"]
    outputs: ["software_versions.yml", "software_versions_mqc.yml"]
resolutions:
  - covers: [call-gridss-single-sample]
    resolution: import-nf-core
    component_type: module
    component: gridss/gridss
    evidence:
      - "At SHA 066da9c5f80fbc42ec51bb720956e5213a4aa657, inspected source accepts metadata+BAM, FASTA, FAI, optional BWA-index directory, and emits metadata-associated VCF.gz/version evidence. Its nf-test covers paired BAM with and without BWA index."
  - covers: [index-gridss-vcf]
    resolution: reuse-local
    path: modules/nf-core/tabix/tabix/main.nf
    evidence:
      - "TABIX_TABIX accepts metadata-associated VCF.gz, emits TBI, exposes task.ext.args, and has a VCF-TBI test."
  - covers: [audit-gridss-calls]
    resolution: import-nf-core
    component_type: module
    component: bcftools/stats
    evidence:
      - "At the pinned SHA it accepts VCF/TBI plus empty optional region/target/sample/exon/FASTA tuples and emits metadata-associated stats/version evidence."
  - covers: [annotate-gridss-vcf]
    resolution: reuse-local
    path: modules/nf-core/annotsv/annotsv/main.nf
    evidence:
      - "ANNOTSV_ANNOTSV declares metadata-associated tsv, optional unannotated_tsv, and optional vcf outputs; scoped task.ext.args = '-vcf 1' enables the VCF output. The independent CLI oracle contains sample1.annotsv.unannotated.tsv."
  - covers: [aggregate-versions]
    resolution: reuse-local
    path: modules/nf-core/custom/dumpsoftwareversions/main.nf
    evidence:
      - "It consumes collected version YAML and emits both consolidated audit files unchanged."
  - covers: [call-gridss-single-sample, index-gridss-vcf, audit-gridss-calls, annotate-gridss-vcf, aggregate-versions]
    resolution: composition
    components:
      - { resolution: import-nf-core, component: gridss/gridss }
      - { resolution: reuse-local, component: modules/nf-core/tabix/tabix/main.nf }
      - { resolution: import-nf-core, component: bcftools/stats }
      - { resolution: reuse-local, component: modules/nf-core/annotsv/annotsv/main.nf }
      - { resolution: reuse-local, component: modules/nf-core/custom/dumpsoftwareversions/main.nf }
    evidence:
      - "Only independent local wiring is new; it composes existing interfaces without changing SV_CALLING."
nfcore:
  checked: true
  modules_sha: 066da9c5f80fbc42ec51bb720956e5213a4aa657
  searches:
    - "search_nfcore.py gridss returned gridss/gridss and lower-level GRIDSS candidates; source and tests were inspected."
    - "search_nfcore.py 'bcftools stats' was run; compatible bcftools/stats source and tests at the pinned SHA were inspected."
```

## Test data and artifacts

| Boundary | Role | Path or materialization command | Format and semantics | Checksum |
| --- | --- | --- | --- | --- |
| Workflow input | accepted BAM + BAI | `agents_data/reference-data/feat-gridss-tsv/sample1.bam` and `.bam.bai` | User-approved paired-end GRIDSS fixture, coordinate sorted on `chr22`; one sample (`test`), matching the selected minimal reference and producing GRIDSS calls | BAM `65663815b591bf76118335606fc418a5e9434cb604ca12a6611c9b5f949d067c`; BAI `aa28640323adbaf35c2ccfdf4a24367a07bdb8010e932ae5337fbf16fef40359` |
| Workflow input | accepted FASTA + FAI | `agents_data/reference-data/feat-gridss-tsv/genome.fasta` and `.fai` | Minimal `chr22` reference compatible with the accepted BAM; reference-validation must retain the compatibility evidence with selected AnnotSV GRCh38 assets | FASTA `48d0bbb875d37e529640d43f2751ec2a25e0ba1144f1994773e9c643d3cf9d05`; FAI `aa684078e5bc8ec77af619fb6c3e6e9e51e143d997d84ab213b47eff844757d1` |
| Workflow input | AnnotSV annotations | `agents_data/reference-data/Annotations_Human` | Existing GRCh38 directory passed as a directory, not copied | directory; validate selected layout/version |
| Derived prerequisite | BWA index | `.../derived/bwa-index/`, generated only if selected interface needs it | Must correspond exactly to fixture FASTA; not a product input | pending reference generation |
| Independent GRIDSS oracle | VCF + TBI | `.../reference/gridss/`, direct container CLI then Tabix | Non-empty valid VCF/TBI with at least one record | pending reference generation |
| Independent AnnotSV oracle | VCF + annotated TSV + unannotated TSV | `.../reference/annotsv/`, direct `AnnotSV -vcf 1` | All three describe the GRIDSS call set; validate unannotated TSV schema and source IDs against GRIDSS | pending validation of unannotated TSV |
| Independent audit oracle | stats + versions | `.../reference/audit/`, direct BCFtools and version collation | Non-empty stats and GRIDSS/Tabix/BCFtools/AnnotSV version evidence | pending reference generation |
| Committed helpers | materialize/generate/validate | `agents_data/plans/feat-gridss-annotsv-wgs-single-sample.reference/{materialize,generate,validate}.sh` | Record URLs, commands, images/SIFs, binds, selected annotation evidence, and all SHA-256 values; materialize from an empty workspace | not applicable |

`agents_data/reference-data/feat-gridss-tsv/` is the user-approved fixture source for this plan. Its manifest and BAM header record the original RNA-derived provenance; the user has explicitly accepted it for this focused GRIDSS functional test. Preserve that provenance and assert technical compatibility rather than treating its origin label as a blocker.

## Component design

| Component | Classification | Contract and evidence | Source |
| --- | --- | --- | --- |
| `GRIDSS_GRIDSS` | import-nf-core | `[meta,bam]`, FASTA/FAI and optional BWA index to `[meta,vcf.gz]` and versions; unchanged import | `gridss/gridss`, SHA `066da9c5f80fbc42ec51bb720956e5213a4aa657` |
| `TABIX_TABIX` | reuse-local | GRIDSS VCF to metadata-associated TBI with scoped `-p vcf` | `modules/nf-core/tabix/tabix/main.nf` |
| `BCFTOOLS_STATS` | import-nf-core | GRIDSS VCF/TBI and empty optional tuples to metadata-associated stats/versions; unchanged import | `bcftools/stats`, same SHA |
| `ANNOTSV_ANNOTSV` | reuse-local | VCF/TBI plus configured directory to metadata-associated VCF, annotated TSV, and optional unannotated TSV with scoped `-vcf 1`; `out.unannotated_tsv` exists without modifying the module | `modules/nf-core/annotsv/annotsv/main.nf` |
| `CUSTOM_DUMPSOFTWAREVERSIONS` | reuse-local | Collected versions files to consolidated audit artifacts | `modules/nf-core/custom/dumpsoftwareversions/main.nf` |
| `GRIDSS_ANNOTSV` | local-wiring | New `subworkflows/local/gridss_annotsv/`; input `[meta,bam,bai]`, FASTA/FAI, optional BWA-index, annotations directory; output GRIDSS VCF/TBI, stats, AnnotSV VCF, annotated TSV, unannotated TSV, and versions, preserving `meta` on per-sample outputs | new local wiring |

## Acceptance criteria coverage

| Acceptance criterion | Plan increment | Verification |
| --- | --- | --- |
| One paired-end WGS sample is one GRIDSS unit | 4 | One `[meta,bam,bai]` fixture gives one metadata-associated result set |
| Configured GRCh38 FASTA is used | 2, 4 | BAM/FASTA compatibility and normalized VCF-header/contig oracle assertions |
| Configured AnnotSV directory annotates calls | 2, 4 | Validated GRCh38 directory and VCF/TSV call-set ID assertions |
| GRIDSS VCF retains metadata | 4 | Channel-shape assertion and VCF summary snapshot |
| Software versions emit | 1, 4, 5 | Consolidated named-tool versions from the completed run; stats remain an existing audit output |
| AnnotSV VCF, annotated TSV, and unannotated TSV retain metadata | 2, 3, 4, 5 | Independent three-file oracle, one metadata-associated tuple per output, and normalized source-ID assertions for annotated and unannotated variants |
| Manta SV_CALLING remains unchanged | 5, 6 | Scope review and existing nf-test if present |

### Step 1: Import pinned reusable modules

- **Depends on:** none
- **Execution:** `coder: direct import-nf-core`

- [x] Run `nf-core modules install gridss/gridss --sha 066da9c5f80fbc42ec51bb720956e5213a4aa657` from the pipeline root.
- [x] Run `nf-core modules install bcftools/stats --sha 066da9c5f80fbc42ec51bb720956e5213a4aa657` from the pipeline root.
- [x] Validate each import's files/provenance and report every changed file; stop if either interface differs from inspected evidence.

### Step 2: Validate references before generating outputs

- **Depends on:** 1
- **Execution:** `tester: reference-validation`

- [x] Validate the user-approved `feat-gridss-tsv` BAM/BAI and FASTA/FAI against the recorded checksums, sample/header/contig compatibility, and selected AnnotSV GRCh38 assets.
- [x] Write `validate.sh` assertions for sorting/pairing, compatible annotations, VCF record/TBI validity, VCF/TSV call-set agreement, metadata, and stats/version content.
- [x] Establish RED only for missing reference outputs/prerequisites; unavailable fixture/container is an environment failure, not valid RED.
- [x] Extend `validate.sh` to check the independent `sample1.annotsv.unannotated.tsv`: schema, source IDs, sample identity, and non-empty variant rows; reject inconsistent reference data.

### Step 3: Generate and validate independent reference data

- **Depends on:** 2
- **Execution:** `coder: reference-generation`

- [x] Materialize or link the approved `feat-gridss-tsv` fixture and generate its BWA index in the specification-specific untracked data tree.
- [x] Run direct GRIDSS, Tabix, AnnotSV (`-vcf 1`), and BCFtools commands in pinned containers, never the production subworkflow.
- [x] Record command/container/bind/provenance/checksum data in helpers and make `validate.sh` GREEN.
- [x] Confirm the existing unannotated TSV came from the pinned direct AnnotSV command, record its SHA-256 and provenance in reference artifacts, and bring expanded reference validation to GREEN; regenerate only if needed.

### Step 4: Establish and update the isolated nf-test contract

- **Depends on:** 3
- **Execution:** `tester: production-test`

- [x] Establish the isolated workflow test and record its original RED before `GRIDSS_ANNOTSV` exists; scope `-vcf 1` and `-p vcf` to the AnnotSV and Tabix aliases of this subworkflow.
- [x] Exercise the real `../main.nf` in one functional nf-test with the reproducible BAM/BAI and FASTA/FAI source inputs and the local AnnotSV annotations. Use no script override, substitute workflow, generated reference outputs, or external comparison scripts at test runtime.
- [x] Check all seven current outputs using `assertAll` and reviewable snapshots: metadata-associated GRIDSS VCF/TBI and AnnotSV VCF, annotated TSV, unannotated diagnostics TSV, plus both software-version files. Exclude BCFtools stats and version; the user withdrew the stub test. The functional test passed 1/1 before the configuration adjustment.
- [x] Align `tests/nextflow.config` with `testing_subworkflows.md` so it supplies only scoped `ext.args`; preserve the execution settings and repository-root resolution needed by the isolated test in an appropriate location outside that file, without changing global configuration or `SV_CALLING`.
- [x] Re-run `nf-test test subworkflows/local/gridss_annotsv/tests/main.nf.test --ci` after the configuration adjustment, confirm the single functional test and both snapshots pass with only the permitted inputs available, and record the result: 1/1 passed in 77.863 s on `nodo11` in Slurm job `531555`; `normalized-oracle` and `output-contract` snapshots were unchanged.

### Step 5: Implement the independent composition

- **Depends on:** 4
- **Execution:** `coder: production-implementation`

- [x] Add `GRIDSS_ANNOTSV` and metadata at the declared path; do not include `SV_CALLING`.
- [x] Wire imported GRIDSS to reused Tabix, imported BCFtools stats, reused AnnotSV, and collected reused version dumper while preserving original sample metadata.
- [x] Expose `ANNOTSV_ANNOTSV.out.unannotated_tsv` as `annotsv_unannotated_tsv` with original sample metadata; keep `-vcf 1` and `-p vcf` scoped in the isolated subworkflow's local test configuration.
- [x] Run the original frozen workflow test to GREEN without changing its oracle; run the existing `SV_CALLING` test if present.
- [x] Bring the expanded workflow test to GREEN in isolation, including three AnnotSV outputs, their metadata, and unchanged Manta behavior.

### Step 6: Refactor only after GREEN

- **Depends on:** 5
- **Execution:** `cleaner: production-refactor`

- [x] Remove only duplication or unclear wiring while preserving public contract and snapshots.
- [x] Re-run new and existing SV_CALLING tests; confirm no changes under `subworkflows/local/sv_calling/` or imported modules.

## Blockers

- None at planning. The user-approved `feat-gridss-tsv` BAM/BAI and FASTA/FAI provide the reference-generation input; Step 2 still validates their checksums and technical compatibility with selected `Annotations_Human` GRCh38 assets.
