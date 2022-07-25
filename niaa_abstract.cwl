#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow


requirements:
- class: ScatterFeatureRequirement # because some steps are scattered
- class: StepInputExpressionRequirement # because there are JavaScript expressions in the workflow
- class: SubworkflowFeatureRequirement # because workflow contains subworkflow (generate_hhm)

inputs: 
  pdb_query: string?
  biodl_train_dataset: File
  biodl_test_dataset: File
  sabdab_summary_file: File # manual download
  pdb_search_api_query: File
  hhblits_db_dir: Directory
  hhblits_db_name: string

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
    label: "Combine features"
    in: 
      fasta: generate_ppi_labels/ppi_fasta_files
      pc7: generate_pc7/pc7_features
      psp19: generate_psp19/psp19_features
      hhm: generate_hhm/hhm_file_array
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
          type: File[] 
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

  