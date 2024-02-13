/*
 * Pipeline input parameters
 */
params.reads = "$projectDir/data/*_{1,2}.fq"
params.outdir = "results"

/*
 * Log info
 */
log.info """\
    Q U A L I T Y   C O N T R O L   P I P E L I N E
    ===============================================
    reads        : ${params.reads}
    outdir       : ${params.outdir}
    """
    .stripIndent()


/*
 * PROCESS: FASTQC
 */
process FASTQC {
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    tag "FASTQC on $sample_id"

    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """
}

/*
 * PROCESS: MULTIQC
 */
process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.17--pyhdfd78af_1'
    publishDir params.outdir, mode:'copy'

    input:
    path '*'

    output:
    path 'multiqc_report.html'

    script:
    """
    multiqc .
    """
 }

/*
 * WORKFLOW
 */
workflow {
    Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .set { read_pairs_ch }

    FASTQC(read_pairs_ch)
        .set { fastqc_ch }

    MULTIQC(fastqc_ch.collect())

}

 workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
}
