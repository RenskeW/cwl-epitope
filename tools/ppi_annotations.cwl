#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

baseCommand: python3

doc: "Extract PPI annotations from BioDL."
intent: [ http://edamontology.org/operation_0320 ]

hints:
  # DockerRequirement: # dockerFile does not work with Singularity, upload image to repository and pull from there.
  #   dockerImageId: pdbecif-pandas:20220620
  #   dockerFile: |                                                               
  #     FROM docker.io/debian:stable-slim                                                                                                                         
  #     RUN apt-get update && apt-get install -y --no-install-recommends python3-pip
  #     RUN python3 -m pip install PDBeCif pandas  
  SoftwareRequirement:
    packages:
      pandas:
        specs: [ https://anaconda.org/conda-forge/pandas ]
        version: [ "1.2.4" ]
      python:
        version: [ "3.9.1" ]
      pdbecif:
        specs: [ https://pypi.org/project/PDBeCif/ ]
        version: [ "1.5" ]

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement: # the script takes a directory as input
    listing: |
      ${
           return [{"entry": {"class": "Directory", "basename": "mmcif_directory", "listing": inputs.mmcif_files}, "writable": true}]
       }

arguments:
- $(inputs.script.path)
- "mmcif_directory"
- $(inputs.train_dataset.path) # path to train biodl dataset
- $(inputs.test_dataset.path)
- "--outdir"
- $(inputs.output_directory)

inputs:
  script:
    type: File
    default:
      class: File
      location: ./ppi_annotations.py
  mmcif_files: # the download leaves us with an array of files, but script takes type Directory --> InitialWorkdirRequirement
    type: File[]
  train_dataset:
    type: File
    doc: "BioDL training set"
  test_dataset:
    type: File
    doc: "BioDL test set"
  output_directory:
    type: string
    default: "ppi_fasta"

outputs:
  ppi_fasta_files:
    type: Directory
    outputBinding:
      glob: $(inputs.output_directory) 
