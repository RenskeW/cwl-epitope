cwlVersion: v1.0
class: CommandLineTool

hints:
  DockerRequirement:
    dockerPull: quay.io/biocontainers/hhsuite:3.3.0--py39pl5321h67e14b5_5

baseCommand: python3

inputs:
  script:
    type: File
    default:
      class: File
      location: ../tools/run_hhblits.py # outputs hhblits shell command
  protein_query_sequences:
    type: File
    default:
      class: File
      location: /scistor/informatica/hwt330/cwl-epitope/test.fasta # change this later
    # format: FASTA protein
  database:
    type: Directory
    default:
      class: Directory
      location: /scistor/informatica/hwt330/hhblits/databases
  database_name:
    type: string
    default: "pdb70"

arguments:
  - $(inputs.script.location)
  - $(inputs.protein_query_sequences.location)
  - $(inputs.database.location)/$(inputs.database_name)

outputs:
  hmm_profile:
    type: File[]
    outputBinding:
      glob: "*.hhm"
  protein_sequences: # script outputs separate .fasta file for each protein sequence. This is input for hhblits
    type: File[]
    outputBinding:
      glob: "*.fasta"
