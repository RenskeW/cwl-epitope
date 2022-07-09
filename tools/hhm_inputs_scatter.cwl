cwlVersion: v1.2
class: CommandLineTool
baseCommand: hhblits

doc: |
  CommandLineTool for hhblits, part of HH-suite. See https://github.com/soedinglab/hh-suite for documentation.
hints:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/hhsuite:3.3.0--py39pl5321h67e14b5_5 # this is the version opus-tass uses?
  SoftwareRequirement:
    packages:
      hhsuite:
        specs: [ https://anaconda.org/bioconda/hhsuite ]
        version: [ "3.3.0" ]

inputs:
  protein_query_sequence: 
    type: File
    format: [ 
      edam:format_1929, # FASTA
      edam:format_3281, # A2M
      ]
  database: Directory # too large to be included in RO, change later to type string = path to database
  database_name: string
  n_iterations: 
    type: int
    default: 2 # change this to the correct value


arguments:
- "-i"
- $(inputs.protein_query_sequence.path) #$(inputs.fasta_dir.path)/$(inputs.protein_id).fasta
- "-d"
- $(inputs.database.path)/$(inputs.database_name)
- "-o"
- $(inputs.protein_query_sequence.nameroot).hhr
- "-ohhm"
- $(inputs.protein_query_sequence.nameroot).hhm
- "-n"
- $(inputs.n_iterations)

outputs:
  hhm_file:
    type: File
    outputBinding:
      glob: "*.hhm"


s:author: # Creator of this CWL document
- s:identifier: https://orcid.org/0000-0003-0902-0086

s:license: Apache-2.0

s:mainEntity: # the tool that this document describes
  s:identifier: https://bio.tools/hhsuite
  s:citation:
    s:identifier: https://doi.org/10.1186/s12859-019-3019-7

$namespaces:
  s: https://schema.org/
  edam: http://edamontology.org/

$schemas:
- https://schema.org/version/latest/schemaorg-current-https.rdf
- https://edamontology.org/EDAM_1.25.owl


