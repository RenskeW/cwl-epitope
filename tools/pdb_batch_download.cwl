#!/usr/env/bin cwl-runner

cwlVersion: v1.2
class: CommandLineTool

baseCommand: [ bash ]

requirements: 
  NetworkAccess:
    networkAccess: True

inputs:
  script:
    type: File
    inputBinding:
      position: 1
    default:
      class: File
      location: ./pdb_batch_download.sh
  output_dir:
    type: string
    inputBinding:
      prefix: "-o"
      position: 2
    default: "."
  input_file:
    label: "Comma-separated .txt file with pdb entries to download"
    type: File
    format: iana:text/csv
    inputBinding:
      position: 3
      prefix: "-f"
  mmcif_format: # The last arguments specify the format in which entries will be downloaded
    type: boolean
    inputBinding:
      position: 4
      prefix: "-c" # .cif.gz
    default: True
  pdb_format:
    type: boolean
    inputBinding:
      position: 5
      prefix: "-p" # .pdb.gz
    default: False
  pdb1_format:
    type: boolean
    inputBinding:
      position: 6
      prefix: "-a" # .pdb1.gz
    default: False
  xml_format:
    type: boolean
    inputBinding:
      position: 7
      prefix: "-x" # .xml.gz
    default: False
  sfcif_format:
    type: boolean
    inputBinding:
      position: 8
      prefix: "-s" # .sf.cif.gz
    default: False
  mr_format:
    type: boolean
    inputBinding:
      position: 9
      prefix: "-m" # .mr.gz
    default: False
  mr_str_format:
    type: boolean
    inputBinding:
      position: 10
      prefix: "-r" # .mr.str.gz
    default: False  

outputs:
  pdb_files:
    type: File[]
    outputBinding:
      glob: "*.gz"

    
$namespaces:
  iana: https://www.iana.org/assignments/media-types/