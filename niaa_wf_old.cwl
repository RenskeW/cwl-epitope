#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs:
  #### Inputs: file with fasta sequences ####
  fasta_path: File


outputs:
  # pc7_features, psp19_features & hhm_features can be replaced later by opus_tass inputs
  pc7_features: 
    type: Directory
    outputSource: generate_pc7/pc7_features
  psp19_features:
    type: Directory
    outputSource: generate_psp19/psp19_features
  

############## INPUT FEATURE GENERATION ################
steps:  
  generate_pc7:
    label: "Generate PC7"
    run: ./tools/pc7_inputs.cwl
    in:
      fasta: fasta_path
      outdir: 
        default: "pc7_features" # Now defined as string because directory does not exist yet    
    out:
      [pc7_features]
    doc: |
      Generates PC7 features per residue. Output stored in 1 file per sequence.
       
  generate_psp19:
    label: "Generate PSP19"
    run: ./tools/psp19_inputs.cwl
    in:
      fasta: fasta_path
      outdir:
        default: "psp19_features" # Now defined as string because directory does not exist yet
    out:
      [psp19_features]
    doc: |
      Generates PSP19 features per residue. Output stored in 1 file per sequence.
       
  combine_features:
    in: 
      fasta: fasta_path
    out: [features]
    run:
      class: Operation
      inputs:
        fasta: 
          type: Any 
      outputs:
        features: 
          type: Directory
        
    doc: |
      "Combines PC7, PSP19, HHM & PSSM input features into 1 file per fasta sequence."
  

  




      



#### Generate PSSM profiles ####

#### Generate HHM profiles (HHBlits) ####

#### Concatenate pssm, hhm, psp19, pc7 into 1 input file ####


######### OPUS-TASS TRAINING/PREDICTIONS #############

