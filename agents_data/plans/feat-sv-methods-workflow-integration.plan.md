## Implementation Plan for feat-sv-methods-workflow-integration

- **Specification**: `agents_data/specs/feat-sv-methods-workflow-integration.spec.md` (ID `feat-sv-methods-workflow-integration`)
- **Pipeline root**: `/beegfs/home/cruizarenas/CBRA`
- **Ownership**: This is the sole plan for this specification. Tester owns test files, fixtures, and snapshot review. Coder owns renames, module stub patches, parameter and selection wiring, configuration, and documentation. Cleaner owns refactoring after GREEN only. No new modules or subworkflows are added. Step 6 adds a local patch to the imported `gridss/gridss` module (spec User-confirmed Decisions: "`gridss_annotsv` or their modules ... can be modified to allow passing BWA index to GRIDSS"). Coder owns the patch, its `nf-core modules patch` diff and the `modules.json` registration; tester owns the tests. Do not change the files of the untracked `modules/nf-core/bcftools/stats/`. By user decision of 2026-10-29, which overrides the earlier decision to register both modules, Step 6 registers only `gridss/gridss`; `bcftools/stats` is not registered in `modules.json` and its directory stays untracked, uncommitted and untouched. Do not run Git operations; the builder commits each step.

## Environment and reproducibility

- **Execution environment**: Run every development command on a Slurm compute node, never on `login01`. Check with `hostname -s`. Planning baseline: `nodo05`, Slurm job `583151`. Use this shell prefix for every command in this plan:

  ```bash
  cd /beegfs/home/cruizarenas/CBRA
  source /beegfs/home/cruizarenas/CBRA/.codex-cluster/load-conda-environment.sh
  export NXF_SYNTAX_PARSER=v1
  export NXF_SINGULARITY_CACHEDIR=/beegfs/home/cruizarenas/.nxf-singularity-cache   # persistent, outside the repo; create once
  ```

  - `NXF_SYNTAX_PARSER=v1` is required. `nf-dev` ships Nextflow `26.04.6`. Its strict parser rejects `def check_max(...)` in `nextflow.config` with `Config parsing failed`. Every nf-test run loads `nextflow.config`, so without this variable all tests fail. This was observed during planning.
  - Run every nf-test with `--profile singularity`. `tests/config/nf-test.config` and `nf-test.config` enable no container engine. Stub runs still need containers because `eval` version outputs (Delly, BCFtools, GRIDSS) and `CUSTOM_DUMPSOFTWAREVERSIONS` (no stub block) run real tools. Earlier recorded runs used `-profile singularity`.
  - Use `--ci` for verification runs. `--ci` refuses to create missing snapshots. Create a new or renamed snapshot entry with one run without `--ci` during the GREEN phase, then confirm with `--ci`.
  - Stub tests set `options "-stub"` inside the test file. The GRIDSS subworkflow test is a real functional test. It needs the untracked local AnnotSV directory `agents_data/reference-data` and network access to nf-core test-datasets.
  - nf-test prints warnings about missing `untar` dependencies in unrelated `gatk4` module tests. They are noise.
- **Containers**: No new executable components and no reference commands. All processes use the declared containers of installed modules, unchanged:
  - Manta: `https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f6/f696c93e6209e33ac0d15f1ecfa799bc67329eec07b0569e065ea8b220b53953/data`
  - Delly: `https://depot.galaxyproject.org/singularity/delly:1.7.3--hd6466ae_0`
  - BCFtools index: `https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0b/0b4d52ca9a56d07be3f78a12af654e5116f5112908dba277e6796fd9dfb83fe5/data`
  - AnnotSV and AnnotSV install: `https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/36/363f212881f1b2f5c3395a6c7d1270694392e3a6f886e46e091e83527fed9b6b/data`. Runs with `--writable-tmpfs` from the module's `containerOptions`.
  - GRIDSS: `https://depot.galaxyproject.org/singularity/gridss:2.13.2--h270b39a_0`. Observed SIF SHA-256 `c1d9336c481d0a460a8a320b30e8ed217c8315d53f5e553e9fd1f4ad8676c244`.
  - Tabix: `https://depot.galaxyproject.org/singularity/htslib:1.20--h5efdd21_2`
  - BWA index: `https://depot.galaxyproject.org/singularity/bwa:0.7.18--he4a0461_0`
  - Version dumper and MultiQC: `https://depot.galaxyproject.org/singularity/multiqc:1.19--pyhdfd78af_0`
  - Bind mounts come from `singularity.autoMounts = true` in the `singularity` profile.

## Baseline evidence (planning, 2026-10-28, nodo05)

- `nf-test test subworkflows/local/gridss_annotsv/tests/main.nf.test --profile singularity --ci` with `NXF_SYNTAX_PARSER=v1`: **PASSED** (1/1, 74.7 s).
- `nf-test test subworkflows/local/sv_calling_delly/tests/main.nf.test --profile singularity --ci` with `NXF_SYNTAX_PARSER=v1`: **FAILED**, a pre-existing defect: `MissingFileException: Missing output file(s) versions.yml expected by process SV_CALLING_DELLY:ANNOTSV_ANNOTSV`.
  - The local patch `modules/nf-core/annotsv/annotsv/annotsv-annotsv.diff` replaced the topic output with `path "versions.yml"` but did not update the `stub:` block.
  - `modules/nf-core/manta/germline/manta-germline.diff` has the same defect. Its stub emits no `versions.yml`, so every `-stub` run that includes Manta also fails.
  - `modules/nf-core/annotsv/installannotations` has the same gap, but the tests below avoid it by passing `--annotsv_annotations`.
- `--sv_tools` schema check (planning replan, 2026-10-28, nodo05): a throwaway pipeline in the session scratchpad with nf-schema `2.4.2`, `validateParameters()`, and the `sv_tools` schema entry from the parse and validate contract below. Observed:
  - Accepted: `manta`, `' delly , delly '`, `' , '`, and the empty string from a params file (`{"sv_tools": ""}`), `--sv_tools=` or `--sv_tools ' '`.
  - Rejected before the workflow block: `manta,foo`, `foo,bar`, `Manta`, `manta;delly`. Exit status 1, `completed=0`. stdout has `ERROR ~ Validation of pipeline parameters failed!`. stderr and `.nextflow.log` carry the detail line, with the `errorMessage` appended in parentheses.
  - `--sv_tools ''` on the command line becomes boolean `true`. It is rejected with `* --sv_tools (true): Value is [boolean] but should be [string] (<errorMessage>)`. nf-test passes `params {}` through a params file, so `sv_tools = ''` stays a string in tests.

## Reuse analysis

```yaml
functional_requirements:
  - id: select-sv-methods
    operation: Parse --sv_tools (comma-separated, trimmed, de-duplicated) into the set of SV methods to run for a WGS SV run.
    method: null
    inputs: ["params.sv_tools string", "params.svs", "params.ngs_type"]
    outputs: ["selected method set subset of {manta, delly, gridss}"]
  - id: validate-sv-selection
    operation: Before any process starts and in every invocation, fail on unknown names through nextflow_schema.json validation (naming the invalid value and listing accepted values); under --svs true --ngs_type wgs, warn and continue with no SV results on an empty selection.
    method: nf-schema validateParameters
    inputs: ["params.sv_tools", "params.svs", "params.ngs_type"]
    outputs: ["schema validation error exit or warning log line"]
  - id: call-annotate-manta
    operation: Manta germline calling plus AnnotSV per sample (or joint with --manta_joint).
    method: Manta, AnnotSV
    inputs: ["[meta,bam,bai]", "[meta,fasta]", "[meta,fai]", "manta config", "[meta,annotations]", "candidate genes / false-positive SNV / gene transcripts tuples"]
    outputs: ["diploid and candidate SV VCF.gz (+tbi)", "AnnotSV tsv / unannotated tsv / optional vcf", "versions"]
  - id: call-annotate-delly
    operation: Delly calling, TBI indexing, AnnotSV per sample.
    method: Delly, BCFtools index, AnnotSV
    inputs: ["[meta,bam,bai]", "[meta,fasta]", "[meta,fai]", "[meta,annotations]", "optional AnnotSV tuples"]
    outputs: ["VCF.gz + TBI", "AnnotSV outputs", "versions"]
  - id: call-annotate-gridss
    operation: GRIDSS calling with a BWA index, Tabix, AnnotSV per sample.
    method: GRIDSS, Tabix, AnnotSV
    inputs: ["[meta,bam,bai]", "[meta,fasta]", "[meta,fai]", "[meta,bwa_index_dir]", "[meta,annotations]"]
    outputs: ["VCF.gz + TBI", "AnnotSV vcf/tsv/unannotated tsv", "consolidated versions + mqc"]
  - id: provide-bwa-index
    operation: Use --index when supplied, otherwise derive a BWA index from --fasta once per run.
    method: BWA index
    inputs: ["params.index directory or [meta,fasta]"]
    outputs: ["[meta,bwa_index_dir]", "versions"]
  - id: name-bwa-index-for-gridss
    operation: Present the BWA index to GRIDSS under the names GRIDSS 2.13.2 checks (${reference}.{amb,ann,bwt,pac,sa}, i.e. <fasta.name>.*), whatever the index prefix, so GRIDSS does not run bwa index itself.
    method: symbolic links created in the GRIDSS task (no copies)
    inputs: ["[meta,fasta]", "[meta,bwa_index_dir]"]
    outputs: ["<fasta.name>.{amb,ann,bwt,pac,sa} links in the GRIDSS task dir"]
  - id: publish-sv-results
    operation: Publish each method's raw calls and AnnotSV results under ${outdir}/SVs/{method}/.
    method: publishDir configuration
    inputs: ["process outputs"]
    outputs: ["SVs/manta/, SVs/delly/, SVs/gridss/"]
  - id: report-versions
    operation: Include versions of selected methods only in collated software versions and MultiQC.
    method: CUSTOM_DUMPSOFTWAREVERSIONS, MULTIQC
    inputs: ["versions files"]
    outputs: ["pipeline_info/software_versions.yml", "MultiQC versions section"]
resolutions:
  - covers: [call-annotate-manta]
    resolution: reuse-local
    path: subworkflows/local/sv_calling (renamed to subworkflows/local/manta_annotsv, contract unchanged)
    evidence:
      - "SV_CALLING composes MANTA_GERMLINE (manta/germline @3485512d, local patch) and ANNOTSV_ANNOTSV (annotsv/annotsv @36e47ba3, local patch); take/emit match the requirement. Stubs of both patched modules lack versions.yml (Step 1)."
  - covers: [call-annotate-delly]
    resolution: reuse-local
    path: subworkflows/local/sv_calling_delly (renamed to subworkflows/local/delly_annotsv, contract unchanged)
    evidence:
      - "Composes DELLY_CALL (delly/call @6d467864), BCFTOOLS_INDEX (bcftools/index @feef3743, ext.args --tbi), ANNOTSV_ANNOTSV; existing stub nf-test covers one sample."
  - covers: [call-annotate-gridss]
    resolution: reuse-local
    path: subworkflows/local/gridss_annotsv
    evidence:
      - "Verified spec feat-gridss-annotsv-wgs-single-sample; take includes ch_bwa_index [meta, dir]; functional nf-test passes at planning baseline. GRIDSS_GRIDSS (gridss/gridss) is tracked but absent from modules.json (registered in Step 6, user decision 2026-10-29)."
  - covers: [provide-bwa-index]
    resolution: reuse-local
    path: modules/nf-core/bwa/index (BWA_INDEX already included in workflows/snvs.nf)
    evidence:
      - "Emits [meta, bwa/] directory; nf-core gridss/gridss test feeds BWA_INDEX.out.index directly to GRIDSS_GRIDSS. SNVS already builds ch_index from --index or BWA_INDEX for mapping."
      - "Files are named bwa/<fasta.baseName>.* (genome.*), not the <fasta.name>.* (genome.fasta.*) that GRIDSS checks; RED run 2026-10-29 (Step 6) shows GRIDSS rebuilding the index. Covered by name-bwa-index-for-gridss."
  - covers: [name-bwa-index-for-gridss]
    resolution: reuse-local (local patch)
    path: modules/nf-core/gridss/gridss (nf-core @066da9c5f80fbc42ec51bb720956e5213a4aa657 + gridss-gridss.diff, Step 6)
    evidence:
      - "Unpatched GRIDSS_GRIDSS stages the index with cp -s and keeps the original names, so no supported input or ext option renames them. BWA_INDEX with a scoped ext.prefix = fasta.name cannot cover a user --index, which can have any prefix and never goes through BWA_INDEX, and the user decided BWA_INDEX stays unchanged."
      - "Design decided by the user 2026-10-29: a local patch of the gridss/gridss script (variant A), instead of a new LINK_BWA_INDEX process. The inputs, outputs and stub stay unchanged, so GRIDSS_ANNOTSV and workflows/snvs.nf are untouched. Authority: the spec exception for gridss_annotsv and its modules."
  - covers: [publish-sv-results]
    resolution: reuse-local
    path: conf/modules.config
    evidence:
      - "Scoped withName publishDir/ext.* selectors; no component change needed."
  - covers: [report-versions]
    resolution: reuse-local
    path: modules/nf-core/custom/dumpsoftwareversions, modules/nf-core/multiqc
    evidence:
      - "Pipeline-level dump aggregates by module name (process.split(':')[-1]) and asserts identical versions per module name; all three SV paths use the same AnnotSV container, so this holds."
  - covers: [validate-sv-selection]
    resolution: reuse-local
    path: nextflow_schema.json + nf-schema 2.4.2 validateParameters() (main.nf, guarded by params.validate_params, default true)
    evidence:
      - "validateParameters() runs at main.nf top level before the workflow block. A string pattern plus errorMessage rejects unknown names in every run; verified at planning with nf-schema 2.4.2 (see Baseline evidence)."
  - covers: [select-sv-methods, validate-sv-selection]
    resolution: new-required
    evidence:
      - "Splitting, trimming, de-duplication and the empty-selection warning are pipeline-level Groovy logic (local-wiring in lib/ or workflows/snvs.nf), not an executable component; no module or subworkflow is added."
nfcore:
  checked: false
  modules_sha: null
  note: "Every executable requirement is covered by components already installed locally. name-bwa-index-for-gridss is covered by a user-decided local patch of gridss/gridss (spec exception for gridss_annotsv and its modules), so no remote nf-core search was needed. Installed SHAs come from modules.json. Step 6 registers only gridss/gridss at 066da9c5f80fbc42ec51bb720956e5213a4aa657, as in commit a5d33e7; bcftools/stats is not registered (user decision 2026-10-29)."
```

## Test data and artifacts

| Boundary | Role | Path or materialization command | Format and semantics | Checksum |
| --- | --- | --- | --- | --- |
| Pipeline stub tests (Scenario A) | input samplesheet | `${projectDir}/assets/samplesheet_test.csv` (tracked, existing) | One sample `Sample1`. BAM `test.rna.paired_end.sorted.bam` + `.bai` from nf-core test-datasets `modules`. The FASTQ/VCF columns are present but unused because `--mapping false --variant_calling false --annotation false`. If the tester needs a different BAM-only one-row sheet, it is materialized at test runtime, not committed as data | not applicable (remote, branch-tracked) |
| Pipeline stub tests | FASTA + FAI | `params.modules_testdata_base_path + 'genomics/homo_sapiens/genome/genome.fasta'` and `.fai` | chr22 subset, compatible with the BAM above (same group as the verified GRIDSS fixture) | not applicable |
| Pipeline stub tests | AnnotSV annotations | an existing tracked repository directory passed with `--annotsv_annotations` (stub stand-in; tester picks it) | Stubs never read it. It must exist, so the install module (no stub versions) is not triggered and the tests do not depend on untracked `agents_data/` | not applicable |
| Pipeline stub tests | BWA index (`--index` case) | an existing tracked local directory used as stub stand-in | Proves GRIDSS takes the supplied index and that `BWA_INDEX` does not run. Content is irrelevant under `-stub` | not applicable |
| Pipeline stub tests | derived prerequisite | `BWA_INDEX` stub output (no `--index` case) | `[meta, bwa/]` directory derived from `--fasta` | not applicable |
| `MANTA_ANNOTSV` subworkflow (Scenario B) | BAM + BAI, FASTA + FAI | Same as the Delly test: `genomics/homo_sapiens/illumina/bam/test2.paired_end.recalibrated.sorted.bam(.bai)`, `genomics/homo_sapiens/genome/chr21/sequence/genome.fasta(.fai)` under `params.modules_testdata_base_path` | One sample `[id:'test']`, stub. The Manta config input is the tracked `assets/configManta.ini` or an empty optional value. Annotations `[[id:'annotations'], []]` and empty optional AnnotSV tuples, as in the Delly test | not applicable |
| `DELLY_ANNOTSV` subworkflow | existing fixture | unchanged inputs of `sv_calling_delly/tests/main.nf.test` | Reused under the new name | not applicable |
| `GRIDSS_ANNOTSV` subworkflow | existing fixture | unchanged; pinned test-datasets commit `c16e7bd8bbc7ed534a3652a608ed0b2098037bdd` plus local `agents_data/reference-data` | Real functional test, unchanged | snapshots unchanged |
| `GRIDSS_ANNOTSV` derived index (Step 6) | derived prerequisite | `subworkflows/local/gridss_annotsv/tests/derived_bwa_index.nf.test`: `BWA_INDEX` in a `setup` block on the pinned `genomics/homo_sapiens/genome/genome.fasta`; its `.out.index` is `ch_bwa_index`. Same BAM, FASTA, FAI and AnnotSV inputs as the row above | Real functional run. `[meta, bwa/]` with `genome.{amb,ann,bwt,pac,sa}`, whose prefix (`genome`) differs from the FASTA name (`genome.fasta`) | not applicable (no snapshot) |
| `GRIDSS_GRIDSS` nf-core module (Step 6) | existing fixture | `modules/nf-core/gridss/gridss/tests/main.nf.test`, unchanged. `human - bam - bwa` feeds `BWA_INDEX.out.index` (`bwa/genome.*`, prefix unrelated to `genome.fasta`), so it exercises the patch. `human - bam`, `human - cram` and `human - bam - stub` pass `[[], []]` | Real runs plus one stub. Branch-tracked `modules` test-datasets from `tests/config/nf-test.config` | snapshots unchanged |
| Outputs | output | `${outdir}/SVs/manta/`, `${outdir}/SVs/delly/`, `${outdir}/SVs/gridss/` | Raw calls (VCF.gz plus index) and AnnotSV results per sample, one directory per method; no cross-method overwrite | not applicable |

No reference data generation is needed. There are no new executable components, and the stub and contract assertions are deterministic.

## Component design

| Component | Classification | Contract and evidence | Source |
| --- | --- | --- | --- |
| `ANNOTSV_ANNOTSV` | reuse-local | Unchanged interface. Its local patch's `stub:` must also emit `versions.yml` so stub runs succeed (Step 1). The production `script:` stays the same | `modules/nf-core/annotsv/annotsv` (nf-core `annotsv/annotsv` @`36e47ba3be943154e9bedba0397045684d77654e` + `annotsv-annotsv.diff`) |
| `MANTA_GERMLINE` | reuse-local | Unchanged interface. Its local patch's `stub:` must emit `versions.yml` (Step 1) | `modules/nf-core/manta/germline` (@`3485512d3930df1fcb66b5f92af639179bdfe4be` + `manta-germline.diff`) |
| `GRIDSS_GRIDSS` | reuse-local (local patch, Step 6) | Unchanged interface and `stub:`. The patched `script:` presents a non-empty BWA index under the FASTA file name (see the GRIDSS BWA index patch contract) | `modules/nf-core/gridss/gridss` (nf-core `gridss/gridss` @`066da9c5f80fbc42ec51bb720956e5213a4aa657` + `gridss-gridss.diff`, both registered in Step 6) |
| `DELLY_CALL`, `BCFTOOLS_INDEX`, `TABIX_TABIX`, `BWA_INDEX`, `CUSTOM_DUMPSOFTWAREVERSIONS`, `MULTIQC`, `ANNOTSV_INSTALLANNOTATIONS` | reuse-local | Consumed unchanged | `modules/nf-core/...` |
| `MANTA_ANNOTSV` | local-wiring (rename) | `subworkflows/local/manta_annotsv/`. Same take/emit as current `SV_CALLING`: take `ch_bam, ch_fasta, ch_fai, ch_manta_config, ch_annotsv_annotations, ch_candidate_genes, ch_false_positive_snv, ch_gene_transcripts`; emit `annotated_tsv, annotated_vcf, unannotated_tsv, diploid_sv_vcf, candidate_sv_vcf, versions`. New stub nf-test | from `subworkflows/local/sv_calling` |
| `DELLY_ANNOTSV` | local-wiring (rename) | `subworkflows/local/delly_annotsv/`. Same take/emit as current `SV_CALLING_DELLY`. Tests, snapshot, and manual helper move with it | from `subworkflows/local/sv_calling_delly` |
| `GRIDSS_ANNOTSV` | reuse-local | Unchanged take `ch_bam, ch_fasta, ch_fai, ch_bwa_index, ch_annotsv_annotations`; emit `gridss_vcf, gridss_tbi, annotsv_vcf, annotsv_tsv, annotsv_unannotated_tsv, versions (software_versions.yml), versions_mqc` | `subworkflows/local/gridss_annotsv` |
| `--sv_tools` parse and validate | local-wiring | Declared in `nextflow.config` (default `'manta,delly,gridss'`) and in `nextflow_schema.json` under `svs_options`: type string, default, description listing `manta`, `delly`, `gridss` and the default, plus the exact `pattern` and `errorMessage` from the contract below. Unknown names are rejected by schema validation. Groovy only parses the value and warns on an empty selection | `nextflow.config`, `nextflow_schema.json`, `lib/WorkflowSnvs.groovy` and/or `workflows/snvs.nf` |
| SNVS SV selection wiring | local-wiring | In the existing `params.svs && ngs_type == 'wgs'` branch, invoke exactly the selected subworkflows with the shared `ch_bam_svs`, `ch_fasta`, `ch_fai`, `annotations` and optional AnnotSV channels. GRIDSS keeps its own input set (no optional AnnotSV channels, plus a BWA index). WES branch unchanged | `workflows/snvs.nf` |
| BWA index provisioning | local-wiring | One `ch_index` per run: from `--index` (`[ [id:baseName], dir ]`) or from a single `BWA_INDEX(ch_fasta)` call. Built when `--mapping` is true or GRIDSS is selected in a WGS SV run. `BWA_INDEX` must not be invoked twice. Its versions are collected once | `workflows/snvs.nf` |
| Publishing and SV configuration | local-wiring | `conf/modules.config` selectors renamed to `MANTA_ANNOTSV`/`DELLY_ANNOTSV` and GRIDSS selectors added. See the publishing and versions contract below | `conf/modules.config` |

### Cross-phase contracts

- **`--sv_tools` parse and validate**:
  - **Schema validation (every invocation).** The existing `validateParameters()` call in `main.nf` (nf-schema `2.4.2`) runs before any process starts, whatever `--svs` and `--ngs_type` are. The `sv_tools` property in `nextflow_schema.json` must contain exactly these two keys and values as JSON text:

    ```json
    "pattern": "^\\s*(manta|delly|gridss)?\\s*(,\\s*(manta|delly|gridss)?\\s*)*$",
    "errorMessage": "Invalid SV tool name. Accepted values: manta, delly, gridss (comma-separated)."
    ```

    - The decoded regex is `^\s*(manta|delly|gridss)?\s*(,\s*(manta|delly|gridss)?\s*)*$`. It accepts only `manta`, `delly`, and `gridss` (case-sensitive), separated by commas, with optional whitespace around each name. It also accepts the empty value and empty items such as `' , '`.
    - The schema keeps `"type": "string"` and `"default": "manta,delly,gridss"`.
  - **Expected unknown-name error text.** This is nf-schema's fixed format with the `errorMessage` appended. For `sv_tools = 'manta,foo'`, stderr and `.nextflow.log` contain this line:

    ```text
    * --sv_tools (manta,foo): "manta,foo" does not match regular expression [^\s*(manta|delly|gridss)?\s*(,\s*(manta|delly|gridss)?\s*)*$] (Invalid SV tool name. Accepted values: manta, delly, gridss (comma-separated).)
    ```

    - It comes after `The following invalid input values have been detected:`. stdout carries `ERROR ~ Validation of pipeline parameters failed!`.
    - Tests assert two substrings so they do not depend on the regex text: `* --sv_tools (manta,foo): "manta,foo" does not match regular expression` and `(Invalid SV tool name. Accepted values: manta, delly, gridss (comma-separated).)`.
    - nf-schema prints the whole offending value, so the invalid name `foo` appears inside it.
  - **Groovy parsing (WGS SV runs only).** Split on `,`, trim each name, drop empty items, de-duplicate. No Groovy unknown-name error is required: with schema validation on, unknown names never reach the workflow. With `--validate_params false`, the user has disabled validation, and an unknown name matches no method, so it runs nothing. No defensive check is planned.
  - An empty selection while `--svs true --ngs_type wgs` logs one `log.warn` and the run continues with no SV process. This single text satisfies both spec wordings:
    `No SV tools have been selected (--sv_tools is empty): at least one SV tool is required (accepted values: manta, delly, gridss), so no SV results will be returned.`
  - `--svs false` and `--ngs_type wes` run no `{METHOD}_ANNOTSV` process for any valid `--sv_tools` value, and no warning is logged.
- **Publishing**:
  - Manta raw calls (`*.vcf.gz`, `*.vcf.gz.tbi`) and Manta AnnotSV outputs go to `${params.outdir}/SVs/manta/`.
  - Delly `*.delly.vcf.gz`, its TBI, and Delly AnnotSV outputs go to `${params.outdir}/SVs/delly/`.
  - GRIDSS VCF.gz, TBI, and GRIDSS AnnotSV outputs go to `${params.outdir}/SVs/gridss/`.
  - Existing per-method `ext.args`/`ext.prefix` are kept. GRIDSS in the pipeline needs `-p vcf` for its Tabix and AnnotSV arguments in line with the other methods.
  - `.*CNVS_CALLING:*` selectors stay unchanged.
  - The old locations `manta/`, `delly/`, `svs/annotsv_annotation`, and `svs/delly_annotsv_annotation` are replaced.
- **Versions**:
  - Every selected method's versions reach the pipeline's single `CUSTOM_DUMPSOFTWAREVERSIONS` input: caller, indexing (BCFtools/Tabix, and BWA when derived), and AnnotSV. Unselected methods contribute none.
  - `GRIDSS_ANNOTSV.out.versions` is a consolidated `software_versions.yml`. It is valid YAML keyed by process name and may be mixed into `ch_versions`.
  - `GRIDSS_ANNOTSV.out.versions_mqc` must not be fed to MultiQC, because its section id would duplicate `software_versions`.
  - The bare `withName: CUSTOM_DUMPSOFTWAREVERSIONS` selector also matches `GRIDSS_ANNOTSV:CUSTOM_DUMPSOFTWAREVERSIONS`. The GRIDSS-internal dump must therefore not publish into `pipeline_info/`, where it would overwrite the pipeline-level `software_versions.yml`/`software_versions_mqc.yml`.
- **GRIDSS BWA index patch (Step 6)** (user decision 2026-10-29, variant A):
  - In `modules/nf-core/gridss/gridss/main.nf`, the patch replaces only the guarded `cp -s ${bwa_index}/* .` line (`bwa_index ? ... : ""`). The `input:`, `output:`, `when:` and `stub:` blocks, the container, and the `gridss` command stay unchanged.
  - Non-empty index: the index prefix is the name of the single `*.amb` file in the staged index directory, without `.amb`. The task dir gets symbolic links named `<fasta name>.<suffix>`, where `<fasta name>` is the staged FASTA file name used as `--reference`, for exactly the five suffixes `amb`, `ann`, `bwt`, `pac` and `sa` (user decision 2026-10-29). Each link resolves to `<prefix>.<same suffix>` in the index directory. No file is copied, and no other file of the index directory is linked into the task dir. GRIDSS then finds `${reference}.bwt` and does not run `bwa index`. This holds for the derived index and for a user `--index` with any prefix.
  - Unusable index (user decision 2026-10-29): the non-empty index directory has no top-level `*.amb`, several top-level `*.amb`, or is missing any of `<prefix>.{amb,ann,bwt,pac,sa}`. The patch then creates no link at all, raises no error and prints no warning, and GRIDSS builds its own index as it does today. No partial set of links is created, because GRIDSS checks only `${reference}.bwt`.
  - Validating the index belongs to the workflow, outside GRIDSS and its module, and is out of scope for this plan.
  - Empty index `[meta, []]` (`subworkflows/local/gridss_annotsv/tests/main.nf.test`, and the nf-core module tests other than `human - bam - bwa`): the guard renders the same empty line as today. The script is unchanged, GRIDSS builds its own index as today, and those tests and snapshots stay unchanged.
  - Unchanged: `GRIDSS_ANNOTSV` (take, emit, wiring, `meta.yml`), `BWA_INDEX`, `BWA_MEM`, `MAPPING`, the `workflows/snvs.nf` wiring, `conf/modules.config`, and the version outputs. The GRIDSS staging assertions in `tests/sv_tools.nf.test` (`bwa` and the `conf` stand-in staged by `GRIDSS_GRIDSS`) still hold, because the inputs and the stub are unchanged.
  - `modules.json` (user decision 2026-10-29, which overrides the earlier decision to register both modules), in this order:
    1. Copy only the `gridss/gridss` entry verbatim from `git show a5d33e7:modules.json` (`branch: master`, `git_sha: 066da9c5f80fbc42ec51bb720956e5213a4aa657`, `installed_by: ["modules"]`). nf-core does not compute it. Do this while the module is unmodified, and verify that its local files still match the registered SHA. At planning (2026-10-29, read-only `git`), its files were byte-identical to their `a5d33e7` import. Do not register `bcftools/stats`.
    2. Edit `modules/nf-core/gridss/gridss/main.nf`.
    3. Run `nf-core modules patch gridss/gridss`. It writes `modules/nf-core/gridss/gridss/gridss-gridss.diff` and the `"patch"` key, in the same form as the `annotsv/annotsv` and `manta/germline` entries.
  - Risk kept: `nf-core modules patch` runs nf-core's `check_up_to_date`, which could touch other `modules.json` entries. Review the `modules.json` diff afterwards. Only the `gridss/gridss` registration and its `"patch"` entry are expected. If the patch adds a `bcftools/stats` entry or changes anything else, the coder removes the addition from `modules.json` and the builder reports it to the user. If nf-core offers to move or remove modules, or cannot run without registering `bcftools/stats`, stop and report; do not improvise.
  - Consequences of these decisions (no user choice needed):
    - **`bcftools/stats` not registered** (user decision 2026-10-29): `modules/nf-core/bcftools/stats/` stays untracked and untouched. It is not committed and not added to `modules.json`. The module is unused by the pipeline.
    - **Index already named `<fasta name>.*`** (for example a `--index` directory holding `genome.fasta.bwt`): no special handling. The links live in the task dir and point into the staged index directory, a different directory, so no link can point to itself. Their names do not collide with the staged FASTA (`<fasta name>`) or FAI (`<fasta name>.fai`).
  - No extra tests are added for these decided behaviours, including the unusable index (user decision 2026-10-29).

## Acceptance criteria coverage

| Acceptance criterion | Plan increment | Verification |
| --- | --- | --- |
| AC1 `--sv_tools` in `nextflow.config` and `nextflow_schema.json`, accepted values and default `manta,delly,gridss` | 3, 4 | Schema/config entries reviewed. Pipeline stub test without `--sv_tools` runs Manta, Delly and GRIDSS tasks (Step 4). `validateParameters()` accepts the parameter in every pipeline test |
| AC2 Run each SV subworkflow only when listed; no process of an unlisted method | 3, 4 | Pipeline stub tests for single selections (`manta`, `delly`, `gridss`, and whitespace/duplicate form): the trace contains only processes of the selected subworkflow(s), and only that method's `SVs/{method}/` directory exists |
| AC3 Several methods run once per sample and publish to distinct method locations | 4 | Multiple-selection and default stub tests: one caller task per method for the single sample; `SVs/manta/`, `SVs/delly/`, `SVs/gridss/` each hold that method's raw and AnnotSV files only |
| AC4 Unknown name stops before any process, whatever `--svs`/`--ngs_type`, with a `nextflow_schema.json` validation error naming the value and listing accepted values | 3 | Three pipeline stub tests with an unknown name: `--svs true --ngs_type wgs`, `--svs false`, and `--ngs_type wes`. Each run fails, stderr contains both expected-error substrings from the contract, and the trace has zero tasks. Schema review: the `pattern`/`errorMessage` match the contract |
| AC5 Empty selection: warning that at least one SV tool is required; run continues with no SV results | 3 | Pipeline stub tests with `--sv_tools ''` (and separators only, e.g. `' , '`): success, the warning text appears in the output, no SV process runs, no `SVs/` directory exists |
| AC6 GRIDSS uses `--index` or a BWA index derived from `--fasta` | 4, 6 | Step 4: GRIDSS stub tests with and without `--index`: `BWA_INDEX` runs exactly once without `--index` and never with it, and the GRIDSS task runs in both cases. Step 6, which corrects the 2026-10-29 real-run finding that GRIDSS ignored the derived index: the real `derived_bwa_index.nf.test` run shows no `Running bwa index` in the GRIDSS logs, no `cp -s` in `.command.sh`, and no regular `genome.fasta.{amb,ann,bwt,pac,sa}` file, and each of those names resolves to the `BWA_INDEX` file with the same suffix. The patch derives the prefix from `*.amb`, not from the FASTA name, so a user `--index` with any prefix is covered the same way. The nf-core `human - bam - bwa` module test passes with an unchanged snapshot. The Step 4 stub tests keep showing GRIDSS staging the `BWA_INDEX` output or the `--index` directory |
| AC7 WES runs the CNV path unchanged and ignores the selection of a valid `--sv_tools` | 3, 4, 5 | Diff review: the `ngs_type == 'wes'` branch and `.*CNVS_CALLING:*` selectors are unchanged, and Groovy selection and the empty-selection warning apply only to WGS SV runs. Under WES, only schema validation of unknown names applies (Step 3 `--ngs_type wes` unknown-name test) |
| AC8 Names `{method}_annotsv`/`{METHOD}_ANNOTSV`; no `sv_calling`/`SV_CALLING`/`sv_calling_delly`/`SV_CALLING_DELLY` reference | 2, 5 | `rg -n -i 'sv_calling' --glob '!agents_data/**' --glob '!.nf-test*' --glob '!.git/**' /beegfs/home/cruizarenas/CBRA` returns nothing. Renamed tests pass |
| AC9 Passing nf-test coverage: three subworkflow tests plus pipeline stub tests (single, multiple, default, unknown) | 1, 2, 3, 4, 5, 6 | All four nf-test commands in Step 5 pass with `--ci`. After Step 6, the Step 6 final verification set passes with `--ci`, including the nf-core `gridss/gridss` module tests |

### Step 1: Make patched AnnotSV and Manta stubs emit version evidence
Restore stub runnability so that existing and planned stub tests can pass. Production `script:` blocks and the module interfaces stay unchanged.

- **Depends on:** none
- **Execution:** `coder: direct module-patch`. No preceding tester phase: the RED evidence is the existing Delly stub test, which fails with `Missing output file(s) versions.yml ... ANNOTSV_ANNOTSV` (planning baseline).
- **Approval (recorded 2026-10-28):** the user approved this step as planned, relayed by the coordinator. The approved scope is to add `versions.yml` creation to the `stub:` blocks of `annotsv/annotsv` and `manta/germline` only, and to regenerate both patches with `nf-core modules patch`. Real `script:` blocks stay unchanged. No other module changes in this step. Step 6 patches `gridss/gridss` and registers only `gridss/gridss` in `modules.json`, by user decision of 2026-10-29; `bcftools/stats` is not registered.
- **RED (already recorded):** `nf-test test subworkflows/local/sv_calling_delly/tests/main.nf.test --profile singularity --ci` fails on `versions.yml`.
- **GREEN:** the same command passes, or fails only on a snapshot mismatch limited to version-file md5 values. In that case, run once without `--ci` and rerun with `--ci`. The test is renamed in Step 2, so snapshot refresh may also be deferred to Step 2.

- [x] Update the `stub:` blocks of `modules/nf-core/annotsv/annotsv/main.nf` and `modules/nf-core/manta/germline/main.nf` so each writes a `versions.yml` with the same `"${task.process}": tool: version` shape as its script.
- [x] Regenerate both local patch files with `nf-core modules patch annotsv/annotsv` and `nf-core modules patch manta/germline` from the pipeline root. Confirm `modules.json` still points at the patch files.
- [x] Run the Delly stub test to the GREEN state above and record the result. (2026-10-28, nodo05: AnnotSV versions md5 refreshed once; `--ci` rerun `SUCCESS: Executed 1 tests`; GRIDSS test also PASSED.)

### Step 2: Rename SV subworkflows to `{method}_annotsv` and add the Manta subworkflow test
Mechanical rename with preserved contracts, plus the missing `MANTA_ANNOTSV` stub test. The Delly and GRIDSS tests must stay green.

- **Depends on:** 1
- **Execution:** `tester: production-test` -> `coder: production-implementation` -> `cleaner: production-refactor`
- **tester (RED):**
  - Create `subworkflows/local/manta_annotsv/tests/main.nf.test` (stub, one sample, see Test data) and `tests/nextflow.config` with scoped `MANTA_ANNOTSV:*` `ext.args`, mirroring the Delly test. Workflow `MANTA_ANNOTSV`, tags `subworkflows`, `subworkflows/manta_annotsv`, `manta`, `manta/germline`, `annotsv`, `annotsv/annotsv`.
  - Assert success, every emitted channel's metadata/file shape, and a stub snapshot.
  - Move the Delly tests directory, including `manual/`, to `subworkflows/local/delly_annotsv/tests/`. Change every name, tag, and selector in it to `DELLY_ANNOTSV`/`delly_annotsv`.
  - Expected RED: both tests fail because `../main.nf` / workflow `MANTA_ANNOTSV` / `DELLY_ANNOTSV` do not exist. Command: `nf-test test subworkflows/local/manta_annotsv/tests/main.nf.test subworkflows/local/delly_annotsv/tests/main.nf.test --profile singularity --ci`.
- **coder (GREEN):**
  - Move `sv_calling/{main.nf,meta.yml}` to `manta_annotsv/` and `sv_calling_delly/{main.nf,meta.yml}` to `delly_annotsv/`, renaming the workflows to `MANTA_ANNOTSV`/`DELLY_ANNOTSV`. Leave no old directory.
  - Update `meta.yml` names, the `include`s and calls in `workflows/snvs.nf`, and the `conf/modules.config` selectors (`.*SV_CALLING:...` -> `.*MANTA_ANNOTSV:...`, `.*SV_CALLING_DELLY:...` -> `.*DELLY_ANNOTSV:...`).
  - Keep behavior and output paths unchanged in this step.
  - Create the new snapshot entries with one run without `--ci`. Remove the obsolete `sv_calling_delly ...` snapshot key. Delly snapshot changes must be limited to the test name and version-file md5 values that come from process names. Then verify:
    - `nf-test test subworkflows/local/manta_annotsv/tests/main.nf.test --profile singularity --ci` passes
    - `nf-test test subworkflows/local/delly_annotsv/tests/main.nf.test --profile singularity --ci` passes
    - `nf-test test subworkflows/local/gridss_annotsv/tests/main.nf.test --profile singularity --ci` passes with unchanged snapshots
- **cleaner:** Remove only rename leftovers, such as stale comments or descriptions. Rerun the three commands above with `--ci`; all must pass.

- [x] Tester: add the `MANTA_ANNOTSV` stub test and config, move and rename the Delly tests and manual helper, and record RED.
- [x] Coder: rename both subworkflow directories, workflow names, `meta.yml`, the `workflows/snvs.nf` includes and calls, and the `conf/modules.config` selectors, with contracts unchanged.
- [x] Coder: create and review the snapshots, then bring the Manta, Delly, and GRIDSS subworkflow tests to GREEN with `--ci`.
- [x] Confirm the AC8 `rg` scan finds no matches outside `agents_data/`.
- [x] Cleaner: refactor after GREEN and rerun the three subworkflow tests. (2026-10-28, nodo05: no cleanup needed; `--ci` run of Manta, Delly and GRIDSS tests `SUCCESS: Executed 3 tests`; AC8 scan empty.)

### Step 3: Add `--sv_tools` with validation and selection of Manta and Delly
Declare the parameter, validate it before any process starts, and gate the existing Manta and Delly calls on the selection. GRIDSS is integrated in Step 4. Until then `gridss` is an accepted name that runs nothing.

- **Depends on:** 2
- **Execution:** `tester: production-test` -> `coder: production-implementation` -> `cleaner: production-refactor`
- **tester (RED):**
  - Create the pipeline-level stub test file `tests/sv_tools.nf.test` (`nextflow_pipeline`, `script "../main.nf"`, `options "-stub"`, tag `pipeline`, tag `sv_tools`).
  - Common params: `outdir = "$outputDir"`, the samplesheet/FASTA/FAI/annotations from Test data, `ngs_type = 'wgs'`, `svs = true`, `mapping = false`, `variant_calling = false`, `annotation = false`.
  - Cases:
    - `sv_tools = 'manta'`: only `MANTA_ANNOTSV` processes run, and `SVs/manta/` exists.
    - `sv_tools = ' delly , delly '`: whitespace and duplicate handling; `DELLY_ANNOTSV` processes run once for the sample, and none from Manta or GRIDSS.
    - Unknown name, `sv_tools = 'manta,foo'` (common params): the run fails, stderr contains both expected-error substrings from the parse and validate contract, and the trace has zero tasks (empty or absent trace).
    - Unknown name with `svs = false, sv_tools = 'manta,foo'`: the same failure, error substrings, and zero tasks.
    - Unknown name with `ngs_type = 'wes', sv_tools = 'manta,foo'`: the same failure, error substrings, and zero tasks. Keep the other params schema-valid so the asserted error is the `sv_tools` one.
    - `sv_tools = ''` and `sv_tools = ' , '`: success, the warning text from the contract appears, no SV process runs.
    - `svs = false, sv_tools = 'manta'`: no SV process runs.
  - Process-name and trace assertions only; no md5 snapshots of stub files are required.
  - Expected RED, all from the stub run:
    - The selection cases fail because Manta and Delly always run.
    - The empty cases fail because the warning is missing.
    - The three unknown-name cases fail because `sv_tools` is not in the schema: `validationFailUnrecognisedParams = false` only warns, so the expected-error substrings are absent. In the WGS case, tasks also start.
    - Record the failing assertion for each unknown-name case. A run failing for an unrelated reason is not valid RED evidence.
  - Command: `nf-test test tests/sv_tools.nf.test --profile singularity --ci`.
- **coder (GREEN):**
  - Add `sv_tools = 'manta,delly,gridss'` to `nextflow.config`.
  - Add the `nextflow_schema.json` property under `svs_options`: type string, the default, a description listing `manta`, `delly`, `gridss` and the default, and the exact `pattern` and `errorMessage` from the contract.
  - Implement the Groovy parsing and the empty-selection warning, and gate `MANTA_ANNOTSV`/`DELLY_ANNOTSV` on the selection. Version collection applies only to invoked subworkflows. Leave the WES branch unchanged.
  - Verify:
    - `nf-test test tests/sv_tools.nf.test --profile singularity --ci` passes. This stub run is the GREEN evidence for all three unknown-name cases.
    - `python3 -m json.tool nextflow_schema.json` succeeds
    - `nf-test test subworkflows/local/manta_annotsv/tests/main.nf.test subworkflows/local/delly_annotsv/tests/main.nf.test --profile singularity --ci` passes
- **cleaner:** Simplify the parsing and selection code while keeping the contract. Rerun both commands above.

- [x] Tester: write the pipeline-level stub tests for single selection, whitespace and duplicates, unknown name (WGS SV, `--svs false`, `--ngs_type wes`), empty selection, and `--svs false`, and record RED from the stub run.
- [x] Coder: declare `--sv_tools` in `nextflow.config`, and in `nextflow_schema.json` with the exact `pattern` and `errorMessage`.
- [x] Coder: implement parsing and the empty-selection warning contract, and gate Manta and Delly on the selection. Leave WES unchanged.
- [x] Coder: bring the pipeline and the Manta and Delly subworkflow tests to GREEN with `--ci`.
- [x] Cleaner: refactor after GREEN and rerun the tests. (2026-10-28, nodo05: RED 7/8 failed for missing behavior; GREEN `--ci` `SUCCESS: Executed 10 tests` across sv_tools, Manta and Delly tests. `SVs/manta/` assertion deferred to Step 4 with publishing.)

### Step 4: Integrate GRIDSS with the BWA index, method-specific publishing, and version reporting
Wire `GRIDSS_ANNOTSV` into the WGS SV branch. Provide the BWA index from `--index` or `--fasta`. Publish all three methods under `SVs/{method}/`, and report versions for the selected methods only.

- **Depends on:** 3
- **Execution:** `tester: production-test` -> `coder: production-implementation` -> `cleaner: production-refactor`
- **tester (RED):** Extend `tests/sv_tools.nf.test` with these cases:
  - `sv_tools = 'gridss'` without `--index`: `BWA_INDEX` runs once, `GRIDSS_ANNOTSV` processes run, no Manta or Delly process runs, and `SVs/gridss/` holds the GRIDSS VCF.gz, TBI and AnnotSV TSV.
  - `sv_tools = 'gridss'` with `index` = the stand-in directory: no `BWA_INDEX` task, GRIDSS runs.
  - `sv_tools = 'manta,gridss'` (multiple selection): exactly the processes of those two methods run.
  - The default, with no `sv_tools` param: all three run once for the sample.
  - For the multiple and default cases, assert that each `SVs/{method}/` contains only its own method's raw and AnnotSV files, and that no SV file is published outside `SVs/`. Assert that `pipeline_info/software_versions.yml` lists the selected methods' callers (e.g. `gridss`, `delly`, `manta`) plus `annotsv`, and omits the unselected ones. Assert that the GRIDSS-internal dump does not overwrite it.
  - Update the Step 3 `manta`/`delly` cases to expect `SVs/{method}/` paths.
  - Expected RED: GRIDSS never runs, and the outputs are still in the old locations.
  - Command: `nf-test test tests/sv_tools.nf.test --profile singularity --ci`.
- **coder (GREEN):**
  - Implement the BWA index provisioning contract, so `BWA_INDEX` is called at most once.
  - Invoke `GRIDSS_ANNOTSV` when selected, with `ch_bam_svs`, `ch_fasta`, `ch_fai`, `ch_index`, `annotations`.
  - Mix the selected methods' versions into `ch_versions` according to the versions contract.
  - Update `conf/modules.config` for SV publishing and the GRIDSS selectors, following the publishing contract.
  - Verify every command below:
    - `nf-test test tests/sv_tools.nf.test --profile singularity --ci`
    - `nf-test test subworkflows/local/manta_annotsv/tests/main.nf.test --profile singularity --ci`
    - `nf-test test subworkflows/local/delly_annotsv/tests/main.nf.test --profile singularity --ci`
    - `nf-test test subworkflows/local/gridss_annotsv/tests/main.nf.test --profile singularity --ci`. The subworkflow tests also load `conf/modules.config`, so GRIDSS snapshots must stay unchanged. Explain any snapshot change before accepting it.
- **cleaner:** Remove duplication in the SV branch, such as shared channel preparation, while keeping the contracts. Rerun all four commands.

- [x] Tester: add the GRIDSS, `--index`, multiple, default, publishing, and versions cases, and record RED.
- [x] Coder: provide the BWA index once from `--index` or `--fasta`, and invoke `GRIDSS_ANNOTSV` when selected.
- [x] Coder: publish Manta, Delly and GRIDSS raw and AnnotSV outputs under `SVs/{method}/`, and keep the GRIDSS-internal version dump out of `pipeline_info/`.
- [x] Coder: bring the pipeline and all three subworkflow tests to GREEN with `--ci`.
- [x] Cleaner: refactor after GREEN and rerun all four tests. (2026-10-28, nodo05: RED 6/12 failed for missing behavior; GREEN `--ci` `SUCCESS: Executed 15 tests` across sv_tools and the three subworkflow tests; no snapshot changes. GRIDSS-internal dump publishing disabled by a fully qualified selector, verified by review from run output. No BWA_INDEX `ext.prefix` added; see Step 5 docs.)

### Step 5: Documentation and final verification
Describe `--sv_tools`, the three methods, and their output locations, then run the full verification set.

- **Depends on:** 4
- **Execution:** `coder: direct documentation`. This is a docs-only phase; no RED is required.
- **Verification:** all commands below:
  - `nf-test test subworkflows/local/manta_annotsv/tests/main.nf.test subworkflows/local/delly_annotsv/tests/main.nf.test subworkflows/local/gridss_annotsv/tests/main.nf.test tests/sv_tools.nf.test --profile singularity --ci` passes
  - The AC8 `rg` scan finds no matches
  - `python3 -m json.tool nextflow_schema.json` succeeds

- [x] Update `docs/usage.md` (the SV paragraph under "Pipeline steps"): `--sv_tools` syntax, accepted values, the default, schema rejection of unknown names in every run, empty-selection and `--svs false` behavior (an empty value is passed as `--sv_tools=`, `--sv_tools ' '`, or `sv_tools: ''` in a params file, not as `--sv_tools ''`), the fact that WES ignores a valid selection, and GRIDSS with `--index` or a derived index.
- [x] Update `README.md` (SV analysis bullets): replace "all available SV callers are run together" with selectable Manta, Delly and GRIDSS, and note that AnnotSV annotates every selected method.
- [x] Add an SVs section to `docs/output.md` with `SVs/manta/`, `SVs/delly/`, `SVs/gridss/` and their raw and AnnotSV files.
- [x] Add a `CHANGELOG.md` entry under `v1.0dev` `Added` (the `--sv_tools` selection and GRIDSS integration) and a rename note (`sv_calling` -> `manta_annotsv`, `sv_calling_delly` -> `delly_annotsv`, new output paths).
- [x] Run the final verification set above and record the results. (2026-10-28, nodo05: `--ci` run of the four nf-test files `SUCCESS: Executed 15 tests`; AC8 scan empty; schema JSON valid. Docs record that GRIDSS uses a BWA index only when named after the FASTA file name, otherwise builds its own.)

### Step 6: Make GRIDSS use the supplied or derived BWA index
A real run on 2026-10-29 corrected AC6. `BWA_INDEX` writes `bwa/<fasta.baseName>.*` (`genome.*`), but GRIDSS 2.13.2 checks for `${reference}.bwt` (`genome.fasta.bwt`). When that file is missing, GRIDSS runs `bwa index` itself and ignores the index it was given. A local patch of the imported `gridss/gridss` script presents the index under the FASTA file name, as set out in the GRIDSS BWA index patch contract. `GRIDSS_ANNOTSV`, `BWA_INDEX`, `BWA_MEM`, `MAPPING` and the `workflows/snvs.nf` wiring stay unchanged.

- **Depends on:** 5
- **Execution:** `coder: direct module-registration` -> `tester: production-test` -> `coder: production-implementation` -> `cleaner: production-refactor`, then `coder: direct documentation` after verification. There are no reference-validation or reference-generation phases: the input names and paths fix the expected output (see Test data).
- **Precondition:** none. The user decided the former open points on 2026-10-29 (see the GRIDSS BWA index patch contract).
- **Shell prefix:** run every command of this step after the plan's shell prefix:

  ```bash
  cd /beegfs/home/cruizarenas/CBRA
  source /beegfs/home/cruizarenas/CBRA/.codex-cluster/load-conda-environment.sh
  export NXF_SYNTAX_PARSER=v1
  export NXF_SINGULARITY_CACHEDIR=/beegfs/home/cruizarenas/.nxf-singularity-cache
  ```

- **RED (already recorded, 2026-10-29):** `nf-test test subworkflows/local/gridss_annotsv/tests/derived_bwa_index.nf.test --profile singularity --ci` failed (1 test), with 2 of 6 assertions failing:
  - `Running bwa index` appears in the GRIDSS `.command.log`.
  - GRIDSS creates regular `genome.fasta.*` files, while `genome.*` are symlinks to the `BWA_INDEX` output.
  - Work dir: `.nf-test/tests/f2c21d1f2abdb55e313dfe511dbfcb8/work/5a/eee5c490b975828d04af3abf60913f`.
  - The earlier log under `.nf-test/tests/5888b93af7d71bf88c0b43870df97320/` came from `main.nf.test`, which passes an empty index. It is not evidence for AC6.
- **coder (registration, user decision 2026-10-29):**
  - Before any edit to `modules/nf-core/gridss/gridss/`, register only `gridss/gridss` in `modules.json` as the contract describes (order item 1). Do not register `bcftools/stats`.
  - Leave the module files unchanged.
  - Evidence:
    - `python3 -m json.tool modules.json` succeeds.
    - The new `gridss/gridss` entry equals the one in `git show a5d33e7:modules.json`.
    - No other `modules.json` entry changes.
    - The local `gridss/gridss` files still match the registered SHA `066da9c5f80fbc42ec51bb720956e5213a4aa657`. The coder picks the check.
- **tester (RED):**
  - In `derived_bwa_index.nf.test`, the staging assertions expect variant A:
    - `.command.sh` has no `cp -s` line, which replaces the current `cp -s` regex assertion.
    - `genome.fasta.{amb,ann,bwt,pac,sa}` in the GRIDSS task dir are symlinks that resolve to the `BWA_INDEX` `bwa/genome.*` file with the same suffix. This replaces the current `genome.*` symlink assertion.
    - Keep the no-rebuild assertions (no `Running bwa index`, no regular `genome.fasta.{amb,ann,bwt,pac,sa}` file) and the light output checks.
  - Add no other test case, including none for an unusable index (user decision 2026-10-29).
  - `tests/sv_tools.nf.test` and the nf-core `gridss/gridss` module tests stay unchanged. Under variant A, their staging and snapshot expectations still hold. They are regression guards, not RED.
  - Expected RED:
    - The derived test fails on the `cp -s`, link-name and no-rebuild assertions.
    - A failure for any other reason is not valid RED.
  - Commands:
    - `nf-test test subworkflows/local/gridss_annotsv/tests/derived_bwa_index.nf.test --profile singularity --ci`
    - `nf-test test tests/sv_tools.nf.test --profile singularity --ci`
    - `nf-test test modules/nf-core/gridss/gridss/tests/main.nf.test --profile singularity --ci`
- **coder (GREEN):**
  - In `modules/nf-core/gridss/gridss/main.nf`, replace only the guarded `cp -s` line. Follow the GRIDSS BWA index patch contract.
  - Then run `nf-core modules patch gridss/gridss` from the pipeline root. It writes `modules/nf-core/gridss/gridss/gridss-gridss.diff`, and `modules.json` gains the `"patch"` key.
  - Review the `modules.json` diff. Only the `gridss/gridss` registration and its `"patch"` entry may differ from `HEAD`. If the patch adds a `bcftools/stats` entry or changes anything else, remove the addition from `modules.json`; the builder reports it to the user. If nf-core offers to move or remove modules, or cannot run without registering `bcftools/stats`, stop and report; do not improvise.
  - The diff touches only `main.nf`, outside the `stub:` block.
  - Do not change `GRIDSS_ANNOTSV`, `BWA_INDEX`, `BWA_MEM`, `MAPPING`, `workflows/snvs.nf`, `conf/modules.config`, or any file under `modules/nf-core/bcftools/stats/`.
  - **GREEN:**
    - The three commands above pass with `--ci`.
    - In the real derived run, the GRIDSS task logs have no `Running bwa index` and the task dir has no regular `genome.fasta.{amb,ann,bwt,pac,sa}` file. Each of those names resolves to the `BWA_INDEX` output with the same suffix.
    - The final verification set below passes.
  - **Snapshots that must stay unchanged:**
    - `subworkflows/local/gridss_annotsv/tests/main.nf.test.snap`
    - `subworkflows/local/manta_annotsv/tests/main.nf.test.snap`
    - `subworkflows/local/delly_annotsv/tests/main.nf.test.snap`
    - `modules/nf-core/gridss/gridss/tests/main.nf.test.snap`

    No new snapshot is expected. Explain any snapshot change, and do not accept it without the user.
- **cleaner:**
  - Refactor only the patched block, keeping the contract.
  - Regenerate the diff with `nf-core modules patch gridss/gridss` if the block changes.
  - Rerun the final verification set.
- **Final verification set** (`--ci`):
  - `nf-test test subworkflows/local/manta_annotsv/tests/main.nf.test subworkflows/local/delly_annotsv/tests/main.nf.test subworkflows/local/gridss_annotsv/tests/main.nf.test subworkflows/local/gridss_annotsv/tests/derived_bwa_index.nf.test modules/nf-core/gridss/gridss/tests/main.nf.test tests/sv_tools.nf.test --profile singularity --ci` passes
  - The AC8 `rg` scan finds no matches
  - `python3 -m json.tool modules.json` succeeds, and the `gridss/gridss` entry points at `gridss-gridss.diff`
- **Commit:** the builder commits.
  - The new test `subworkflows/local/gridss_annotsv/tests/derived_bwa_index.nf.test` (untracked today) is committed together with the fix: patched `main.nf`, `gridss-gridss.diff`, the `modules.json` `patch` key, and any updated tests. It is never committed on its own.
  - The registration (the `gridss/gridss` `modules.json` entry only) may be a separate earlier commit, because it changes no behavior. `modules/nf-core/bcftools/stats/` is never committed and stays untracked (user decision 2026-10-29).

- [x] Coder: register only `gridss/gridss` in `modules.json` with unmodified module files, copied verbatim from `a5d33e7`; do not register `bcftools/stats`. (2026-10-29, nodo01: entry copied from `a5d33e7`, SHA `066da9c5f80fbc42ec51bb720956e5213a4aa657`; before the edit the module files were byte-identical to upstream at that SHA.)
- [x] Tester: update the `derived_bwa_index.nf.test` assertions for variant A and record RED. (2026-10-29, nodo01: derived test 1 failed, 4 of 6 assertions: `cp -s`, link names, `Running bwa index`, regular `genome.fasta.*`; `sv_tools` 12/12 and `gridss/gridss` module tests 4/4 passed.)
- [x] Coder: patch the guarded `cp -s` line in `gridss/gridss` `main.nf` following the contract, run `nf-core modules patch gridss/gridss`, and review the `modules.json` diff. (2026-10-29, nodo01: variant A with relative links, user-confirmed. nf-core/tools 4.2.1 wrote `gridss-gridss.diff` and the `patch` key; a first 4.1.0 attempt failed on a dirty local nf-core cache, reset by the user. `check_up_to_date` (patch and lint) re-added a `bcftools/stats` entry, removed by user decision; the final `modules.json` diff is only the `gridss/gridss` entry plus `patch`. `nf-core modules lint gridss/gridss` (4.2.1): 58 passed, 1 warning `module_version: New version available`, 0 failed.)
- [x] Coder: bring the three Step 6 tests to GREEN, then pass the final verification set with the listed snapshots unchanged. (2026-10-29, nodo01: final set `--ci` `SUCCESS: Executed 20 tests`; AC8 scan empty; `modules.json` valid JSON; the four snapshots unchanged. Real derived run: no `Running bwa index`; `genome.fasta.{amb,ann,bwt,pac,sa}` link to `BWA_INDEX` `bwa/genome.*`.)
- [x] Cleaner: refactor after GREEN and rerun the final verification set. (2026-10-29, nodo01: no change.)
- [x] Coder, after verification: update `docs/usage.md` (the GRIDSS bullet in the SV paragraph) and `CHANGELOG.md` (the `v1.0dev` GRIDSS entry). Both should say that GRIDSS uses the `--index` index whatever its prefix, and the index derived from `--fasta`, without rebuilding it per task. Replace the "only when named after the FASTA file name" wording. (2026-10-29, nodo01: both updated; one `README.md` sentence with the same now-false claim was corrected too.)

## Risks and spec notes (not resolved by changing the spec)

- **Warning wording:** the single warning text in the contract contains both "No SV tools have been selected ... no SV results will be returned" (Model section) and "at least one SV tool is required" (AC5).
- **Output relocation:** the existing `manta/`, `delly/`, `svs/annotsv_annotation/`, and `svs/delly_annotsv_annotation/` move to `SVs/{method}/`. Note the capital `SVs`, as the spec requires. Users of the old paths are affected, so the CHANGELOG must say so.
- **GRIDSS index naming:** `BWA_INDEX` writes `bwa/<fasta.baseName>.*`. GRIDSS 2.13.2 checks for `${reference}.bwt` (`<fasta.name>.bwt`) and otherwise runs `bwa index` itself. A real run on 2026-10-29 (`derived_bwa_index.nf.test`) confirmed that the derived index was ignored, so AC6 was not met. A user `--index` with any other prefix is ignored in the same way. Step 6 resolves this with the user-decided local patch of `gridss/gridss` (variant A). `GRIDSS_ANNOTSV`, `BWA_INDEX` (no `ext.prefix`), `BWA_MEM` (finds the index by `*.amb`) and `workflows/snvs.nf` stay unchanged. `subworkflows/nf-core/fastq_align_bwa` is unused. Remaining risks:
  - `nf-core modules patch` runs `check_up_to_date`, which could touch other `modules.json` entries. The coder reviews the `modules.json` diff: an added `bcftools/stats` entry or other change is removed and reported to the user by the builder; an nf-core offer to move or remove modules, or a need to register `bcftools/stats`, means stop and report.
  - Observed in Step 6: while the untracked `modules/nf-core/bcftools/stats/` exists, future nf-core commands (for example `modules patch` or `modules lint`) will re-add `bcftools/stats` to `modules.json`. Review the `modules.json` diff after any nf-core command.
  - Any future `nf-core modules update gridss/gridss` must reapply `gridss-gridss.diff`, as for the AnnotSV and Manta patches.
  - `--refdict` (`params.refdict`) is not passed to GRIDSS. Wiring it would change the `GRIDSS_GRIDSS` inputs, so it is out of scope.
- **Version dumper:** the pipeline-level dump aggregates by module name and fails if two same-named modules report different versions. All AnnotSV and Tabix uses share one container, so this holds today. Do not feed the GRIDSS `versions_mqc` to MultiQC.
- **Pre-existing, out of scope:** `ch_manta_config` is `Channel.empty()` when `--manta_config` is unset, which silently skips Manta; the default is a URL. `annotsv/installannotations` has no `versions.yml` in its stub. Report these; do not fix them here. Exception, user decision 2026-10-29: the missing `modules.json` entry for `gridss/gridss` (tracked) is fixed in Step 6. `bcftools/stats` (untracked, unused) stays unregistered, untracked and untouched; this overrides the earlier decision to register it.
- `--sv_tools` passed without a value, or as `--sv_tools ''` on the command line, becomes boolean `true` in Nextflow. The string schema rejects it with `Value is [boolean] but should be [string]` plus the `errorMessage` (observed at planning). This is why the docs must give working empty forms. No test is required.
- `--validate_params false` skips schema validation, so unknown names are then not rejected. They match no method and run nothing. This is accepted user opt-out, not a defect.

## Blockers

- None for Steps 1-5. The Step 1 stub-only patch of `annotsv/annotsv` and `manta/germline` (add `versions.yml` to the stubs, regenerate the patches with `nf-core modules patch`, real scripts unchanged) was approved by the user on 2026-10-28, relayed by the coordinator. It is no longer a blocker.
- Not a blocker: the GRIDSS subworkflow test depends on the untracked local `agents_data/reference-data`, which exists on this cluster.
- None for Step 6. The user decided the former open points on 2026-10-29; no open point remains. Not a blocker: the real `derived_bwa_index.nf.test` depends on `agents_data/reference-data` and on network access to nf-core test-datasets.
