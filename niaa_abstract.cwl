#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs: # SAbDab, BioDL & PDB
  SAbDab: Directory # I assume these are directories of .pdb files
  BioDL: Directory
  pdb: Directory

outputs:
  predictions: 
    type: Directory # I assume that each protein has 1 file containing predictions for all tasks
    outputSource: opus_tass/predictions


steps:  
  extract_fasta:
    label: "Extract fasta sequences"
    in:
      pdb: SAbDab
    out:
      [fasta_path]
    run:
      class: Operation
      inputs:
        pdb:
          type: Directory # I assume
      outputs:
        fasta_path:
          type: File
  
  ############## INPUT FEATURE GENERATION ################
  generate_pc7:
    label: "Generate PC7"
    in:
      fasta: extract_fasta/fasta_path
      # outdir: 
      #   default: "pc7_features" # Now defined as string because directory does not exist yet    
    out:
      [pc7_features]
    run:
      class: Operation
      inputs: 
        fasta:
          type: File
      outputs:
        pc7_features:
          type: Directory
    doc: |
      Generates PC7 features per residue. Output stored in 1 file per sequence.
       
  generate_psp19:
    label: "Generate PSP19"
    # run: ./tools/psp19_inputs.cwl
    in:
      fasta: extract_fasta/fasta_path
    out:
      [psp19_features]
    run:
      class: Operation
      inputs:
        fasta:
          type: File
      outputs:
        psp19_features:
          type: Directory
    doc: |
      "Generates PSP19 features per residue. Output stored in 1 file per sequence."
       
  generate_hhm:
    label: "Generate HHM profile"
    in:
      fasta: extract_fasta/fasta_path
      # hhm_db: uniclust30 # Is this correct???
      #number of iterations for hhm
      # anything else?
    out:
      [hhm_features]
    run:
      class: Operation
      inputs: 
        fasta: # not sure if this is necessary, it could just be filenames as well
          type: File
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
      fasta: extract_fasta/fasta_path
      pc7: generate_pc7/pc7_features
      psp19: generate_psp19/psp19_features
      hhm: generate_hhm/hhm_features
    out: [features]
    run:
      class: Operation
      inputs:
        fasta: 
          type: File
        pc7:
          type: Directory
        psp19:
          type: Directory
        hhm:
          type: Directory 
      outputs:
        features: 
          type: Directory
        
    doc: |
      "Combines PC7, PSP19, & HHM input features into 1 file per fasta sequence."
  
  ############## LABEL GENERATION ################
  epitope_annotation:
    label: "Epitope residue annotation"
    in:
      pdb: SAbDab
    out:
      [epitopes]
    run:
      class: Operation
      inputs:
        pdb:
          type: Directory # I assume
      outputs:
        epitopes:
          type: File # I assume
    doc: |
      "Extracts from pdb file which residues are epitopes."

  epi_ss_sa_annotation:
    label: "Epitope Secondary structure & SA annotation"
    in:
      pdb: SAbDab
    out:
      [epi_ss_sa]
    run:
      class: Operation
      inputs:
        pdb:
          type: Directory # I assume
      outputs:
        epi_ss_sa:
          type: Directory # I assume
    doc: |
      "Calculates secondary structure and surface accessibility for each residue in each SAbDab protein."
  
  ppi_annotation:
    label: "PPI annotation"
    in:
      pdb: BioDL
    out:
      [biodl_ppi]
    run:
      class: Operation
      inputs:
        pdb:
          type: Directory # I assume
      outputs: 
        biodl_ppi:
          type: Directory # I assume
    doc: |
      "Calculates PPI annotations for each residue in each BioDL protein."

  biodl_ss_sa_annotation: # Would this be the same CommandLineTool as for epi_ss_sa_annotation?
    label: "PDB Secondary structure & SA annotation"
    in:
      pdb: BioDL
    out:
      [biodl_ss_sa]
    run:
      class: Operation
      inputs:
        pdb:
          type: Directory # I assume
      outputs:
        biodl_ss_sa:
          type: Directory # I assume
    doc: |
      "Calculates secondary structure and surface accessibility for each residue in each PDB protein."
    
  pdb_ss_sa_annotation: # Would this be the same CommandLineTool as for epi_ss_sa_annotation?
    label: "PDB Secondary structure & SA annotation"
    in:
      pdb: pdb
    out:
      [pdb_ss_sa]
    run:
      class: Operation
      inputs:
        pdb:
          type: Directory # I assume
      outputs:
        pdb_ss_sa:
          type: Directory # I assume
    doc: |
      "Calculates secondary structure and surface accessibility for each residue in each PDB protein."
  
  combine_labels: # Ugly, but probably necessary to simplify input for OPUS-TASS. Need to know more details to make this more elegant.
    label: "Combine labels"
    in:
      epitopes: epitope_annotation/epitopes
      epi_ss_sa: epi_ss_sa_annotation/epi_ss_sa
      ppi: ppi_annotation/biodl_ppi
      biodl_ss_sa: biodl_ss_sa_annotation/biodl_ss_sa
      pdb_ss_sa: pdb_ss_sa_annotation/pdb_ss_sa
    out:
      [labels]
    run:
      class: Operation
      inputs:
        epitopes:
          type: Any # Not sure
        epi_ss_sa:
          type: Directory # I assume
        ppi:
          type: Directory # I assume
        biodl_ss_sa:
          type: Directory # I assume
        pdb_ss_sa:
          type: Directory # I assume
      outputs:
        labels:
          type: Directory # I assume
      doc: |
        "Combines all labels into 1 file per protein."
    
  ############## MULTITASK TRAINING/PREDICTION ################
  opus_tass: # This step incorporates both training and prediction, not sure if this is the case in the real workflow.
    label: "OPUS-TASS multi-task epitope prediction"
    in:
      features: combine_features/features
      labels: combine_labels/labels
    out: 
      [predictions] # i assume???
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
      "Use OPUS-TASS to predict epitope residues using a multi-task learning approach."
  