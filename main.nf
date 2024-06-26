process fastqc {
    tag "${name}"

    cpus 1
    memory 512.MB
    time 1.h
    // time "${t = (n_reads.toInteger() * 1.2 * 7e-06) as int; t < 60 ? 60 : t}s"

    publishDir "${params.outdir}/qc/fastqc",
        mode: "copy",
        pattern: "*.html"

    beforeScript "module reset &> /dev/null"
    module params.fastqc._module

    input:
    tuple val(name), path(r1), path(r2)

    output:
    tuple val(name), stdout, emit: n_reads
    path '*_fastqc.{zip,html}', emit: files

    stub:
    if (r2) {
        stub_str = "touch ${name}_1.fastq.gz ${name}_2.fastq.gz"
    } else {
        stub_str = "touch ${name}.fastq.gz"
    }
    stub_str.stripIndent()

    script:
    if (r2) {
        """
zcat ${r1} | fastqc -q stdin:${name}_1.fastq.gz &> /dev/null\
&& zcat ${r2} | fastqc -q stdin:${name}_2.fastq.gz  &> /dev/null\
&& unzip -p ${name}_1_fastqc.zip ${name}_1_fastqc/fastqc_data.txt \
| grep "^Total Sequences" \
| cut -f2
"""
    } else {
        """
zcat ${r1} | fastqc -q stdin:${name}.fastq.gz  &> /dev/null\
&& unzip -p ${name}_fastqc.zip ${name}_fastqc/fastqc_data.txt \
| grep "^Total Sequences" \
| cut -f2
"""
    }
}