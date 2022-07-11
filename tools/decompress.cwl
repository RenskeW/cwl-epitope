#!/usr/bin/env cwl-runner

cwlVersion: v1.2
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      ${
        var LIST = inputs.in_gz;
        return LIST;
      }

baseCommand: [gzip]

arguments: 
  - position: 1
    prefix: -df
    valueFrom: $(inputs.in_gz)

inputs:
  in_gz:
    type: File[]

outputs: 
  out_cif:
    type: File[]
    outputBinding:
      glob: 
        ${
          var A = inputs.in_gz;
          var B = [];
          for(var i = 0; i < A.length; i++){
            if (A[i].nameroot.endsWith(".cif")) {
              B.push(A[i].nameroot);
            }
          }
          return B;
        }
  out_pdb:
    type: File[]
    outputBinding:
      glob: 
        ${
          var A = inputs.in_gz;
          var B = [];
          for(var i = 0; i < A.length; i++){
            if (A[i].nameroot.endsWith(".pdb")) {
              B.push(A[i].nameroot);
            }
          }
          return B;
        }    

s:isBasedOn:
- class: s:SoftwareApplication
  s:url: https://github.com/NAL-i5K/Organism_Onboarding/blob/e3b7029fab3518f07d5376dfec73790a77b458ed/flow_md5checksums/gunzip_multi.cwl


$namespaces:
  s: https://schema.org/

$schemas:
- https://schema.org/version/latest/schemaorg-current-https.rdf


