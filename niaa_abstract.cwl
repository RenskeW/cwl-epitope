#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs: 
  pdb_query: string?
  biodl_train_dataset: File
  biodl_test_dataset: File
  sabdab_summary_file: File # manual download

outputs:
  predictions: 
    type: Directory # I assume that each protein has 1 file containing predictions for all tasks
    outputSource: train_epitope_prediction_model/predictions

steps:  
  run_pdb_query:
    label: "Run pdb query via search API"
    in:
      query: pdb_query
    out:
      [ pdb_ids ]
    run:
      class: Operation
      inputs:
        query:
          type: string?
      outputs:
        pdb_ids:
          type: File # comma-separated file
    doc: |
      "Use PDB search API to run a query on the Protein Data Bank. Returns .txt file with comma-separated PDB IDs which satisfy the query requirements.
      See https://search.rcsb.org/index.html#search-api for a tutorial."
  download_pdb_files:
    in: 
      input_file: run_pdb_query/pdb_ids
      script:
        default:
          class: File
          location: ./tools/pdb_batch_download.sh # it should be path but then it doesn't work: [step download_pdb_files] Cannot make job: Invalid job input record: Anonymous file object must have 'contents' and 'basename' fields.
    out:
      [ pdb_files, mmcif_files ]
    run: ./tools/pdb_batch_download.cwl
    doc: |
      "Batch download of PDB entries (in .pdb & mmcif format) which were returned by the PDB search API. 
      See https://www.rcsb.org/docs/programmatic-access/batch-downloads-with-shell-script"
  decompress_pdb_files:
    in:
      compressed_files: download_pdb_files/pdb_files
    out:
      [ decompressed_pdb_files ]
    run:
      class: Operation
      inputs:
        compressed_files:
          type: File[]
      outputs:
        decompressed_pdb_files:
          type: Directory
    doc: |
      "Decompress the files in the unzipped directory."
  # download_mmcif_files:
  #   in:
  #     pdb_ids: run_pdb_query/pdb_ids
  #     download_format: # which format should be downloaded from the pdb?
  #       default: "mmcif"
  #   out:
  #     [ mmcif_files_compressed ] # is this the unzipped directory already?
  #   run: 
  #     class: Operation
  #     inputs:
  #       pdb_ids:
  #         type: File
  #         label: ".txt file with comma-separated PDB ids"
  #       download_format:
  #         type: string
  #         default: "mmcif"
  #         label: "Format of PDB downloads"
  #     outputs: 
  #       mmcif_files_compressed:
  #         type: Directory
  #         label: "Directory of compressed pdb files with .cif.gz extension"
  #   doc: |
  #     "Batch download of PDB entries (in .pdb format) which were returned by the PDB search API. 
  #     See https://www.rcsb.org/docs/programmatic-access/batch-downloads-with-shell-script"
  decompress_mmcif_files:
    in:
      compressed_files: download_pdb_files/mmcif_files
    out:
      [ decompressed_mmcif_files ]
    run:
      class: Operation
      inputs:
        compressed_files:
          type: File[]
      outputs:
        decompressed_mmcif_files:
          type: Directory
    doc: |
      "Decompress the mmcif files in the unzipped directory."
  ############## LABEL GENERATION ################
  generate_dssp_labels:
    in:
      pdb_entries: decompress_pdb_files/decompressed_pdb_files
    out:
      [ dssp_output_files ]
    run:
      class: Operation
      inputs: 
        pdb_entries:
          type: Directory
        # out_dir:
        #   type: string
        # rsa_cutoff:
        #   type: string
      outputs:
        dssp_output_files:
          type: Directory
  generate_ppi_labels:
    in:
      biodl_train: biodl_train_dataset
      biodl_test: biodl_test_dataset
      mmcif_dir: decompress_mmcif_files/decompressed_mmcif_files
    out:
      [ ppi_fasta_files ]
    run:
      class: Operation
      inputs:
        biodl_train:
          type: File
        biodl_test:
          type: File
        mmcif_dir:
          type: Directory
      outputs:
        ppi_fasta_files:
          type: Directory
  preprocess_sabdab_data:
    in:
      sabdab_summary_file: sabdab_summary_file
    out:
     [ processed_summary_file ]
    run:
      class: Operation
      inputs:
        sabdab_summary_file:
          type: File
      outputs:
        processed_summary_file:
          type: File
  generate_epitope_labels:
    in: 
      mmcif_dir: decompress_mmcif_files/decompressed_mmcif_files
      sabdab_processed_file: preprocess_sabdab_data/processed_summary_file
    out:
      [ epitope_fasta_dir ]
    run:
      class: Operation
      inputs:
        mmcif_dir:
          type: Directory
        sabdab_processed_file:
          type: File
      outputs:
        epitope_fasta_dir:
          type: Directory
  combine_labels: # Ugly, but probably necessary to simplify input for OPUS-TASS. Need to know more details to make this more elegant.
    label: "Combine labels"
    in:
      epitope_dir: generate_epitope_labels/epitope_fasta_dir
      ppi_dir: generate_ppi_labels/ppi_fasta_files
      dssp_dir: generate_dssp_labels/dssp_output_files
    out:
      [ combined_labels, fasta_dir ]
    run:
      class: Operation
      inputs:
        epitope_dir:
          type: Directory
        ppi_dir: 
          type: Directory
        dssp_dir:
          type: Directory
      outputs:
        combined_labels:
          type: Directory
          label: "Directory with 1 file per training sequence"
        fasta_dir:
          type: Directory
          label: "Directory with fasta files for each train/test protein chain."
  ############## INPUT FEATURE GENERATION ################
  generate_pc7:
    label: "Generate PC7"
    in:
      fasta: combine_labels/fasta_dir
      # outdir: 
      #   default: "pc7_features" # Now defined as string because directory does not exist yet    
    out:
      [pc7_features]
    run:
      class: Operation
      inputs: 
        fasta:
          type: Directory
      outputs:
        pc7_features:
          type: Directory
    doc: |
      Generates PC7 features per residue. Output stored in 1 file per sequence.               
  generate_psp19:
    label: "Generate PSP19"
    # run: ./tools/psp19_inputs.cwl
    in:
      fasta: combine_labels/fasta_dir
    out:
      [psp19_features]
    run:
      class: Operation
      inputs:
        fasta:
          type: Directory
      outputs:
        psp19_features:
          type: Directory
    doc: |
      "Generates PSP19 features per residue. Output stored in 1 file per sequence."       
  generate_hhm:
    label: "Generate HHM profile"
    in:
      fasta: combine_labels/fasta_dir
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
      fasta: combine_labels/fasta_dir
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
      labels: combine_labels/combined_labels
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

  