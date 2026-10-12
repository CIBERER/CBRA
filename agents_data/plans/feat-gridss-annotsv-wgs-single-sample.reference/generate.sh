#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
helper_dir="$repo_root/agents_data/plans/feat-gridss-annotsv-wgs-single-sample.reference"
data_dir="$repo_root/agents_data/reference-data/feat-gridss-annotsv-wgs-single-sample"
input_dir="$data_dir/derived/input"
reference_dir="$data_dir/reference"
image_dir="$data_dir/derived/images"
work_dir="$data_dir/derived/work"
annotation_dir="$repo_root/agents_data/reference-data/Annotations_Human"

gridss_uri='https://depot.galaxyproject.org/singularity/gridss:2.13.2--h270b39a_0'
tabix_uri='https://depot.galaxyproject.org/singularity/htslib:1.20--h5efdd21_2'
annotsv_uri='docker://community.wave.seqera.io/library/annotsv:3.5.3--71a461cb86d570b7'
bcftools_uri='https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0b/0b4d52ca9a56d07be3f78a12af654e5116f5112908dba277e6796fd9dfb83fe5/data'

bash "$helper_dir/materialize.sh"
for relative in \
    Genes/GRCh38/genes.ENSEMBL.sorted.bed \
    Genes/GRCh38/genes.RefSeq.sorted.bed \
    AnyOverlap/CytoBand/GRCh38/cytoBand_GRCh38.formatted.sorted.bed \
    BreakpointsAnnotations/SegDup/GRCh38/20240216_SegDup.sorted.bed \
    SVincludedInFt/BenignSV/GRCh38/benign_Loss_SV_GRCh38.sorted.bed; do
    [[ -s "$annotation_dir/$relative" ]] || { echo "Missing GRCh38 annotation: $relative" >&2; exit 1; }
done

mkdir -p "$image_dir" "$work_dir" "$reference_dir/gridss" "$reference_dir/annotsv" "$reference_dir/audit"
outputs=(
    "$reference_dir/gridss/sample1.gridss.vcf.gz"
    "$reference_dir/gridss/sample1.gridss.vcf.gz.tbi"
    "$reference_dir/annotsv/sample1.annotsv.vcf"
    "$reference_dir/annotsv/sample1.annotsv.tsv"
    "$reference_dir/annotsv/sample1.annotsv.unannotated.tsv"
    "$reference_dir/audit/sample1.bcftools-stats.txt"
    "$reference_dir/audit/versions.yml"
)
for output in "${outputs[@]}"; do
    [[ ! -e "$output" ]] || { echo "Refusing to overwrite reference: $output" >&2; exit 1; }
done

pull_image() {
    local name="$1" uri="$2" expected="${3:-}"
    local sif="$image_dir/$name.sif"
    if [[ ! -s "$sif" ]]; then
        apptainer pull "$sif" "$uri"
    fi
    local actual
    actual="$(sha256sum "$sif" | cut -d' ' -f1)"
    if [[ -n "$expected" && "$actual" != "$expected" ]]; then
        echo "SIF checksum mismatch for $name: $actual" >&2
        exit 1
    fi
    printf '%s\t%s\t%s\t%s\n' "$name" "$uri" "$sif" "$actual" >> "$reference_dir/audit/images.tsv"
}

[[ ! -e "$reference_dir/audit/images.tsv" ]] || { echo 'Refusing existing images manifest' >&2; exit 1; }
pull_image gridss "$gridss_uri" c1d9336c481d0a460a8a320b30e8ed217c8315d53f5e553e9fd1f4ad8676c244
pull_image tabix "$tabix_uri"
pull_image annotsv "$annotsv_uri" 6727ccdf9c97716965592e54c5a7dfb3cede5c13f05367137ab7cf9359175069
pull_image bcftools "$bcftools_uri"

gridss_image="$image_dir/gridss.sif"
tabix_image="$image_dir/tabix.sif"
annotsv_image="$image_dir/annotsv.sif"
bcftools_image="$image_dir/bcftools.sif"
bind_root="$repo_root:$repo_root"

commands="$reference_dir/audit/commands.sh"
{
    printf '#!/usr/bin/env bash\nset -euo pipefail\n'
    printf '# All paths refer to the original workspace. Regenerate with generate.sh.\n'
    printf 'apptainer exec --cleanenv --bind %q --pwd %q %q gridss --output %q --reference %q --threads 2 --jvmheap 3g --otherjvmheap 3g %q\n' \
        "$bind_root" "$work_dir" "$gridss_image" "$reference_dir/gridss/sample1.gridss.vcf.gz" "$input_dir/genome.fasta" "$input_dir/sample1.bam"
    printf 'apptainer exec --cleanenv --bind %q --pwd %q %q tabix -f -p vcf %q\n' \
        "$bind_root" "$work_dir" "$tabix_image" "$reference_dir/gridss/sample1.gridss.vcf.gz"
    printf 'apptainer exec --cleanenv --writable-tmpfs --bind %q --pwd %q %q AnnotSV -annotationsDir %q -outputFile %q -SVinputFile %q -vcf 1\n' \
        "$bind_root" "$work_dir" "$annotsv_image" "$(dirname "$annotation_dir")" "$reference_dir/annotsv/sample1.annotsv.tsv" "$reference_dir/gridss/sample1.gridss.vcf.gz"
    printf 'apptainer exec --cleanenv --bind %q --pwd %q %q bcftools stats %q > %q\n' \
        "$bind_root" "$work_dir" "$bcftools_image" "$reference_dir/gridss/sample1.gridss.vcf.gz" "$reference_dir/audit/sample1.bcftools-stats.txt"
} > "$commands"

apptainer exec --cleanenv --bind "$bind_root" --pwd "$work_dir" "$gridss_image" \
    gridss --output "$reference_dir/gridss/sample1.gridss.vcf.gz" \
    --reference "$input_dir/genome.fasta" --threads 2 --jvmheap 3g --otherjvmheap 3g \
    "$input_dir/sample1.bam"
apptainer exec --cleanenv --bind "$bind_root" --pwd "$work_dir" "$tabix_image" \
    tabix -f -p vcf "$reference_dir/gridss/sample1.gridss.vcf.gz"
apptainer exec --cleanenv --writable-tmpfs --bind "$bind_root" --pwd "$work_dir" "$annotsv_image" \
    AnnotSV -annotationsDir "$(dirname "$annotation_dir")" \
    -outputFile "$reference_dir/annotsv/sample1.annotsv.tsv" \
    -SVinputFile "$reference_dir/gridss/sample1.gridss.vcf.gz" -vcf 1
[[ -s "$reference_dir/annotsv/sample1.annotsv.unannotated.tsv" ]] || {
    echo 'AnnotSV did not produce a non-empty unannotated TSV' >&2
    exit 1
}
apptainer exec --cleanenv --bind "$bind_root" --pwd "$work_dir" "$bcftools_image" \
    bcftools stats "$reference_dir/gridss/sample1.gridss.vcf.gz" \
    > "$reference_dir/audit/sample1.bcftools-stats.txt"

version_file="$reference_dir/audit/versions.yml"
{
    printf 'reference-generation:\n'
    printf '  gridss: "%s"\n' "$(apptainer exec --cleanenv "$gridss_image" GeneratePonBedpe --version 2>&1 | sed 's/-gridss//' | head -1)"
    printf '  tabix: "%s"\n' "$(apptainer exec --cleanenv "$tabix_image" tabix --version 2>&1 | head -1)"
    printf '  bcftools: "%s"\n' "$(apptainer exec --cleanenv "$bcftools_image" bcftools --version 2>&1 | head -1)"
    printf '  annotsv: "%s"\n' "$(apptainer exec --cleanenv --writable-tmpfs "$annotsv_image" AnnotSV -help 2>&1 | head -1)"
} > "$version_file"

provenance="$reference_dir/audit/provenance.tsv"
{
    printf 'execution\tbash agents_data/plans/feat-gridss-annotsv-wgs-single-sample.reference/generate.sh\n'
    printf 'apptainer\t%s\n' "$(apptainer --version)"
    printf 'bind\t%s\n' "$bind_root"
    printf 'annotation-directory\t%s\n' "$annotation_dir"
    printf 'annotation-build\tGRCh38\n'
    for relative in \
        Genes/GRCh38/genes.ENSEMBL.sorted.bed \
        Genes/GRCh38/genes.RefSeq.sorted.bed \
        AnyOverlap/CytoBand/GRCh38/cytoBand_GRCh38.formatted.sorted.bed \
        BreakpointsAnnotations/SegDup/GRCh38/20240216_SegDup.sorted.bed \
        SVincludedInFt/BenignSV/GRCh38/benign_Loss_SV_GRCh38.sorted.bed; do
        printf 'annotation\t%s\t%s\n' "$relative" "$(sha256sum "$annotation_dir/$relative" | cut -d' ' -f1)"
    done
    for output in "${outputs[@]}"; do
        printf 'output\t%s\t%s\n' "${output#"$data_dir/"}" "$(sha256sum "$output" | cut -d' ' -f1)"
    done
    printf 'output-generator\t%s\t%s\n' \
        'reference/annotsv/sample1.annotsv.unannotated.tsv' 'audit/commands.sh:AnnotSV -vcf 1'
} > "$provenance"

bash "$helper_dir/validate.sh"
