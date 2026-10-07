include { GRIDSS_GRIDSS } from '../../../modules/nf-core/gridss/gridss/main'
include { TABIX_TABIX } from '../../../modules/nf-core/tabix/tabix/main'
include { ANNOTSV_ANNOTSV } from '../../../modules/nf-core/annotsv/annotsv/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../../../modules/nf-core/custom/dumpsoftwareversions/main'

workflow GRIDSS_ANNOTSV {
    take:
    ch_bam                  // channel: [ val(meta), path(bam), path(bai) ]
    ch_fasta                // channel: [ val(reference_meta), path(fasta) ]
    ch_fai                  // channel: [ val(reference_meta), path(fai) ]
    ch_bwa_index            // channel: [ val(reference_meta), path(bwa_index_dir) ]
    ch_annotsv_annotations  // channel: [ val(annotations_meta), path(annotations_parent_dir) ]

    main:
    ch_gridss_input = ch_bam.map { meta, bam, bai -> tuple(meta, bam) }
    GRIDSS_GRIDSS(ch_gridss_input, ch_fasta.first(), ch_fai.first(), ch_bwa_index.first())

    TABIX_TABIX(GRIDSS_GRIDSS.out.vcf)
    ch_indexed_vcf = GRIDSS_GRIDSS.out.vcf.join(TABIX_TABIX.out.tbi)

    ch_empty_optional = Channel.value(tuple([:], []))
    ch_annotsv_input = ch_indexed_vcf.map { meta, vcf, tbi -> tuple(meta, vcf, tbi, []) }
    ANNOTSV_ANNOTSV(
        ch_annotsv_input,
        ch_annotsv_annotations.first(),
        ch_empty_optional,
        ch_empty_optional,
        ch_empty_optional
    )

    ch_gridss_versions = GRIDSS_GRIDSS.out.versions_gridss.map { process_name, tool, version ->
        "\"${process_name}\":\n  ${tool}: '${version}'\n"
    }
    ch_versions = ch_gridss_versions
        .mix(TABIX_TABIX.out.versions.map { version_file -> version_file.text }, ANNOTSV_ANNOTSV.out.versions.map { version_file -> version_file.text })
        .collectFile(name: 'collated_versions.yml', sort: true)
    CUSTOM_DUMPSOFTWAREVERSIONS(ch_versions)

    emit:
    gridss_vcf     = GRIDSS_GRIDSS.out.vcf                   // channel: [ val(meta), path(vcf.gz) ]
    gridss_tbi     = TABIX_TABIX.out.tbi                     // channel: [ val(meta), path(tbi) ]
    annotsv_vcf    = ANNOTSV_ANNOTSV.out.vcf                 // channel: [ val(meta), path(vcf) ]
    annotsv_tsv    = ANNOTSV_ANNOTSV.out.tsv                 // channel: [ val(meta), path(tsv) ]
    annotsv_unannotated_tsv = ANNOTSV_ANNOTSV.out.unannotated_tsv // channel: [ val(meta), path(unannotated_tsv) ]
    versions       = CUSTOM_DUMPSOFTWAREVERSIONS.out.yml     // channel: path(software_versions.yml)
    versions_mqc   = CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml // channel: path(software_versions_mqc.yml)
}
