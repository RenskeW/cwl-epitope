#!/usr/bin/env cwl-runner

cwlVersion: v1.2 
class: CommandLineTool
baseCommand: python3

hints:
  DockerRequirement:
    dockerPull: biopython/biopython@sha256:437075df44b0c9b3da96f71040baef0086789de7edf73c81de4ace30a127a245
  # DockerRequirement: # this doesn't work
  #   dockerPull: quay.io/biocontainers/biopython@sha256:fa2c959d7b17b27dd1d3ca3dcc18ac4002f971d1731d57ddcdbd204afab90dba
  SoftwareRequirement:
    packages:
      pandas:
        version: [ "0.19.1" ]
        specs: [ https://pypi.org/project/pandas/ ]
      biopython:
        specs: [ https://pypi.org/project/biopython/ ]
        version: [ "1.75" ]
      dssp:
        specs: [ https://swift.cmbi.umcn.nl/gv/dssp/ ]
        version: [ "2.0.4" ] # this version does not support mmCIF files
      python:
        version: [ "3.5" ]

arguments:
- $(inputs.script.path)
- $(inputs.source_dir.path)
- "-o"
- $(inputs.output_dir)
- "-d"
- $(inputs.dssp)
- "-c"
- $(inputs.rsa_cutoff)

inputs:
  script:
    type: File
    default: 
      class: File
      location: ./dssp_RASA.py 
  source_dir:
    type: Directory
    default: # for testing purposes, remove this later!
      class: Directory
      location: ./dssp_data
  output_dir:
    type: string
    default: "./dssp_scores"
  dssp:
    type: string
    default: "dssp" # in old container: dssp
  rsa_cutoff:
    type: string
    default: "0.06"

outputs:
  dssp_output:
    type: Directory
    outputBinding:
      glob: $(inputs.output_dir)

s:author:
- class: s:Person
  s:name: "Renske de Wit"
s:license: <?>
s:dateCreated: "2022-05-28"
s:mainEntity:
  class: s:SoftwareApplication
  s:name: "dssp_RASA.py"
  s:programmingLanguage: Python
  s:license: <?>
  s:author:
  - class: s:Person
    s:name: "DS"
  s:about: "Script which takes a directory of pdb files as input and calculates relative surface accessibility for each residue in the protein sequence."
  s:basedOn:
  - class: s:SoftwareApplication
    s:name: "DSSP"
  
$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/

$schemas:
- https://schema.org/version/latest/schemaorg-current-https.rdf
- https://edamontology.org/EDAM_1.25.owl




