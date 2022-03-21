#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool 
hints:
  DockerRequirement:
    dockerPull: amancevice/pandas:1.3.4-slim # Script needs numpy which is a dependency of pandas
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
      location: ../tools/get_pc7_inputs.py  
    inputBinding: {position: 1}
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
    #   location: ./pc7_features
    default: "pc7_features"

outputs: 
  pc7_features: 
    type: Directory 
    outputBinding:
      glob: $(inputs.outdir)