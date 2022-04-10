#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

inputs: # add SAbDab, BioDL & PDB
  fasta_path: 
    type: File
    default:
      class: File
      location: /scistor/informatica/hwt330/cwl-epitope/test.fasta

  # add location of cwl-epitope directory since tool paths are relative!

outputs:
  # predictions: 
  #   type: Directory # I assume that each protein has 1 file containing predictions for all tasks
  #   outputSource: opus_tass/predictions
  pc7_features:
    type: Directory
    outputSource: generate_pc7/pc7_features
  psp19_features:
    type: Directory
    outputSource: generate_psp19/psp19_features
  hhm_features:
    type: Directory
    outputSource: generate_hhm/hhm_profiles


steps:  
  ############## INPUT FEATURE GENERATION ################
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
      Generates PC7 features per residue. Output stored in 1 file per protein sequence.       
  
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
       
  generate_hhm:
    label: "Generate HHM profile"
    run: ./tools/hhm_inputs.cwl
    in: 
      protein_query_sequences: fasta_path
      database: 
        default: 
          class: Directory
          location: /scistor/informatica/hwt330/hhblits/databases
      script:
        default:
          class: File
          location: /scistor/informatica/hwt330/cwl-epitope/tools/run_hhblits.py
      database_name: { default: "pdb70" } # for iterative searching, uniclust30 should be used!
      #n_iterations (add later)
      output_directory_name: { default: "hhm_features" }
    out:
      [hhm_profiles]
    doc: |
      Builds multiple sequence alignment using HHBlits for every protein sequence. Output stored in 1 .hhm file per sequence.
      # format: https://github.com/soedinglab/hh-suite/wiki#file-formats .hhm
    


  
  
  ############## LABEL GENERATION ################
  