#!/usr/bin/env cwl-runner

# This is a test file, can be deleted later
cwlVersion: v1.0
class: CommandLineTool
baseCommand: echo
stdout: $(inputs.out_file).txt

inputs:
  message: 
    type: string
    inputBinding:
        position: 1
  out_file:
    type: string
    # inputBinding:
    #   position: 2

outputs: 
  type: stdout