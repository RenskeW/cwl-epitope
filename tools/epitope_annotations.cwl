#!/usr/bin/env cwl-runner

cwlVersion: v1.2 
class: CommandLineTool

baseCommand: python3

# label: Extract epitope annotations from mmCIF files.

requirements:
  InlineJavascriptRequirement: {}
  InitialWorkDirRequirement: # the script takes a directory as input
    listing: |
      ${
           return [{"entry": {"class": "Directory", "basename": "mmcif_directory", "listing": inputs.mmcif_files}, "writable": true}]
       }

doc: |
  Runs Python script which takes directory of mmCIF files as input and outputs directory of FASTA files with protein sequence + epitope annotations.

# hints:
#   # DockerRequirement:
#   #   dockerImageId: pdbecif-pandas:20220620
#   #   dockerFile: |                                                               
#   #     FROM docker.io/debian:stable-slim                                                                                                                         
#   #     RUN apt-get update && apt-get install -y --no-install-recommends python3-pip
#   #     RUN python3 -m pip install PDBeCif pandas  
#   SoftwareRequirement:
#     packages:
#       pandas:
#         specs: [ https://anaconda.org/conda-forge/pandas ]
#         version: [ "1.2.4" ]
#       python:
#         version: [ "3.9.1" ]
#       pdbecif:
#         specs: [ https://pypi.org/project/PDBeCif/ ]
#         version: [ "1.5" ]

arguments:
- $(inputs.script.path)
- "mmcif_directory"
- $(inputs.sabdab_processed_file.path)
- "--fasta_directory"
- $(inputs.fasta_output_dir)
- "--df_directory"
- $(inputs.df_output_dir)

inputs:
  script:
    type: File
    default:
      class: File
      location: ./epitope_annotation_pipeline.py
  mmcif_files:
    type: File[]
    label: mmCIF file array
    default: 
    - class: File
      location: ../data/test_mmcif_dir/5js9.cif
  sabdab_processed_file: 
    type: File
    label: ".csv file with PDB entries with associated H, L and antigen chain."
    default:
      class: File
      location: /Users/renskedewit/Documents/Bioinformatics_Systems_Biology/CWLproject/learn-git/epitope_annotation/SAbDab_protein_antigens_PDB_chains.csv

  fasta_output_dir:
    type: string
    default: "./epitope_fasta"
  df_output_dir:
    type: string
    default: "./epitope_df"

outputs:
  epitope_fasta_dir:
    type: Directory
    outputBinding:
      glob: $(inputs.fasta_output_dir)
  epitope_df_dir:
    type: Directory
    outputBinding:
      glob: $(inputs.df_output_dir)

s:dateCreated: 2022-05-30
s:license: <?>

s:mainEntity:
  class: s:SoftwareApplication
  s:author:
  - class: s:Person
    s:name: "Katharina Waury"
  s:dateCreated: 2022-02-10
  s:programmingLanguage: Python
  s:license: <?>
  s:about: "Script which extracts epitope annotations and dataframes from mmCIF files."

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/

$schemas:
- https://schema.org/version/latest/schemaorg-current-https.rdf
- https://edamontology.org/EDAM_1.25.owl