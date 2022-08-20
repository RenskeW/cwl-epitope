#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

requirements:
- class: ScatterFeatureRequirement # because some steps are scattered
- class: StepInputExpressionRequirement # because there are JavaScript expressions in the workflow
- class: SubworkflowFeatureRequirement # because workflow contains subworkflow (generate_hhm)

inputs: 
  sabdab_summary_file: File
  biodl_train_dataset: File
  biodl_test_dataset: File
  hhblits_db_dir: Directory
  hhblits_db_name: string
  pdb_search_api_query: File

outputs: 
  model_output:
    type: File
    outputSource: train_epitope_prediction_model/train_log
  # combined_labels:
  #   type: Directory
  #   outputSource: combine_labels/labels_combined
  # combined_features:
  #   type: Directory
  #   outputSource: combine_features/combined_features
  # hhm_features:
  #   type: File[]
  #   outputSource: generate_hhm/hhm_file_array
  # psp19_features:
  #   type: Directory
  #   outputSource: generate_psp19/psp19_features
  # pc7_features:
  #   type: Directory
  #   outputSource: generate_pc7/pc7_features

steps:
  run_pdb_query:
    in:
      pdb_search_query: pdb_search_api_query
    out:
      [ processed_response ]
    run: ./tools/pdb_query.cwl
    doc: |
      "Use PDB search API to run a query on the Protein Data Bank. Returns .txt file with comma-separated PDB IDs which satisfy the query requirements.
      See https://search.rcsb.org/index.html#search-api for a tutorial."

  download_pdb_files:
    in: 
      input_file: run_pdb_query/processed_response 
      mmcif_format: { default: True }
      pdb_format: { default: True }
    out:
      [ pdb_files ]
    run: ./tools/pdb_batch_download.cwl
  
  decompress_pdb_files:
    in:
      in_gz: download_pdb_files/pdb_files
    out: [ out_cif, out_pdb ]
    run: ./tools/decompress.cwl
    doc: "Decompress files using gzip"

  generate_dssp_labels:
    in:
      pdb_files: decompress_pdb_files/out_pdb # change this later
      rsa_cutoff: { default :  0.06 }
    out:
      [ dssp_output_files ]
    run: ./tools/dssp.cwl
    doc: "Use DSSP to extract secondary structure and solvent accessibility from PDB files."

  generate_ppi_labels:
    in:
      mmcif_files: decompress_pdb_files/out_cif 
      train_dataset: biodl_train_dataset
      test_dataset: biodl_test_dataset
    out:
      [ ppi_fasta_files ]
    run: ./tools/ppi_annotations.cwl
    doc: "Extract ppi annoatations from BioDL. This step is partly emulated."
  
  preprocess_sabdab_data:
    doc: Extract antigen chains from SAbDab summary file.
    in:
      sabdab_summary_file: sabdab_summary_file # change this?
    out:
      [ processed_summary_file ]
    run: ./tools/process_sabdab.cwl

  generate_epitope_labels:
    in: 
      mmcif_files: decompress_pdb_files/out_cif # change this later
      sabdab_processed_file: preprocess_sabdab_data/processed_summary_file
    out:
      [ epitope_fasta_dir ]
    run: ./tools/epitope_annotations.cwl
    doc: "Extract epitope annotations from PDB files."

  combine_labels:
    doc: Combine labels into 1 file per protein sequence.
    run: ./tools/combine_labels.cwl
    in:
      epitope_directory: generate_epitope_labels/epitope_fasta_dir
      ppi_directory: generate_ppi_labels/ppi_fasta_files
      dssp_directory: generate_dssp_labels/dssp_output_files
    out: 
      [ labels_combined ]
  
  generate_pc7:
    doc: Calculate PC7 features for each residue in each protein sequence.
    run: ./tools/pc7_inputs.cwl # to do: adapt tool so it takes directory of fasta files as input
    in: 
      fasta: generate_ppi_labels/ppi_fasta_files 
    out:
      [ pc7_features ]  

  generate_psp19:
    label: Calculate PSP19 features for each residue in each protein sequence.
    run: ./tools/psp19_inputs.cwl
    in:
      fasta: generate_ppi_labels/ppi_fasta_files
    out:
      [ psp19_features ]

  generate_hhm:
    in:
      query_sequences: 
        source: generate_ppi_labels/ppi_fasta_files # type Directory
        valueFrom: $(self.listing) # here type Directory is converted to File array
      hhblits_db_dir: hhblits_db_dir
      hhblits_db_name: hhblits_db_name
      hhblits_n_iterations: { default: 1 }
    out: [ hhm_file_array ]
    run:
      class: Workflow # this is a subworkflow as a workaround because generate_ppi_labels/ppi_fasta_files is Directory while run_hhblits takes File
      inputs:
        query_sequences: File[] # file array
        hhblits_db_dir: Directory
        hhblits_db_name: string
        hhblits_n_iterations: int
      outputs:
        hhm_file_array:
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
          scatter: protein_query_sequence # File[] --> File
          run: ./tools/hhm_inputs_scatter.cwl
  combine_features:
    in: 
      input_sequences: generate_ppi_labels/ppi_fasta_files
      pc7_features: generate_pc7/pc7_features
      psp19_features: generate_psp19/psp19_features
      hhm_features: generate_hhm/hhm_file_array # file array, combine_features.cwl converts it to directory
    out: [ combined_features ]
    run: ./tools/combine_features.cwl  
  
  train_epitope_prediction_model: # This step incorporates both training and prediction, not sure if this is the case in the real workflow.
    in: # in the real workflow, the configuration file would be generated as part of the workflow as well
      input_features: combine_features/combined_features
      input_labels: combine_labels/labels_combined
    out: 
      [ train_log ] 
    run: ./tools/train_epitope_model.cwl
    doc: |
      "Predict epitope residues using a multi-task learning approach. This step is not real yet."  