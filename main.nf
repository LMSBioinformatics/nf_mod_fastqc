process fastqc {
    tag "${name}"

    cpus 1
    memory 512.MB
    time { max(60, n_reads * 7e-06)  }.s

    module params.fastqc._module

    input:
    tuple val(name), path(r1), path(r2), val(n_reads)

    output:
    path '*_fastqc.{zip,html}'

    stub:
    if (r2) {
        stub_str = "touch ${name}_1.fastq.gz ${name}_2.fastq.gz"
    } else {
        stub_str = "touch ${name}.fastq.gz"
    }
    stub_str.stripIndent()

    script:
    if (r2) {
        run_str = """
        zcat ${r1} | fastqc stdin:${name}_1.fastq.gz
        zcat ${r2} | fastqc stdin:${name}_2.fastq.gz
        """
    } else {
        run_str = "zcat ${r1} | fastqc stdin:${name}.fastq.gz"
    }
    run_str.stripIndent()
}