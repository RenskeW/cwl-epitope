#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs: 
  epitope_directory: Directory
  ppi_directory: Directory
  dssp_directory: Directory
  fasta_file: File

outputs: 
  all_labels:
    type: Directory
    outputSource: combine_labels/labels_combined
  pc7_inputs:
    type: Directory
    outputSource: generate_pc7/pc7_features

steps:
  combine_labels:
    label: Combine labels into 1 file per protein sequence.
    run: ./tools/combine_labels.cwl
    in:
      epitope_directory: epitope_directory
      ppi_directory: ppi_directory
      dssp_directory: dssp_directory
    out: 
      [ labels_combined ]
  generate_pc7:
    label: Calculate PC7 features for each residue in each protein sequence.
    run: ./tools/pc7_inputs.cwl # to do: adapt tool so it takes directory of fasta files as input
    in: 
      fasta: fasta_file # change this to dssp (or PPI?) directory
    out:
      [ pc7_features ]
    




