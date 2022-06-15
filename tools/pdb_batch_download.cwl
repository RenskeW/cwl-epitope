#!/usr/env/bin cwl-runner

cwlVersion: v1.2
class: CommandLineTool

baseCommand: [ bash ]

# requirements: 
#   NetworkAccess:
#     networkAccess: True

# hints:
#   DockerRequirement:
#     dockerPull: curlimages/curl:7.83.0 # make this work later: /entrypoint.sh: exec: line 14: /var/lib/cwl/stg1b61f255-57e4-4f05-9c56-6f9124b393a0/pdb_batch_download.sh: not found

arguments:
- $(inputs.script.path)
- "-o"
- $(inputs.output_dir)
- "-f"
- $(inputs.input_file.path)
- "-c" # download mmcif files
- "-p" # download pdb files

inputs:
  script:
    type: File
    default:
      class: File
      path: ./pdb_batch_download.sh
  input_file:
    label: "Comma-separated .txt file with pdb entries to download"
    type: File
    default:
      class: File
      path: ./pdb_ids.txt
  output_dir:
    type: string
    default: "."

outputs:
  pdb_files:
    type: File[]
    outputBinding:
      glob: "*.pdb.gz"
  mmcif_files:
    type: File[]
    outputBinding:
      glob: "*.cif.gz"
    
