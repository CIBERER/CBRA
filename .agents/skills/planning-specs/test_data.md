# Discovering minimal reference test data

Test data is a fixture for the smallest meaningful execution of a required
behavior. It is not a production-scale experiment or a biological benchmark.
Prefer one sample and a small genomic region over WGS or a complete cohort
unless the behavior under test specifically depends on genome-wide or
multi-sample properties.

Evaluate candidates per minimal test scenario and per input role. A file can
be a valid concrete input even when the same source does not provide every
other input or a precomputed expected output. Preserve useful candidates and
search separately for the remaining input roles.

Require coordination only within compatibility groups whose files are
interpreted together:

- When an index or other companion is required by the selected
implementation interface, it must correspond to its primary file.
- Aligned reads and their reference must agree on the genome build, contig
  names, and contig lengths required by the selected region.
- Intervals and variants must be compatible with the reference when they are
  used together.
- Files joined by sample, event, or another identifier must contain compatible
  identifiers.

Inputs outside the same compatibility group may come from different samples,
experiments, or repositories. For example, aligned reads and their selected reference must be
compatible; any indexes or other companions required by the selected
implementation must also correspond to their primary files.

Do not require a source dataset to provide a full expected-output oracle.
Existence, parseability, schema, channel cardinality, metadata propagation, and
other deterministic properties can be sufficient assertions for a functional
test. Require known biological events or exact annotation values only when the
specified behavior explicitly depends on them.

Search for test data in the following order:

## Local repository

Explore data used for testing modules, subworkflows, and workflows in the current repository. Inspect the metadata, headers, and other properties of candidate files to confirm that they satisfy the required input role and compatibility group. Use the smallest compatible dataset. Do not add test-data files to this repository. Consider test data files defined as links to external repositories, such as Zenodo or nf-core/test-datasets, to be part of the local repository.

## nf-core/test-datasets

When the specification does not already provide a usable fixture, browse the
repository and its relevant branches or directories. Do not choose a dataset
solely because it appears in the paths below. Inspect candidate metadata or
headers as needed, compare only the properties required for its input role and
compatibility group, and use the smallest compatible dataset. Do not add
test-data files to this repository.

The repository test configuration currently uses the `modules` branch as its
base URL:

```text
https://raw.githubusercontent.com/nf-core/test-datasets/modules
```

The following paths are examples already used in this project; they are not an
exhaustive catalogue and do not replace the search:

- `data/genomics/homo_sapiens/illumina/fastq/test.umi_1.fastq.gz`
- `data/genomics/homo_sapiens/illumina/fastq/test.umi_2.fastq.gz`
- `data/genomics/homo_sapiens/illumina/bam/test.rna.paired_end.sorted.bam`
- `data/genomics/homo_sapiens/illumina/bam/test.rna.paired_end.sorted.bam.bai`
- `data/genomics/homo_sapiens/illumina/vcf/NA12878_GIAB.chr22.vcf.gz`
- `data/genomics/homo_sapiens/illumina/vcf/NA12878_GIAB.chr22.vcf.gz.csi`
- `data/genomics/homo_sapiens/genome/genome.fasta`
- `data/genomics/homo_sapiens/genome/genome.fasta.fai`
- `data/genomics/homo_sapiens/genome/genome.bed`
- `data/genomics/homo_sapiens/genome/genome.interval_list`
- `data/genomics/homo_sapiens/genome/vcf/dbsnp_146.hg38.vcf.gz`
- `data/genomics/homo_sapiens/genome/vcf/dbsnp_146.hg38.vcf.gz.tbi`

CNV tests also use the Sarek test data:

```text
https://github.com/nf-core/test-datasets/raw/refs/heads/sarek/testdata/recalbam/1234N.recal.bam
https://github.com/nf-core/test-datasets/raw/refs/heads/sarek/testdata/recalbam/1234N.recal.bai
https://github.com/nf-core/test-datasets/raw/refs/heads/sarek/testdata/recalbam/9876T.recal.bam
https://github.com/nf-core/test-datasets/raw/refs/heads/sarek/testdata/recalbam/9876T.recal.bai
```

## Zenodo dataset used by local modules

After searching nf-core/test-datasets, use only record
[19064653](https://zenodo.org/records/19064653) when a Zenodo input is needed.
Inspect every file attached to the record and select a compatible file or file
set; do not limit the search to the example files below.

- Record [19064653](https://zenodo.org/records/19064653):
  `https://zenodo.org/records/19064653/files/AshkenazimTrio.ped`,
  `https://zenodo.org/records/19064653/files/AshkenazimTrio.gatk.PASS.chr22_1000.vcf.gz`,
  and
  `https://zenodo.org/records/19064653/files/AshkenazimTrio.gatk.PASS.chr22_1000.vcf.gz.tbi`.

For each selected file or compatibility group, document the search result or
rationale, repository, record URL or DOI, exact file URLs, required companion
files, input role, and the compatibility evidence that matters to the test.
State any still-missing input roles separately instead of rejecting compatible
files already found. Prefer small, stable inputs.
