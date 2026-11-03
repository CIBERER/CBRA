process GRIDSS_GRIDSS {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/gridss:2.13.2--h270b39a_0'
        : 'quay.io/biocontainers/gridss:2.13.2--h270b39a_0'}"

    input:
    tuple val(meta), path(inputs)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(fasta_fai)
    tuple val(meta4), path(bwa_index)

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    tuple val("${task.process}"), val('gridss'), eval("GeneratePonBedpe --version 2>&1 | sed 's/-gridss//'"), topic: versions, emit: versions_gridss

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Link a complete BWA index (prefix from its single *.amb) under the FASTA name; otherwise GRIDSS builds its own.
    def bwa = bwa_index ? """\
    set -- ${bwa_index}/*.amb
    bwa_prefix=\${1%.amb}
    if [ \$# -eq 1 ] && [ -e "\$bwa_prefix.amb" ] && [ -e "\$bwa_prefix.ann" ] \\
        && [ -e "\$bwa_prefix.bwt" ] && [ -e "\$bwa_prefix.pac" ] && [ -e "\$bwa_prefix.sa" ]; then
        for suffix in amb ann bwt pac sa; do
            ln -s "\$bwa_prefix.\$suffix" "${fasta}.\$suffix"
        done
    fi""" : ""
    """
    ${bwa}

    gridss \\
        --output ${prefix}.vcf.gz \\
        --reference ${fasta} \\
        --threads ${task.cpus} \\
        --jvmheap ${task.memory.toGiga() - 1}g \\
        --otherjvmheap ${task.memory.toGiga() - 1}g \\
        ${args} \\
        ${inputs}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def steps = args.contains("-s ")
        ? args.split('-s ')[-1].split(" ")[0]
        : args.contains("--steps ")
            ? args.split('--steps ')[-1].split(" ")[0]
            : "all"
    def vcf = steps.contains("call") || steps.contains("all") ? "echo '' | gzip > ${prefix}.vcf.gz" : ""
    """
    ${vcf}
    """
}
