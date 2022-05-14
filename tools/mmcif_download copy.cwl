#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

doc: |
  "Does the same thing as mmcif_download.cwl but not via a bash script. curl -s -f https://files.rcsb.org/download/4hhb.cif -o ./pdb/4hhb.cif"

baseCommand: [ curl ]

requirements:
  NetworkAccess: 
    networkAccess: True

hints:
  DockerRequirement: 
    dockerPull: curlimages/curl:7.83.0 # does not work yet
#     dockerPull: curlimages/curl:7.65.3 # also does not work

arguments:
- "-f"
- $(inputs.pdb_url)/$(inputs.pdb_id).cif
- "-o"
- ./$(inputs.pdb_id).cif

inputs:
  pdb_url:
    type: string
    default: "https://files.rcsb.org/download"
  pdb_id:
    type: string
    default: "4hhb"

outputs: 
  pdb_file:
    type: File
    outputBinding:
      glob: "*.cif"
  