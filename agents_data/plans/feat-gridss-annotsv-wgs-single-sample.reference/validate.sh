#!/usr/bin/env bash
set -euo pipefail

# Validate the accepted inputs and the independently generated reference outputs.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
input_dir="$repo_root/agents_data/reference-data/feat-gridss-tsv"
annotation_dir="$repo_root/agents_data/reference-data/Annotations_Human"
data_dir="$repo_root/agents_data/reference-data/feat-gridss-annotsv-wgs-single-sample"
image='https://depot.galaxyproject.org/singularity/gridss:2.13.2--h270b39a_0'

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 2; }
red() { printf 'RED: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }
require_file() { [[ -s "$1" ]] || fail "required input missing or empty: $1"; }
in_gridss() {
    apptainer exec --bind "$repo_root:$repo_root" --pwd "$repo_root" "$image" "$@"
}

case "${1:-all}" in
    inputs|all) ;;
    *) fail 'usage: validate.sh [inputs|all]' ;;
esac
command -v apptainer >/dev/null || fail 'apptainer is unavailable'
command -v python3 >/dev/null || fail 'python3 is unavailable'
command -v sha256sum >/dev/null || fail 'sha256sum is unavailable'

for name in sample1.bam sample1.bam.bai genome.fasta genome.fasta.fai manifest.tsv; do
    require_file "$input_dir/$name"
done
(
    cd "$input_dir"
    printf '%s\n' \
        '65663815b591bf76118335606fc418a5e9434cb604ca12a6611c9b5f949d067c  sample1.bam' \
        'aa28640323adbaf35c2ccfdf4a24367a07bdb8010e932ae5337fbf16fef40359  sample1.bam.bai' \
        '48d0bbb875d37e529640d43f2751ec2a25e0ba1144f1994773e9c643d3cf9d05  genome.fasta' \
        'aa684078e5bc8ec77af619fb6c3e6e9e51e143d997d84ab213b47eff844757d1  genome.fasta.fai' \
        | sha256sum --check --status
) || fail 'approved fixture checksum mismatch'
pass 'approved BAM/BAI and FASTA/FAI SHA-256 values'
in_gridss sh -c 'command -v samtools && command -v bcftools && command -v tabix' >/dev/null || fail 'pinned GRIDSS image lacks required validation tools'
in_gridss samtools faidx "$input_dir/genome.fasta" chr22:1-1 >/dev/null || fail 'FASTA/FAI random access failed'

in_gridss samtools quickcheck -v "$input_dir/sample1.bam" || fail 'BAM quickcheck failed'
header="$(in_gridss samtools view -H "$input_dir/sample1.bam")" || fail 'cannot read BAM header'
idxstats="$(in_gridss samtools idxstats "$input_dir/sample1.bam")" || fail 'BAI is unreadable'
primary="$(in_gridss samtools view -c -F 0x900 "$input_dir/sample1.bam")" || fail 'cannot count primary alignments'
paired="$(in_gridss samtools view -c -f 0x1 -F 0x900 "$input_dir/sample1.bam")" || fail 'cannot count paired alignments'
read1="$(in_gridss samtools view -c -f 0x40 -F 0x900 "$input_dir/sample1.bam")" || fail 'cannot count read 1'
read2="$(in_gridss samtools view -c -f 0x80 -F 0x900 "$input_dir/sample1.bam")" || fail 'cannot count read 2'
proper="$(in_gridss samtools view -c -f 0x2 -F 0x900 "$input_dir/sample1.bam")" || fail 'cannot count properly paired reads'
export header idxstats primary paired read1 read2 proper input_dir annotation_dir
python3 - <<'PY' || fail 'BAM, FASTA, or AnnotSV GRCh38 compatibility check failed'
import os
from pathlib import Path

root = Path(os.environ['input_dir'])
header = os.environ['header'].splitlines()
assert sum(line.startswith('@HD\t') and 'SO:coordinate' in line.split('\t') for line in header) == 1, 'BAM sorting'
sq = [line for line in header if line.startswith('@SQ\t')]
assert len(sq) == 1 and 'SN:chr22' in sq[0].split('\t') and 'LN:40001' in sq[0].split('\t'), 'BAM contig'
rg = [line for line in header if line.startswith('@RG\t')]
assert len(rg) == 1 and 'SM:test' in rg[0].split('\t'), 'one sample test'
assert int(os.environ['primary']) > 0, 'no primary reads'
assert int(os.environ['primary']) == int(os.environ['paired']), 'unpaired primary reads'
assert int(os.environ['read1']) == int(os.environ['read2']) > 0, 'read1/read2 imbalance'
assert int(os.environ['proper']) > 0, 'no properly paired reads'
idx = [line.split('\t') for line in os.environ['idxstats'].splitlines()]
assert any(row[0] == 'chr22' and row[1] == '40001' and int(row[2]) > 0 for row in idx), 'BAI contig or mapped count'
assert all(row[0] in ('chr22', '*') for row in idx), 'unexpected BAM contig'

fai = (root / 'genome.fasta.fai').read_text().strip().split('\t')
assert len(fai) == 5 and fai[0] == 'chr22' and int(fai[1]) == 40001, 'FAI contig/length'
with (root / 'genome.fasta').open() as handle:
    assert handle.readline().strip().split()[0] == '>chr22', 'FASTA header'
    sequence = ''.join(line.strip() for line in handle)
assert len(sequence) == 40001 and set(sequence.upper()) <= set('ACGTN'), 'FASTA sequence'

manifest = (root / 'manifest.tsv').read_text()
assert 'source_revision\tc16e7bd8bbc7ed534a3652a608ed0b2098037bdd' in manifest, 'fixture provenance'
for name in ('sample1.bam', 'sample1.bam.bai', 'genome.fasta', 'genome.fasta.fai'):
    assert any(line.startswith(name + '\thttps://raw.githubusercontent.com/nf-core/test-datasets/') for line in manifest.splitlines()), f'manifest: {name}'

annotation_root = Path(os.environ['annotation_dir'])
selected = (
    'Genes/GRCh38/genes.ENSEMBL.sorted.bed',
    'Genes/GRCh38/genes.RefSeq.sorted.bed',
    'AnyOverlap/CytoBand/GRCh38/cytoBand_GRCh38.formatted.sorted.bed',
    'BreakpointsAnnotations/SegDup/GRCh38/20240216_SegDup.sorted.bed',
    'SVincludedInFt/BenignSV/GRCh38/benign_Loss_SV_GRCh38.sorted.bed',
)
for relative in selected:
    path = annotation_root / relative
    assert path.is_file() and path.stat().st_size > 0, f'GRCh38 asset: {relative}'
    with path.open(errors='replace') as handle:
        assert any(line.split('\t', 1)[0].replace('chr', '', 1) == '22' for line in handle if not line.startswith('#')), f'chr22 in {relative}'
print('PASS: coordinate-sorted, indexed, paired sample test on chr22:40001; selected GRCh38 assets contain 22')
PY

[[ "${1:-all}" == inputs ]] && exit 0

# The independent outputs and index are supplied by Step 3.
reference_dir="$data_dir/reference"
required=(
    "$data_dir/derived/bwa-index/genome.fasta.amb"
    "$data_dir/derived/bwa-index/genome.fasta.ann"
    "$data_dir/derived/bwa-index/genome.fasta.bwt"
    "$data_dir/derived/bwa-index/genome.fasta.pac"
    "$data_dir/derived/bwa-index/genome.fasta.sa"
    "$reference_dir/gridss/sample1.gridss.vcf.gz"
    "$reference_dir/gridss/sample1.gridss.vcf.gz.tbi"
    "$reference_dir/annotsv/sample1.annotsv.vcf"
    "$reference_dir/annotsv/sample1.annotsv.tsv"
    "$reference_dir/annotsv/sample1.annotsv.unannotated.tsv"
    "$reference_dir/audit/sample1.bcftools-stats.txt"
    "$reference_dir/audit/versions.yml"
)
for path in "${required[@]}"; do
    [[ -s "$path" ]] || red "reference output/prerequisite not generated: $path"
done

in_gridss bcftools view -h "$reference_dir/gridss/sample1.gridss.vcf.gz" >/dev/null || fail 'GRIDSS VCF header invalid'
in_gridss tabix -l "$reference_dir/gridss/sample1.gridss.vcf.gz" | grep -Fx 'chr22' >/dev/null || fail 'GRIDSS TBI contig invalid'
in_gridss tabix "$reference_dir/gridss/sample1.gridss.vcf.gz" chr22:1-40001 >/dev/null || fail 'GRIDSS TBI region lookup failed'

export reference_dir
python3 - <<'PY' || fail 'reference VCF/TSV, metrics, or version contract failed'
import csv
import gzip
import os
import re
from pathlib import Path

base = Path(os.environ['reference_dir'])
gridss = base / 'gridss/sample1.gridss.vcf.gz'
annotated = base / 'annotsv/sample1.annotsv.vcf'
tsv = base / 'annotsv/sample1.annotsv.tsv'
unannotated = base / 'annotsv/sample1.annotsv.unannotated.tsv'
stats = base / 'audit/sample1.bcftools-stats.txt'
versions = base / 'audit/versions.yml'

def calls(path):
    opener = gzip.open if path.suffix == '.gz' else open
    with opener(path, 'rt') as handle:
        lines = handle.readlines()
    header = [line for line in lines if line.startswith('#CHROM\t')]
    assert len(header) == 1 and header[0].rstrip('\n').split('\t')[9:] == ['test'], f'VCF sample: {path}'
    records = [line.rstrip('\n').split('\t') for line in lines if line and not line.startswith('#')]
    assert records and all(len(record) >= 10 for record in records), f'VCF records: {path}'
    assert all(record[0].replace('chr', '', 1) == '22' and 1 <= int(record[1]) <= 40001 for record in records), f'VCF contigs: {path}'
    identifiers = {record[2]: record for record in records}
    assert len(identifiers) == len(records) and all(value not in ('', '.') for value in identifiers), f'VCF IDs: {path}'
    return identifiers

def unannotated_calls(path, source_calls):
    # AnnotSV records one diagnostic per unannotated variant, not a table.
    source_records = list(source_calls.values())
    diagnostics = path.read_text().splitlines()
    assert diagnostics, 'no unannotated variant rows'
    identifiers = set()
    for diagnostic in diagnostics:
        match = re.fullmatch(r'([^\s]+): (.+) \(line ([1-9][0-9]*)\)', diagnostic)
        assert match, f'AnnotSV unannotated row format: {diagnostic}'
        identifier, reason, line_number = match.groups()
        assert reason.strip(), f'AnnotSV unannotated reason: {identifier}'
        assert identifier not in identifiers, f'duplicate AnnotSV unannotated ID: {identifier}'
        identifiers.add(identifier)
        parts = identifier.split('_', 5)
        assert len(parts) == 6, f'AnnotSV unannotated ID schema: {identifier}'
        chrom, position, end, sv_type, ref, alt = parts
        assert chrom == '22' and position.isdecimal() and 1 <= int(position) <= 40001, f'AnnotSV unannotated locus: {identifier}'
        assert not end or (end.isdecimal() and int(position) <= int(end) <= 40001), f'AnnotSV unannotated end: {identifier}'
        assert sv_type in {'BND', 'DEL', 'DUP', 'INS', 'INV'}, f'AnnotSV unannotated type: {identifier}'
        assert ref and alt, f'AnnotSV unannotated alleles: {identifier}'
        assert int(line_number) > 0, f'AnnotSV unannotated source line: {identifier}'
        candidates = [record for record in source_records if record[0].replace('chr', '', 1) == chrom and record[1] == position]
        assert candidates, f'AnnotSV unannotated GRIDSS locus: {identifier}'
        assert all(record[9] not in ('', '.') for record in candidates), f'AnnotSV unannotated source sample: {identifier}'
        if sv_type == 'BND':
            assert any(ref == record[3] and alt == record[4] for record in candidates), f'AnnotSV unannotated GRIDSS alleles: {identifier}'
    return identifiers

gridss_calls = calls(gridss)
annotated_calls = calls(annotated)
unannotated_ids = unannotated_calls(unannotated, gridss_calls)
with tsv.open(newline='') as handle:
    reader = csv.DictReader(handle, delimiter='\t')
    required_columns = {'ID', 'AnnotSV_ID', 'SV_chrom', 'SV_start', 'SV_end', 'Samples_ID', 'QUAL', 'FILTER', 'FORMAT', 'test'}
    assert reader.fieldnames and required_columns <= set(reader.fieldnames), 'AnnotSV TSV columns'
    rows = list(reader)
assert rows and all(row['ID'] and row['AnnotSV_ID'] for row in rows), 'AnnotSV TSV call identifiers'
tsv_ids = {row['ID'] for row in rows}
assert len(tsv_ids) == len(rows), 'duplicate AnnotSV TSV source IDs'
assert len({row['AnnotSV_ID'] for row in rows}) == len(rows), 'duplicate AnnotSV annotation IDs'
assert tsv_ids == set(annotated_calls), 'AnnotSV VCF/TSV source IDs differ'
assert tsv_ids <= set(gridss_calls), 'AnnotSV source IDs absent from GRIDSS VCF'

# AnnotSV converts some GRIDSS breakends into DEL records and adjusts their
# coordinates. The source ID is the stable join key; converted VCF coordinates
# must agree with the TSV and its AnnotSV_ID rather than the original VCF POS.
for row in rows:
    source = gridss_calls[row['ID']]
    result = annotated_calls[row['ID']]
    chrom = row['SV_chrom'].replace('chr', '', 1)
    assert chrom == source[0].replace('chr', '', 1) == result[0].replace('chr', '', 1), f'call chromosome: {row["ID"]}'
    assert 1 <= int(row['SV_start']) <= int(row['SV_end']) <= 40001, f'annotation coordinates: {row["ID"]}'
    assert int(result[1]) == int(row['SV_start']), f'AnnotSV VCF/TSV position: {row["ID"]}'
    info = dict(field.split('=', 1) for field in result[7].split(';') if '=' in field)
    assert info.get('AnnotSV_ID') == row['AnnotSV_ID'], f'AnnotSV VCF/TSV annotation ID: {row["ID"]}'
    assert info.get('SV_start') == row['SV_start'] and info.get('END') == row['SV_end'], f'AnnotSV VCF/TSV interval: {row["ID"]}'
    assert row['Samples_ID'] == 'test', f'AnnotSV TSV sample: {row["ID"]}'
    for column, index in (('QUAL', 5), ('FILTER', 6), ('FORMAT', 8), ('test', 9)):
        assert row[column] == result[index] == source[index], f'{column} provenance: {row["ID"]}'

stats_text = stats.read_text()
record_counts = [int(line.split('\t')[-1]) for line in stats_text.splitlines() if line.startswith('SN\t') and '\tnumber of records:\t' in line]
assert record_counts == [len(gridss_calls)], 'BCFtools record metrics disagree with GRIDSS VCF'
version_text = versions.read_text().lower()
assert all(tool in version_text for tool in ('gridss', 'tabix', 'bcftools', 'annotsv')), 'named tool versions'
print(f'PASS: {len(gridss_calls)} GRIDSS records, {len(tsv_ids)} traced AnnotSV VCF/TSV calls, {len(unannotated_ids)} traced unannotated diagnostics, audit and versions')
PY
