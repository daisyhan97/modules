// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process DSHBIO_EXPORTSEGMENTS {
    tag "${meta.id}"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::dsh-bio=2.0.5" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/dsh-bio:2.0.5--hdfd78af_0"
    } else {
        container "quay.io/biocontainers/dsh-bio:2.0.5--hdfd78af_0"
    }

    input:
    tuple val(meta), path(gfa)

    output:
    tuple val(meta), path("*.fa"), emit: fasta
    path "*.version.txt"             , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    dsh-bio \\
        export-segments \\
        $options.args \\
        -i $gfa \\
        -o ${prefix}.fa

    echo \$(dsh-bio --version 2>&1) | grep -o 'dsh-bio-tools .*' | cut -f2 -d ' ' > ${software}.version.txt
    """
}
