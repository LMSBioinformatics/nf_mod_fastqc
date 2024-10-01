/*
Run fastqc and scrape the number of reads/pairs for a set of samples
*/
process fastqc {
    tag "${name}"

    cpus 1
    memory 1.GB
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

/*
Count the number of reads/pairs across a set of samples
*/
process count_reads {
    tag "${name}"

    cpus 1
    memory 1.GB
    time 1.h

    input:
    tuple val(name), path(r1), path(r2)

    output:
    tuple val(name), stdout, emit: n_reads

    script:
    """
    bc <<< "\$(zcat ${r1} | wc -l)/4"
    """
}


/*
Count the number of "Undetermined" reads from demux and form a table of the
most common
*/
process count_undetermined {
    cpus 1
    memory 1.GB
    time 1.h

    publishDir "${params.outdir}/qc",
        mode: "copy",
        pattern: "Undetermined_barcodes.csv"

    input:
    val(run_dir)

    output:
    stdout emit: n_undetermined
    path "Undetermined_barcodes.csv", optional: true, emit: files

    script:
    """
    #!/usr/bin/python3

    from collections import defaultdict as dd
    import gzip
    from pathlib import Path

    barcodes = dd(int)
    for f in Path('${run_dir}').glob('Undetermined_*_R1_*'):
        with gzip.open(f, mode='rt') as F:
            for i, l in enumerate(F):
                if i % 4 != 0: continue
                barcodes[l.split(':')[-1].strip()] += 1

    total = 0
    if barcodes:
        with open('Undetermined_barcodes.csv', 'w') as F:
            print('Barcode,Count', file=F)
            for k, v in sorted(
                    barcodes.items(), key=lambda x: x[1], reverse=True):
                total += v
                print(f'{k},{v}', file=F)
    print(total)
    """
}