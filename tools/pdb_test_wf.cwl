#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: Workflow

label: "Test workflow for mmcif_download.cwl"

# requirements:
#   ScatterFeatureRequirement: {}

inputs:
  pdb_ids:
    type: string[]
    default: [ "3tcl", "4hhb"]
#   pdb_ids:
#     type: string
#     default: "3tcl"

steps:
  download:
    run: mmcif_download.cwl
    # scatter: pdb_id
    in:
      pdb_id: pdb_ids
    out: [ pdb_file ]

outputs: 
  mmcif:
    type: File[]
    outputSource: download/pdb_file
