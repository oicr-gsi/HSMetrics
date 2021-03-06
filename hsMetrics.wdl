version 1.0

workflow hsMetrics {
input {
   File    inputBam
   String  baitBed
   String  targetBed
   String outputFileNamePrefix = basename(inputBam, '.bam')
}

call bedToIntervals as bedToTargetIntervals { input: inputBed = targetBed }
call bedToIntervals as bedToBaitIntervals { input: inputBed = baitBed }

call collectHSmetrics{ input: inputBam = inputBam, baitIntervals = bedToBaitIntervals.outputIntervals, targetIntervals = bedToTargetIntervals.outputIntervals, outputPrefix = outputFileNamePrefix }

meta {
  author: "Peter Ruzanov"
  email: "peter.ruzanov@oicr.on.ca"
  description: "HSMetrics 2.0"
  dependencies: [{
    name: "picard/2.21.2",
    url: "https://broadinstitute.github.io/picard/"
  }]
}

output {
  File outputHSMetrics  = collectHSmetrics.outputHSMetrics
}

}

task bedToIntervals {
input {
   String inputBed
   String refDict = "$HG19_ROOT/hg19_random.dict"
   Int    jobMemory = 16
   String modules   = "picard/2.21.2 hg19/p13"
   Int timeout = 1
}

command <<<
 java -Xmx~{jobMemory-6}G -jar $PICARD_ROOT/picard.jar BedToIntervalList \
                              INPUT=~{inputBed} \
                              OUTPUT="~{basename(inputBed, '.bed')}.interval_list" \
                              SD="~{refDict}"
>>>

parameter_meta {
 inputBed: "Path to input bed file"
 refDict: "Path to index of fasta reference file"
 jobMemory: "Memory allocated to job"
 modules: "Names and versions of modules needed"
 timeout: "Maximum amount of time (in hours) the task can run for."
}

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}

output {
  File outputIntervals = "~{basename(inputBed, '.bed')}.interval_list"
}
}

task collectHSmetrics {
input { 
   File   inputBam
   String baitIntervals
   String targetIntervals
   String refFasta   = "$HG19_ROOT/hg19_random.fa"
   String metricTag  = "HS"
   String filter     = "LENIENT"
   String outputPrefix = "OUTPUT"
   Int   jobMemory   = 18
   Int   coverageCap = 500
   Int   maxRecordsInRam = 250000
   String modules    = "picard/2.21.2 hg19/p13"
   Int timeout = 5
}

command <<<
 java -Xmx~{jobMemory-6}G -jar $PICARD_ROOT/picard.jar CollectHsMetrics \
                              TMP_DIR=picardTmp \
                              BAIT_INTERVALS=~{baitIntervals} \
                              TARGET_INTERVALS=~{targetIntervals} \
                              R=~{refFasta} \
                              COVERAGE_CAP=~{coverageCap} \
                              MAX_RECORDS_IN_RAM=~{maxRecordsInRam} \
                              INPUT=~{inputBam} \
                              OUTPUT="~{outputPrefix}.~{metricTag}.txt" \
                              VALIDATION_STRINGENCY=~{filter}
>>>

parameter_meta {
 inputBam: "Input bam file"
 baitIntervals: "path to bed file with bait intervals"
 targetIntervals: "path to bed file with target intervals"
 refFasta: "Path to fasta reference file"
 metricTag: "Extension for metrics file"
 filter: "Settings for picard filter"
 outputPrefix: "prefix to build a name for output file"
 coverageCap: "Parameter to set a max coverage limit for Theoretical Sensitivity calculations"
 maxRecordsInRam: "Specifies the N of records stored in RAM before spilling to disk. Increasing this number increases the amount of RAM needed."
 jobMemory: "Memory allocated to job"
 modules: "Names and versions of modules needed"
 timeout: "Maximum amount of time (in hours) the task can run for."
}

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}

output {
  File outputHSMetrics = "~{outputPrefix}.~{metricTag}.txt"
}

}

