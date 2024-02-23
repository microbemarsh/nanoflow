// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
process EMU_COMBINE {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/emu:3.1.0--hdfd78af_0':
        'quay.io/biocontainers/emu:3.4.5--hdfd78af_0' }"

    input:
    // TODO nf-core: Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".

    tuple val(meta), path(tsv)
    path(outdir)

    output:
    tuple val(meta), path("*.log")              , emit: log
    tuple val(meta), path("*emu-combined.tsv")  , emit: combined
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def relabunddir = relabunddir_directory ? "--db_directory $db_directory" : ""
    def outdir = outdir : ""

    """
    emu \\
        combine-outputs \\
        $args \\
        --split-tables \\
        --db $db_directory \\
        --threads $task.cpus \\
        --keep-counts \\
        --keep-files \\
        --output-dir $outdir

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        emu: \$(emu --version |& sed '1!d ; s/emu //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        emu: \$(emu --version |& sed '1!d ; s/emu //')
    END_VERSIONS
    """
}
