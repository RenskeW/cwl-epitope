#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs: 
  pdb_query: string?
  biodl_train_dataset: File
  biodl_test_dataset: File
  sabdab_summary_file: File # manual download
  pdb_search_api_query: File

outputs:
  predictions: 
    type: Directory # I assume that each protein has 1 file containing predictions for all tasks
    outputSource: train_epitope_prediction_model/predictions

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
      script:
        default:
          class: File
          location: ./tools/pdb_batch_download.sh # it should be path but then it doesn't work: [step download_pdb_files] Cannot make job: Invalid job input record: Anonymous file object must have 'contents' and 'basename' fields.
    out:
      [ pdb_files ]
    run: ./tools/pdb_batch_download.cwl
    doc: |
      "Batch download of PDB entries (in .pdb & mmcif format) which were returned by the PDB search API. 
      See https://www.rcsb.org/docs/programmatic-access/batch-downloads-with-shell-script"
  decompress_pdb_files:
    label: Decompress using gzip
    in:
      in_gz: download_pdb_files/pdb_files
    out: [ out_cif, out_pdb ]
    run: ./tools/decompress.cwl
    doc: |
      "Decompress the files in the unzipped directory."

  ############## LABEL GENERATION ################
  generate_dssp_labels:
    in:
      pdb_files: decompress_pdb_files/out_pdb 
      rsa_cutoff: { default :  0.06 }
      # extension (might need .ent instead of .pdb???)
    out:
      [ dssp_output_files ]
    run: ./tools/dssp.cwl

  generate_ppi_labels:
    in:
      mmcif_files: decompress_pdb_files/out_cif
      train_dataset: biodl_train_dataset
      test_dataset: biodl_test_dataset
    out:
      [ ppi_fasta_files ]
    run: ./tools/ppi_annotations.cwl 
  
  preprocess_sabdab_data:
    label: Extract antigen chains from SAbDab summary file.
    in:
      sabdab_summary_file: sabdab_summary_file
    out:
      [ processed_summary_file ]
    run: ./tools/process_sabdab.cwl

  generate_epitope_labels:
    in: 
      mmcif_files: decompress_pdb_files/out_cif
      sabdab_processed_file: preprocess_sabdab_data/processed_summary_file
    out:
      [ epitope_fasta_dir ]
    run: ./tools/epitope_annotations.cwl

  combine_labels:
    label: Combine labels into 1 file per protein sequence.
    run: ./tools/combine_labels.cwl
    in:
      epitope_directory: generate_epitope_labels/epitope_fasta_dir
      ppi_directory: generate_ppi_labels/ppi_fasta_files
      dssp_directory: generate_dssp_labels/dssp_output_files
    out: 
      [ labels_combined ] # what to do about fasta_dir?
  ############## INPUT FEATURE GENERATION ################
  generate_pc7:
    label: Calculate PC7 features for each residue in each protein sequence.
    run: ./tools/pc7_inputs.cwl 
    in: 
      fasta: generate_ppi_labels/ppi_fasta_files
    out:
      [ pc7_features ]  
    doc: |
      Generates PC7 features per residue. Output stored in 1 file per sequence.             
    
  generate_psp19:
    label: Calculate PSP19 features for each residue in each protein sequence.
    run: ./tools/psp19_inputs.cwl
    in:
      fasta: generate_ppi_labels/ppi_fasta_files
    out:
      [ psp19_features ]
    doc: |
      "Generates PSP19 features per residue. Output stored in 1 file per sequence."  
  generate_hhm:
    label: "Generate HHM profile"
    in:
      fasta: generate_ppi_labels/ppi_fasta_files
      # hhm_db: uniclust30 # Is this correct???
      #number of iterations for hhm
      # anything else?
    out:
      [hhm_features]
    run:
      class: Operation
      inputs: 
        fasta: # not sure if this is necessary, it could just be filenames as well
          type: Directory
        # hhm_db:
        #   type: Any
      outputs:
        hhm_features:
          type: Directory
    doc: |
      "Generates HHM profiles with HHBlits. Output stored in 1 file per sequence."
  combine_features:
    label: "Combine features"
    in: 
      fasta: generate_ppi_labels/ppi_fasta_files
      pc7: generate_pc7/pc7_features
      psp19: generate_psp19/psp19_features
      hhm: generate_hhm/hhm_features
    out: [features]
    run:
      class: Operation
      inputs:
        fasta: 
          type: Directory
        pc7:
          type: Directory
        psp19:
          type: Directory
        hhm:
          type: Directory 
      outputs:
        features: 
          type: Directory        
  train_epitope_prediction_model: # This step incorporates both training and prediction, not sure if this is the case in the real workflow.
    label: "OPUS-TASS multi-task epitope prediction"
    in:
      features: combine_features/features
      labels: combine_labels/labels_combined
    out: 
      [ predictions ] # i assume???
    run:
      class: Operation
      inputs:
        features:
          type: Directory # I assume
        labels: 
          type: Directory # I assume
      outputs:
        predictions:
          type: Directory # I assume
    doc: |
      "Predict epitope residues using a multi-task learning approach."  

  