#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

requirements:
- class: ScatterFeatureRequirement # because some steps are scattered
- class: StepInputExpressionRequirement # because there are JavaScript expressions in the workflow
- class: SubworkflowFeatureRequirement # because workflow contains subworkflow (generate_hhm)

inputs: 
  # epitope_directory: Directory
  # ppi_directory: Directory
  # dssp_directory: Directory
  # fasta_dir: Directory
  sabdab_summary_file: File
  # pdb_ids: File
  # mmcif_directory: Directory
  biodl_train_dataset: File
  biodl_test_dataset: File
  # decompressed_pdb_files: Directory 
  # mmcif_directory_epitope: Directory
  hhblits_db_dir: Directory
  hhblits_db_name: string
  hhblits_n_iterations: int
  pdb_search_api_query: File
  # test_in_gz: File[]

outputs: []

steps:
  run_pdb_query:
    label: "Run pdb query via search API"
    in:
      pdb_search_query: pdb_search_api_query
    out:
      [ processed_response ]
    run: ./tools/pdb_query.cwl
    doc: |
      "Use PDB search API to run a query on the Protein Data Bank. Returns .txt file with comma-separated PDB IDs which satisfy the query requirements.
      See https://search.rcsb.org/index.html#search-api for a tutorial."

  download_pdb_files:
    label: Download PDB entries in pdb format
    in: 
      input_file: run_pdb_query/processed_response 
      mmcif_format: { default: True }
      pdb_format: { default: True }
    out:
      [ pdb_files ]
    run: ./tools/pdb_batch_download.cwl
  
  decompress_pdb_files:
    label: Decompress using gzip
    in:
      in_gz: download_pdb_files/pdb_files
    out: [ out_cif, out_pdb ]
    run: ./tools/decompress.cwl

  generate_dssp_labels:
    in:
      pdb_files: decompress_pdb_files/out_pdb # change this later
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

  combine_labels:
    label: Combine labels into 1 file per protein sequence.
    run: ./tools/combine_labels.cwl
    in:
      epitope_directory: generate_epitope_labels/epitope_fasta_dir
      ppi_directory: generate_ppi_labels/ppi_fasta_files
      dssp_directory: generate_dssp_labels/dssp_output_files
    out: 
      [ labels_combined ]
  
  generate_pc7:
    label: Calculate PC7 features for each residue in each protein sequence.
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

  generate_hhm:
    in:
      query_sequences: 
        source: generate_ppi_labels/ppi_fasta_files # type Directory
        valueFrom: $(self.listing) # here type Directory is converted to File array
      hhblits_db_dir: hhblits_db_dir
      hhblits_db_name: hhblits_db_name
      hhblits_n_iterations: hhblits_n_iterations
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