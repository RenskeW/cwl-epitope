#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs: 
  epitope_directory: Directory
  ppi_directory: Directory
  dssp_directory: Directory
  fasta_dir: Directory


outputs: 
  all_labels:
    type: Directory
    outputSource: combine_labels/labels_combined
  pc7_inputs:
    type: Directory
    outputSource: generate_pc7/pc7_features
  psp19_inputs:
    type: Directory
    outputSource: generate_psp19/psp19_features

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
    run: ./tools/pc7_inputs.cwl 
    in: 
      fasta: fasta_dir 
    out:
      [ pc7_features ]
  generate_psp19:
    label: Calculate PSP19 features for each residue in each protein sequence.
    run: ./tools/psp19_inputs.cwl
    in:
      fasta: fasta_dir
    out:
      [ psp19_features ]
    




