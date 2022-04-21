#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool
baseCommand: python3

label: "Combine input features"

doc: |
  "Combines the input features for each protein sequence into 1 file per sequence. Output is stored in a new directory."

hints:
  DockerRequirement:
    dockerPull: amancevice/pandas:1.3.4-slim 
  SoftwareRequirement:
    packages:
      numpy:
        specs: [ https://anaconda.org/conda-forge/numpy ]
        version: [ "1.21.4" ]
      pandas:
        specs: [ https://anaconda.org/conda-forge/pandas ]
        version: [ "1.3.4" ]

arguments:
- $(inputs.script.path)
- $(inputs.input_sequences.path)
- $(inputs.hhm_features.path)
- $(inputs.pc7_features.path)
- $(inputs.psp19_features.path)
- "--outdir"
- ./$(inputs.outdir_name) # An output directory will be created in current working directory

inputs:
  script:
    type: File
    default:
      class: File
      location: /Users/renskedewit/Documents/GitHub/cwl-epitope/tools/combine_inputs.py # delete this later
    #   location: ./tools/combine_inputs.py # relative to cwl-epitope
  input_sequences:
    type: File
    default:
      class: File
      location: /Users/renskedewit/Documents/GitHub/cwl-epitope/test.fasta # delete this later
    #   location: ./test.fasta
  hhm_features:
    type: Directory
    default:
      class: Directory
      location: /Users/renskedewit/Documents/GitHub/cwl-epitope/prov_output/hhm_features
    #   location: ./prov_output/hhm_features
  pc7_features:
    type: Directory
    default:
      class: Directory
      location: /Users/renskedewit/Documents/GitHub/cwl-epitope/prov_output/pc7_features
    #   location: ./prov_output/pc7_features
  psp19_features:
    type: Directory
    default:
      class: Directory
      location: /Users/renskedewit/Documents/GitHub/cwl-epitope/prov_output/psp19_features
    #   location: ./prov_output/psp19_features
  outdir_name:
    type: string
    default: "opus_tass_input_data"

outputs:
  combined_features:
    type: Directory
    outputBinding:
      glob: ./$(inputs.outdir_name)

