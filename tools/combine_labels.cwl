#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

baseCommand: python3

# hints:
#   DockerRequirement:
#     dockerPull: amancevice/pandas:1.3.4-slim
#   SoftwareRequirement:
#     packages:
#       pandas:
#         specs: [ https://anaconda.org/conda-forge/pandas ]
#         version: [ "1.3.4" ]
#       python:
#         version: [ "3.9.7" ]

arguments:
- $(inputs.script.path)
- $(inputs.epitope_directory.path)
- $(inputs.ppi_directory.path)
- $(inputs.dssp_directory.path)
- "--outdir"
- $(inputs.output_directory)

inputs:
  script:
    type: File
    default:
      class: File
      location: ./combine_labels.py
  epitope_directory:
    type: Directory
    label: Directory with FASTA files with epitope annotations.
  ppi_directory:
    type: Directory
    label: Directory with FASTA files with PPI annotations.
  dssp_directory:
    type: Directory
    label: Directory with DSSP output files.
  output_directory:
    type: string
    default: "./combined_labels"

outputs:
  labels_combined:
    type: Directory
    outputBinding:
      glob: $(inputs.output_directory)




