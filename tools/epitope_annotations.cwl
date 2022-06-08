#!/usr/bin/env cwl-runner

cwlVersion: v1.2 
class: CommandLineTool

baseCommand: python3

hints:
  # DockerRequirement:
  #   dockerPull: quay.io/briansanderson/biopython-sklearn@sha256:e14acfb71f11046236ce471b0cd2acaa0f228bd3d7a420f9cdc827cd5f3d2701
  SoftwareRequirement:
    packages:
      pandas:
        specs: [ https://anaconda.org/conda-forge/pandas ]
        version: [ "1.2.4" ]
      # biopython:
      #   specs: [ https://pypi.org/project/biopython/ ]
      #   version: [ "1.78" ]
      python:
        version: [ "3.9.1" ]

arguments:
- $(inputs.script.path)
- $(inputs.mmcif_directory.path)
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
      path: ./epitope_annotation_pipeline.py
#   mmcif_directory:
#     type: File
#     default:
#       class: File
#       path: ../data/1am2.cif
  mmcif_directory:
    type: Directory
    default:
      class: Directory
      path: ../data/test_set/mmcif_directory/epitope_proteins
  sabdab_processed_file: 
    type: File
    default:
      class: File
      path: /Users/renskedewit/Documents/Bioinformatics_Systems_Biology/CWLproject/learn-git/epitope_annotation/SAbDab_protein_antigens_PDB_chains.csv
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

# outputs: []
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