# CIBERER/CBRA: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0dev - [date]

Initial release of CIBERER/CBRA, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- `--sv_tools` parameter to select the WGS structural variant methods to run (`manta`, `delly`, `gridss`; default `manta,delly,gridss`). Unknown names are rejected by parameter validation; an empty selection logs a warning and runs no SV method.
- GRIDSS structural variant calling with AnnotSV annotation for WGS. GRIDSS uses the BWA index from `--index` whatever its file prefix, or the index built once from `--fasta`, and builds its own index for the task only when `--index` does not hold one complete BWA index (`.amb`, `.ann`, `.bwt`, `.pac`, `.sa`); the `gridss/gridss` module carries a local patch that links the index under the FASTA file name. Only those five index files are linked: other files in the `--index` directory (`.alt`, `.img`, `.gridsscache`, `.dict`) are not reused, and a directory with more than one `.amb` makes GRIDSS build its own index.

### `Changed`

- Manta and Delly SV subworkflows renamed to `manta_annotsv` and `delly_annotsv`.
- SV outputs moved from `manta/`, `delly/`, `svs/annotsv_annotation/` and `svs/delly_annotsv_annotation/` to `SVs/manta/`, `SVs/delly/` and `SVs/gridss/` (one directory per method, with raw and AnnotSV files).

### `Fixed`

### `Dependencies`

### `Deprecated`
