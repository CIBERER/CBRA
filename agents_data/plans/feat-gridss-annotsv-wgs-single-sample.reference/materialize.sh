#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source_dir="$repo_root/agents_data/reference-data/feat-gridss-tsv"
data_dir="$repo_root/agents_data/reference-data/feat-gridss-annotsv-wgs-single-sample"
input_dir="$data_dir/derived/input"
index_dir="$data_dir/derived/bwa-index"
gridss_image='https://depot.galaxyproject.org/singularity/gridss:2.13.2--h270b39a_0'
revision='c16e7bd8bbc7ed534a3652a608ed0b2098037bdd'
base_url="https://raw.githubusercontent.com/nf-core/test-datasets/$revision/data/genomics/homo_sapiens"

mkdir -p "$source_dir" "$input_dir" "$index_dir"
files=(sample1.bam sample1.bam.bai genome.fasta genome.fasta.fai)
urls=(
    "$base_url/illumina/bam/test.rna.paired_end.sorted.bam"
    "$base_url/illumina/bam/test.rna.paired_end.sorted.bam.bai"
    "$base_url/genome/genome.fasta"
    "$base_url/genome/genome.fasta.fai"
)
hashes=(
    65663815b591bf76118335606fc418a5e9434cb604ca12a6611c9b5f949d067c
    aa28640323adbaf35c2ccfdf4a24367a07bdb8010e932ae5337fbf16fef40359
    48d0bbb875d37e529640d43f2751ec2a25e0ba1144f1994773e9c643d3cf9d05
    aa684078e5bc8ec77af619fb6c3e6e9e51e143d997d84ab213b47eff844757d1
)

for i in "${!files[@]}"; do
    file="$source_dir/${files[$i]}"
    if [[ ! -e "$file" ]]; then
        tmp="$file.download"
        [[ ! -e "$tmp" ]] || { echo "Refusing existing download: $tmp" >&2; exit 1; }
        curl --fail --location --output "$tmp" "${urls[$i]}"
        mv "$tmp" "$file"
    fi
    printf '%s  %s\n' "${hashes[$i]}" "$file" | sha256sum --check --status || {
        echo "Fixture checksum mismatch: $file" >&2
        exit 1
    }
    if [[ ! -e "$input_dir/${files[$i]}" ]]; then
        ln -s "$file" "$input_dir/${files[$i]}"
    fi
done

manifest="$source_dir/manifest.tsv"
if [[ ! -e "$manifest" ]]; then
    {
        printf 'format\tfeat-gridss-tsv-reference-manifest-v1\n'
        printf 'source_revision\t%s\n' "$revision"
        printf 'file\turl\tsha256\n'
        for i in "${!files[@]}"; do
            printf '%s\t%s\t%s\n' "${files[$i]}" "${urls[$i]}" "${hashes[$i]}"
        done
    } > "$manifest"
fi

index_prefix="$index_dir/genome.fasta"
if [[ ! -e "$index_prefix" ]]; then
    ln -s "$source_dir/genome.fasta" "$index_prefix"
fi
if [[ ! -e "$index_prefix.fai" ]]; then
    ln -s "$source_dir/genome.fasta.fai" "$index_prefix.fai"
fi
if [[ ! -s "$index_prefix.bwt" ]]; then
    apptainer exec --cleanenv --bind "$repo_root:$repo_root" --pwd "$repo_root" \
        "$gridss_image" bwa index "$index_prefix"
fi
for suffix in amb ann bwt pac sa; do
    [[ -s "$index_prefix.$suffix" ]] || { echo "BWA index missing: $suffix" >&2; exit 1; }
done

metadata="$data_dir/derived/materialization.tsv"
{
    printf 'source_revision\t%s\n' "$revision"
    printf 'command\tbash agents_data/plans/feat-gridss-annotsv-wgs-single-sample.reference/materialize.sh\n'
    printf 'image\t%s\n' "$gridss_image"
    printf 'bind\t%s:%s\n' "$repo_root" "$repo_root"
    for i in "${!files[@]}"; do
        printf 'input\t%s\t%s\t%s\n' "${files[$i]}" "${urls[$i]}" "${hashes[$i]}"
    done
    for suffix in amb ann bwt pac sa; do
        printf 'bwa-index\t%s\t%s\n' "$(sha256sum "$index_prefix.$suffix" | cut -d' ' -f1)" "genome.fasta.$suffix"
    done
} > "$metadata"
printf 'Materialized accepted fixture and BWA index: %s\n' "$data_dir/derived"
