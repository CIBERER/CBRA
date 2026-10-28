# CIBERER/CBRA: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.0dev - [date]

Initial release of CIBERER/CBRA, created with the [nf-core](https://nf-co.re/) template.

### `Added`

- `--sv_tools` parameter to select the WGS structural variant methods to run (`manta`, `delly`, `gridss`; default `manta,delly,gridss`). Unknown names are rejected by parameter validation; an empty selection logs a warning and runs no SV method.
- GRIDSS structural variant calling with AnnotSV annotation for WGS. GRIDSS uses the BWA index from `--index` only when its files are named after the FASTA file name (`<fasta>.bwt`, ...); otherwise it builds its own BWA index in each task.

### `Changed`

- Manta and Delly SV subworkflows renamed to `manta_annotsv` and `delly_annotsv`.
- SV outputs moved from `manta/`, `delly/`, `svs/annotsv_annotation/` and `svs/delly_annotsv_annotation/` to `SVs/manta/`, `SVs/delly/` and `SVs/gridss/` (one directory per method, with raw and AnnotSV files).

### `Fixed`

### `Dependencies`

### `Deprecated`
