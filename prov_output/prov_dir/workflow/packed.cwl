{
    "$graph": [
        {
            "class": "Workflow",
            "inputs": [
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/test.fasta"
                    },
                    "id": "#main/fasta_path"
                }
            ],
            "steps": [
                {
                    "label": "Generate HHM profile",
                    "run": "#hhm_inputs.cwl",
                    "in": [
                        {
                            "default": {
                                "class": "Directory",
                                "location": "file:///scistor/informatica/hwt330/hhblits/databases"
                            },
                            "id": "#main/generate_hhm/database"
                        },
                        {
                            "default": "pdb70",
                            "id": "#main/generate_hhm/database_name"
                        },
                        {
                            "default": "hhm_features",
                            "id": "#main/generate_hhm/output_directory_name"
                        },
                        {
                            "source": "#main/fasta_path",
                            "id": "#main/generate_hhm/protein_query_sequences"
                        },
                        {
                            "default": {
                                "class": "File",
                                "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/run_hhblits.py"
                            },
                            "id": "#main/generate_hhm/script"
                        }
                    ],
                    "out": [
                        "#main/generate_hhm/hhm_profiles"
                    ],
                    "doc": "Builds multiple sequence alignment using HHBlits for every protein sequence. Output stored in 1 .hhm file per sequence.\n# format: https://github.com/soedinglab/hh-suite/wiki#file-formats .hhm\n",
                    "id": "#main/generate_hhm"
                },
                {
                    "label": "Generate PC7",
                    "run": "#pc7_inputs.cwl",
                    "in": [
                        {
                            "source": "#main/fasta_path",
                            "id": "#main/generate_pc7/fasta"
                        },
                        {
                            "default": "pc7_features",
                            "id": "#main/generate_pc7/outdir"
                        }
                    ],
                    "out": [
                        "#main/generate_pc7/pc7_features"
                    ],
                    "doc": "Generates PC7 features per residue. Output stored in 1 file per protein sequence.       \n",
                    "id": "#main/generate_pc7"
                },
                {
                    "label": "Generate PSP19",
                    "run": "#psp19_inputs.cwl",
                    "in": [
                        {
                            "source": "#main/fasta_path",
                            "id": "#main/generate_psp19/fasta"
                        },
                        {
                            "default": "psp19_features",
                            "id": "#main/generate_psp19/outdir"
                        }
                    ],
                    "out": [
                        "#main/generate_psp19/psp19_features"
                    ],
                    "doc": "Generates PSP19 features per residue. Output stored in 1 file per sequence.\n \n",
                    "id": "#main/generate_psp19"
                }
            ],
            "id": "#main",
            "outputs": [
                {
                    "type": "Directory",
                    "outputSource": "#main/generate_hhm/hhm_profiles",
                    "id": "#main/hhm_features"
                },
                {
                    "type": "Directory",
                    "outputSource": "#main/generate_pc7/pc7_features",
                    "id": "#main/pc7_features"
                },
                {
                    "type": "Directory",
                    "outputSource": "#main/generate_psp19/psp19_features",
                    "id": "#main/psp19_features"
                }
            ]
        },
        {
            "class": "CommandLineTool",
            "hints": [
                {
                    "class": "LoadListingRequirement",
                    "loadListing": "deep_listing"
                },
                {
                    "class": "NetworkAccess",
                    "networkAccess": true
                },
                {
                    "dockerPull": "quay.io/biocontainers/hhsuite:3.3.0--py39pl5321h67e14b5_5",
                    "class": "DockerRequirement"
                }
            ],
            "baseCommand": "python3",
            "inputs": [
                {
                    "type": "Directory",
                    "default": {
                        "class": "Directory",
                        "location": "file:///scistor/informatica/hwt330/hhblits/databases"
                    },
                    "doc": "\"Directory containing hhblits databases\"\n",
                    "id": "#hhm_inputs.cwl/database"
                },
                {
                    "type": "string",
                    "default": "pdb70",
                    "doc": "\"The database against which to run the query protein sequence, must be located in $(inputs.database)\"\n",
                    "id": "#hhm_inputs.cwl/database_name"
                },
                {
                    "type": "string",
                    "default": "hhm_features",
                    "doc": "\"Name of directory in which output .hhm files will be stored.\"\n",
                    "id": "#hhm_inputs.cwl/output_directory_name"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/test.fasta"
                    },
                    "doc": "\"File with FASTA sequences for which HHM profiles will be generated by HHBlits\"\n",
                    "id": "#hhm_inputs.cwl/protein_query_sequences"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/run_hhblits.py"
                    },
                    "id": "#hhm_inputs.cwl/script"
                }
            ],
            "arguments": [
                "$(inputs.script.path)",
                "$(inputs.protein_query_sequences.path)",
                "$(inputs.database.path)/$(inputs.database_name)",
                "--outdir",
                "./$(inputs.output_directory_name)"
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "./$(inputs.output_directory_name)"
                    },
                    "doc": "\"Directory containing HHM profiles for each of the input protein sequences.\"\n",
                    "id": "#hhm_inputs.cwl/hhm_profiles"
                }
            ],
            "id": "#hhm_inputs.cwl"
        },
        {
            "class": "CommandLineTool",
            "hints": [
                {
                    "class": "LoadListingRequirement",
                    "loadListing": "deep_listing"
                },
                {
                    "class": "NetworkAccess",
                    "networkAccess": true
                },
                {
                    "dockerPull": "amancevice/pandas:1.3.4-slim",
                    "class": "DockerRequirement"
                },
                {
                    "packages": [
                        {
                            "specs": [
                                "https://anaconda.org/conda-forge/numpy"
                            ],
                            "package": "numpy"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "baseCommand": "python3",
            "inputs": [
                {
                    "type": "File",
                    "inputBinding": {
                        "position": 2
                    },
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/test.fasta"
                    },
                    "id": "#pc7_inputs.cwl/fasta"
                },
                {
                    "type": "string",
                    "inputBinding": {
                        "position": 3,
                        "prefix": "-o"
                    },
                    "default": "pc7_features",
                    "id": "#pc7_inputs.cwl/outdir"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/get_pc7_inputs.py"
                    },
                    "inputBinding": {
                        "position": 1
                    },
                    "id": "#pc7_inputs.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "$(inputs.outdir)"
                    },
                    "id": "#pc7_inputs.cwl/pc7_features"
                }
            ],
            "id": "#pc7_inputs.cwl"
        },
        {
            "class": "CommandLineTool",
            "hints": [
                {
                    "dockerPull": "amancevice/pandas:1.3.4-slim",
                    "class": "DockerRequirement"
                }
            ],
            "baseCommand": "python3",
            "inputs": [
                {
                    "type": "File",
                    "inputBinding": {
                        "position": 2
                    },
                    "id": "#psp19_inputs.cwl/fasta"
                },
                {
                    "type": "string",
                    "inputBinding": {
                        "position": 3,
                        "prefix": "-o"
                    },
                    "default": "psp19_features",
                    "id": "#psp19_inputs.cwl/outdir"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/get_psp19_inputs.py"
                    },
                    "inputBinding": {
                        "position": 1
                    },
                    "id": "#psp19_inputs.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "$(inputs.outdir)"
                    },
                    "id": "#psp19_inputs.cwl/psp19_features"
                }
            ],
            "id": "#psp19_inputs.cwl"
        }
    ],
    "cwlVersion": "v1.2"
}