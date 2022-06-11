#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

baseCommand: python3

requirements:
  NetworkAccess: 
    networkAccess: True

hints:
  DockerRequirement:
    dockerPull: nyurik/alpine-python3-requests@sha256:e0553236e3ebaa240752b41b8475afb454c5ab4c17eb023a2a904637eda16cf6
  SoftwareRequirement:
    packages:
      python3:
        version: [ 3.9.5 ]
      requests:
        version: [ 2.25.1 ]

arguments:
- $(inputs.script.path)
- $(inputs.pdb_search_query.path)
- "--outpath"
- $(inputs.return_file)

inputs:
  script:
    type: File
    default:
      class: File
      path: ./pdb_query.py
  pdb_search_query:
    type: File
    default:
      class: File
      path: ./pdb_query.json
      format: iana:application/json
    format: iana:application/json
  return_file:
    type: string
    label: Path to output file
    default: "./pdb_ids.txt"

outputs:
  processed_response:
    type: File
    label: Comma-separated text file with returned identifiers from PDB search API
    outputBinding:
       glob: $(inputs.return_file)

label: Query PDB search API and store output in comma-separated text file.

doc: |
  "This tool invokes a Python script which uses requests library to query PDB search API and return a comma-separated file of identifiers returned by the API.
  More information about PDB search API: https://search.rcsb.org/index.html"


$namespaces:
  iana: https://www.iana.org/assignments/media-types/
  s: https://www.schema.org/

# $schemas:

s:author:
- class: s:Person
  s:name: "Renske de Wit"

s:mainEntity:
  s:author:
  - class: s:Person
    s:name: "Renske de Wit"

