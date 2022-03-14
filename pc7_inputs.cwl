#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool 
baseCommand: python3
inputs:
  script:
    type: File
    inputBinding: {position: 1}
  fasta:
    type: File 
    inputBinding:
      position: 2

outputs: 
  out: 
    type: File[] # How do I store all these files in a single directory? Or is this automatic in a workflow?
    outputBinding:
      glob: "*.input"