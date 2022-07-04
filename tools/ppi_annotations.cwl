#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

baseCommand: python3

# To do: add DockerRequirement (give network access)
arguments:
- $(inputs.script.path)
- $(inputs.mmcif_directory.path)
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
  mmcif_directory:
    type: Directory
  train_dataset:
    type: File
  test_dataset:
    type: File
  output_directory:
    type: string
    default: "ppi_fasta"

outputs:
  ppi_fasta_files:
    type: Directory
    outputBinding:
      glob: $(inputs.output_directory) 

doc: Some tool which uses BioDL dataset