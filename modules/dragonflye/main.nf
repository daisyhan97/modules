// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process DRAGONFLYE {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::dragonflye=1.0.4" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/dragonflye:1.0.4--hdfd78af_0"
    } else {
        container "quay.io/biocontainers/dragonflye:1.0.4--hdfd78af_0"
    }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("contigs.fa")                                        , emit: contigs
    tuple val(meta), path("dragonflye.log")                                    , emit: log
    tuple val(meta), path("{flye,miniasm,raven}.fasta")                        , emit: raw_contigs
    tuple val(meta), path("{miniasm,raven}-unpolished.gfa"), optional:true     , emit: gfa
    tuple val(meta), path("flye-info.txt"), optional:true                      , emit: txt
    path "*.version.txt"                                                       , emit: version

    script:
    def software = getSoftwareName(task.process)
    def memory = task.memory.toGiga()
    """
    dragonflye \\
        --reads ${reads} \\
        $options.args \\
        --cpus $task.cpus \\
        --ram $memory \\
        --outdir ./ \\
        --force
    echo \$(dragonflye --version 2>&1) | sed 's/^.*dragonflye //'  > ${software}.version.txt
    """
}
