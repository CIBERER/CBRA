# Manual Delly Calling Smoke Test

This helper runs only the `SV_CALLING_DELLY` subworkflow with Delly's example
short-read data. It is intended for manual validation on machines with
Nextflow, Singularity, and an AnnotSV annotations directory available.

Run from the repository root (change ANNOTDIR!):

To download annotation from AnnotSV:

```bash
cd /path/to/install/
git clone https://github.com/lgmgeo/AnnotSV.git

cd /path/to/install/AnnotSV
make PREFIX=. install
make PREFIX=. install-human-annotation
```


```bash
ANNOTDIR='../AnnotSV/share/AnnotSV'
nextflow run subworkflows/local/sv_calling_delly/tests/manual/run_real.nf \
    -c nextflow.config \
    -c subworkflows/local/sv_calling_delly/tests/manual/run_real.config \
    -profile singularity \
    --annotsv_annotations $ANNOTDIR
```

Outputs are written to `manual_outputs/delly_calling_real/`, which is ignored
by git.
