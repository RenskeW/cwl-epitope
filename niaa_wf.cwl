#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

# requirements:
#   ScatterFeatureRequirement: {}

inputs: [] # add SAbDab, BioDL & PDB
  # fasta_path: 
  #   type: File
  #   default:
  #     class: File
  #     location: /scistor/informatica/hwt330/cwl-epitope/test.fasta
  # protein_ids:
  #   type: string[]
  #   default: [ "3tcl", "4hhb"]

outputs:
  pdb_files: # the compressed pdb files
    type: File[]
    outputSource: download_pdb_files/pdb_files
  mmcif_files: # the compressed pdb files
    type: File[]
    outputSource: download_pdb_files/mmcif_files
  # predictions: 
  #   type: Directory # I assume that each protein has 1 file containing predictions for all tasks
  #   outputSource: opus_tass/predictions

steps:
  # run_pdb_query:
  download_pdb_files:
    in: 
      input_file: 
        default:
          class: File
          location: ./tools/pdb_ids.txt # should be path
      script:
        default:
          class: File
          location: ./tools/pdb_batch_download.sh # it should be path but then it doesn't work: [step download_pdb_files] Cannot make job: Invalid job input record: Anonymous file object must have 'contents' and 'basename' fields.
    out:
      [ pdb_files, mmcif_files ]
    run: ./tools/pdb_batch_download.cwl
    
  # download_pdb:
  #   label: "Download structures from PDB"
  #   run: ./tools/mmcif_download.cwl
  #   in:
  #     pdb_id: protein_ids
  #   scatter: pdb_id
  #   out:
  #     [ pdb_file ] 
  # ############## INPUT FEATURE GENERATION ################
  # generate_pc7:
  #   label: "Generate PC7"
  #   run: ./tools/pc7_inputs.cwl
  #   in:
  #     fasta: fasta_path
  #     outdir: 
  #       default: "pc7_features" # Now defined as string because directory does not exist yet    
  #   out:
  #     [pc7_features]
  #   doc: |
  #     Generates PC7 features per residue. Output stored in 1 file per protein sequence.       
  
  # generate_psp19:
  #   label: "Generate PSP19"
  #   run: ./tools/psp19_inputs.cwl
  #   in:
  #     fasta: fasta_path
  #     outdir:
  #       default: "psp19_features" # Now defined as string because directory does not exist yet
  #   out:
  #     [psp19_features]
  #   doc: |
  #     Generates PSP19 features per residue. Output stored in 1 file per sequence.
       
  # generate_hhm:
  #   label: "Generate HHM profile"
  #   run: ./tools/hhm_inputs.cwl
  #   in: 
  #     protein_query_sequences: fasta_path
  #     database: 
  #       default: 
  #         class: Directory
  #         location: /scistor/informatica/hwt330/hhblits/databases
  #     script:
  #       default:
  #         class: File
  #         location: /scistor/informatica/hwt330/cwl-epitope/tools/run_hhblits.py
  #     database_name: { default: "pdb70" } # for iterative searching, uniclust30 should be used!
  #     #n_iterations (add later)
  #     output_directory_name: { default: "hhm_features" }
  #   out:
  #     [hhm_profiles]
  #   doc: |
  #     Builds multiple sequence alignment using HHBlits for every protein sequence. Output stored in 1 .hhm file per sequence.
  #     # format: https://github.com/soedinglab/hh-suite/wiki#file-formats .hhm
    


  
  
  # ############## LABEL GENERATION ################
  