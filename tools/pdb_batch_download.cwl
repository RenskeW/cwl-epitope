#!/usr/env/bin cwl-runner

cwlVersion: v1.2
class: CommandLineTool

baseCommand: [ sh ]

requirements: 
  NetworkAccess:
    networkAccess: True

# To do:
# - Before execution: create new empty directory in which files are saved
# - Make tool work in Docker

# hints:
#   DockerRequirement:
#     dockerPull: curlimages/curl:7.83.0 # make this work later: /var/lib/cwl/stgeb44ade0-b56c-4cdd-9cf1-b2bb84e9cecc/pdb_batch_download.sh: line 73: syntax error: unexpected redirection
#     # dockerOutputDirectory: ./output??

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
  # output_dir:
  #   type: Directory
  #   default: 
  #     class: Directory
  #     path: ./download_files

outputs:
  pdb_files:
    type: File[]
    outputBinding:
      glob: "*.pdb.gz"
  mmcif_files:
    type: File[]
    outputBinding:
      glob: "*.cif.gz"

    
