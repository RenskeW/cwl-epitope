#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool 
hints:
  DockerRequirement:
    dockerPull: amancevice/pandas:1.3.4-slim
  # SoftwareRequirement:
  #   packages: 
  #     numpy:
  #       specs: [ https://anaconda.org/conda-forge/numpy ]

baseCommand: python3
inputs:
  script:
    type: File
    default: 
      class: File
      location: ../tools/get_psp19_inputs.py  
    inputBinding: 
      position: 1
  fasta:
    type: File 
    inputBinding:
      position: 2
  outdir:
    # type: Directory
    type: string
    inputBinding: 
      position: 3
      prefix: -o
    # default:
    #   class: Directory
    #   location: ./psp19_features
    default: "psp19_features"

outputs: 
  psp19_features: 
    type: Directory 
    outputBinding:
      glob: $(inputs.outdir)