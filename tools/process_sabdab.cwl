#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: amancevice/pandas:1.3.4-slim

baseCommand: python3

arguments:
- $(inputs.script.path)
- $(inputs.sabdab_summary_file.path)
- "-o"
- $(inputs.out_file)

inputs:
  script:
    type: File
    default:
      class: File
      location: ./process_sabdab_summary.py
  sabdab_summary_file:
    type: File
    label: Summary file downloaded from SAbDab.
    format: iana:text/tab-separated-values
  out_file:
    type: string
    label: Name of output file in which processed results are stored.
    default: "SAbDab_protein_antigens_PDB_chains.csv"
    format: iana:text/csv

outputs:
  processed_summary_file:
    type: File
    outputBinding:
      glob: $(inputs.out_file)

s:author:
- class: s:Person
  s:name: "Renske de Wit"
  s:identifier: <ORCID identifier>
s:license: https://spdx.org/licenses/Apache-2.0

s:mainEntity:
  class: s:SoftwareApplication
  s:license: https://spdx.org/licenses/Apache-2.0
  s:author:
  - class: s:Person
    s:name: "Katharina Waury"
    s:identifier: <Kathi's ORCID identifier>

$namespaces:
  iana: "https://www.iana.org/assignments/media-types/"
  s: "https://schema.org/"
