include { DELLY_CALL } from '../../../modules/nf-core/delly/call/main'
include { BCFTOOLS_INDEX } from '../../../modules/nf-core/bcftools/index/main'
include { ANNOTSV_ANNOTSV } from '../../../modules/nf-core/annotsv/annotsv/main'

workflow SV_CALLING_DELLY {

    take:
    ch_bam                 // channel (mandatory): [ val(meta), path(bam), path(bai) ]
    ch_fasta               // channel (mandatory): [ val(meta2), path(fasta) ]
    ch_fai                 // channel (mandatory): [ val(meta3), path(fai) ]
    ch_annotsv_annotations // channel (mandatory): [ val(meta), path(annotations) ]
    ch_candidate_genes     // channel (optional):  [ val(meta), path(candidate_genes) ]
    ch_false_positive_snv  // channel (optional):  [ val(meta), path(false_positive_snv) ]
    ch_gene_transcripts    // channel (optional):  [ val(meta), path(gene_transcripts) ]

    main:

    ch_versions = Channel.empty()

    // Delly expects: [ meta, bam, bai, vcf, vcf_index, exclude_bed ].
    // For raw WGS calling there is no prior callset to genotype or excluded BED.
    ch_delly_input = ch_bam.map { meta, bam, bai ->
        [ meta, bam, bai, [], [], [] ]
    }

    DELLY_CALL (
        ch_delly_input,
        ch_fasta,
        ch_fai,
        'vcf'
    )

    ch_delly_versions = DELLY_CALL.out.versions_delly
        .unique()
        .map { process, tool, version ->
            "\"${process}\":\n    ${tool}: ${version}\n"
        }
        .collectFile(name: 'delly_versions.yml')
    ch_versions = ch_versions.mix(ch_delly_versions)


    // DELLY_CALL outputs index as .csi, Annotsv expects .tbi
    // bcftools expects: [.{vcf,vcf.gz}]

    BCFTOOLS_INDEX (
        DELLY_CALL.out.bcf
    )

    ch_bcftools_versions = BCFTOOLS_INDEX.out.versions_bcftools
        .unique()
        .map { process, tool, version ->
            "\"${process}\":\n    ${tool}: ${version}\n"
        }
        .collectFile(name: 'bcftools_index_versions.yml')
    ch_versions = ch_versions.mix(ch_bcftools_versions)

    // same format as MANTA_GERMLINE for ANNOTSV_ANNOTSV: [ meta, vcf, vcf_index ]
    ch_annotsv_input = DELLY_CALL.out.bcf
        .join(BCFTOOLS_INDEX.out.index)
        .map { meta, vcf, vcf_index ->
            [ meta, vcf, vcf_index, [] ]
        }

    ANNOTSV_ANNOTSV (
        ch_annotsv_input,
        ch_annotsv_annotations,
        ch_candidate_genes,
        ch_false_positive_snv,
        ch_gene_transcripts
    )
    ch_versions = ch_versions.mix(ANNOTSV_ANNOTSV.out.versions.first())

    emit:
    vcf             = DELLY_CALL.out.bcf            // channel: [ val(meta), path(vcf.gz) ]
    vcf_index       = BCFTOOLS_INDEX.out.index      // channel: [ val(meta), path(tbi) ]
    annotated_tsv   = ANNOTSV_ANNOTSV.out.tsv       // channel: [ val(meta), path(tsv) ]
    annotated_vcf   = ANNOTSV_ANNOTSV.out.vcf       // channel: [ val(meta), path(vcf) ] (optional, requires -vcf 1 in args)
    unannotated_tsv = ANNOTSV_ANNOTSV.out.unannotated_tsv
    versions        = ch_versions                   // channel: [ versions.yml ]
}
