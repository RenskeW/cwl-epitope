#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

# requirements:
#   ScatterFeatureRequirement: {}

inputs: 
  epitope_directory: Directory
  ppi_directory: Directory
  dssp_directory: Directory
  fasta_dir: Directory
  sabdab_summary_file: File
  pdb_ids: File
  mmcif_directory: Directory
  biodl_train_dataset: File
  biodl_test_dataset: File
  decompressed_pdb_files: Directory 
  mmcif_directory_epitope: Directory
  hhblits_db_dir: Directory
  hhblits_db_name: string
  hhblits_n_iterations: int

outputs:
  pdb_files: # the compressed pdb files
    type: Directory
    outputSource: download_pdb_files/pdb_files
  mmcif_files: # the compressed pdb files
    type: Directory
    outputSource: download_mmcif_files/pdb_files
  all_labels:
    type: Directory
    outputSource: combine_labels/labels_combined
  pc7_inputs:
    type: Directory
    outputSource: generate_pc7/pc7_features
  psp19_inputs:
    type: Directory
    outputSource: generate_psp19/psp19_features

  # predictions: 
  #   type: Directory # I assume that each protein has 1 file containing predictions for all tasks
  #   outputSource: opus_tass/predictions

steps:
  # run_pdb_query:
  download_pdb_files:
    label: Download PDB entries in pdb format
    in: 
      input_file: pdb_ids # change this later
      mmcif_format: { default: False }
      pdb_format: { default: True }
    out:
      [ pdb_files ]
    run: ./tools/pdb_batch_download.cwl
  
  download_mmcif_files:
    label: Download PDB entries in mmCIF format
    in:
      input_file: pdb_ids # change this later
      mmcif_format: { default: True }
    out:
     [ pdb_files ]
    run: ./tools/pdb_batch_download.cwl

  generate_dssp_labels:
    in:
      source_dir: decompressed_pdb_files # change this later
      rsa_cutoff: { default :  0.06 }
      # extension (might need .ent instead of .pdb???)
    out:
      [ dssp_output_files ]
    run: ./tools/dssp.cwl

  generate_ppi_labels:
    in:
      mmcif_directory: mmcif_directory
      train_dataset: biodl_train_dataset
      test_dataset: biodl_test_dataset
    out:
      [ ppi_fasta_files ]
    run: ./tools/ppi_annotations.cwl 
  
  preprocess_sabdab_data:
    label: Extract antigen chains from SAbDab summary file.
    in:
      sabdab_summary_file: sabdab_summary_file # change this?
    out:
      [ processed_summary_file ]
    run: ./tools/process_sabdab.cwl

  generate_epitope_labels:
    in: 
      mmcif_directory: mmcif_directory_epitope # change this later
      sabdab_processed_file: preprocess_sabdab_data/processed_summary_file
    out:
      [ epitope_fasta_dir ]
    run: ./tools/epitope_annotations.cwl

  combine_labels:
    label: Combine labels into 1 file per protein sequence.
    run: ./tools/combine_labels.cwl
    in:
      epitope_directory: epitope_directory
      ppi_directory: generate_ppi_labels/ppi_fasta_files
      dssp_directory: generate_dssp_labels/dssp_output_files
    out: 
      [ labels_combined ]
  
  generate_pc7:
    label: Calculate PC7 features for each residue in each protein sequence.
    run: ./tools/pc7_inputs.cwl # to do: adapt tool so it takes directory of fasta files as input
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

  # generate_hhm: # find a way to convert Directory into file array
  #   label: "Generate HHM profile"
  #   in:
  #     protein_query_sequence: generate_ppi_labels/ppi_fasta_files
  #     database: hhblits_db_dir
  #     database_name: hhblits_db_name
  #     n_iterations: { default: 1 } # this is not correct, change value
  #   out: [ hhm_file ]
  #   scatter: protein_query_sequence
  #   run: ./tools/hhm_inputs_scatter.cwl
  #   doc: |
  #     "Generates HHM profiles with HHBlits. Output stored in 1 file per sequence."  
