#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Operation
label: NIAA abstract workflow
doc: |
  Input feature generation for OPUS-TASS.

# inputs:
#   #### Inputs: file with fasta sequences ####
  
#   fasta_path: File

# outputs:
#   wf_pc7_out:
#     type: File[]
#     outputSource: generate_pc7/pc7_features
#   # wf_psp19_out:
#   #   type: File[]
#   #   outputSource: generate_psp19/psp19
#   # wf_pssm_out:
#   #   type: File
#   #   outputSource: generate_pssm/pssm



# ############## INPUT FEATURE GENERATION ################
# steps:  
#   #### Generate PC7 features ####
#   generate_pc7:
#     run: pc7_inputs.cwl
#     in:
#       fasta: fasta_path     
#     out: [pc7_features]    

  #### Generate PSP19 features ####
  # generate_psp19:
  #   run:
  #     class: Operation

  #     inputs: [fasta_path]
  #     outputs: 
  #       psp19: File[]

  #### Generate PSSM profiles ####
  # generate_pssm:
  #   run:
  #     class: Operation
  #     inputs: [fasta_path]
  #     outputs: 
  #       pssm: File[]



#### Generate HHM profiles (HHBlits) ####

#### Concatenate pssm, hhm, psp19, pc7 into 1 input file ####


######### OPUS-TASS TRAINING/PREDICTIONS #############

