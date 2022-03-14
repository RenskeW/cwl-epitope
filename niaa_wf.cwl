#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

inputs:
  #### Inputs: file with fasta sequences ####
  
  #fasta_path: File
  word: string
  message_file: string

outputs:
  wf_test_out:
    type: File
    outputSource: test/test_output # why does this not work?



############## INPUT FEATURE GENERATION ################
steps:  
  test: # This is a test step to see if I understand how to make a workflow, delete hello.cwl and hello-job.yml later
    run: hello.cwl
    in:
      message: word
      out_file: message_file
    out: [test_output]

#   pc7:
#     run: pc7_inputs.cwl
#     in:
#       script: {get_pc7_inputs.py}
#       fasta: fasta_path
      
#     out:
#       #[pc7_features??]    

#### Generate PSP19 features ####

#### Generate PC7 features ####



      



#### Generate PSSM profiles ####

#### Generate HHM profiles (HHBlits) ####

#### Concatenate pssm, hhm, psp19, pc7 into 1 input file ####


######### OPUS-TASS TRAINING/PREDICTIONS #############

