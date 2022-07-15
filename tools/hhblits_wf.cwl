#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

requirements:
  ScatterFeatureRequirement: {}

inputs:
  query_sequences: File[]
  hhblits_db_dir: Directory
  hhblits_db_name: string
  hhblits_n_iterations: int

outputs:
  hhm_array:
    type: File[]
    outputSource: run_hhblits/hhm_file

steps:
  run_hhblits:
    in:
      protein_query_sequence: query_sequences
      database: hhblits_db_dir
      database_name: hhblits_db_name
      n_iterations: hhblits_n_iterations
    out: [ hhm_file ]
    scatter: protein_query_sequence
    run: ./hhm_inputs_scatter.cwl
