nextflow.enable.dsl = 2

include { DELLY_ANNOTSV } from '../../main.nf'

workflow {

    ch_bam = Channel.of([
        [ id:'test' ],
        file(params.delly_exampledata_base_path + 'sr.bam', checkIfExists:true),
        file(params.delly_exampledata_base_path + 'sr.bam.bai', checkIfExists:true)
    ])

    ch_fasta = Channel.of([
        [ id:'genome' ],
        file(params.delly_exampledata_base_path + 'ref.fa', checkIfExists:true)
    ])

    ch_fai = Channel.of([
        [ id:'genome' ],
        file(params.delly_exampledata_base_path + 'ref.fa.fai', checkIfExists:true)
    ])

    ch_annotsv_annotations = Channel.of([
        [ id:'annotations' ],
        file(params.annotsv_annotations, checkIfExists:true)
    ])

    ch_candidate_genes = Channel.of([[:], []])
    ch_false_positive_snv = Channel.of([[:], []])
    ch_gene_transcripts = Channel.of([[:], []])

    DELLY_ANNOTSV(
        ch_bam,
        ch_fasta,
        ch_fai,
        ch_annotsv_annotations,
        ch_candidate_genes,
        ch_false_positive_snv,
        ch_gene_transcripts
    )

    DELLY_ANNOTSV.out.vcf.view { "raw delly vcf: ${it}" }
    DELLY_ANNOTSV.out.vcf_index.view { "raw delly index: ${it}" }
    DELLY_ANNOTSV.out.annotated_tsv.view { "annotsv tsv: ${it}" }
    DELLY_ANNOTSV.out.annotated_vcf.view { "annotsv vcf: ${it}" }
    DELLY_ANNOTSV.out.unannotated_tsv.view { "annotsv unannotated tsv: ${it}" }
    DELLY_ANNOTSV.out.versions.view { "versions: ${it}" }
}
