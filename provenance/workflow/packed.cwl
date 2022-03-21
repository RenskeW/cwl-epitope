{
    "$graph": [
        {
            "class": "Workflow",
            "inputs": [
                {
                    "type": "File",
                    "id": "#main/fasta_path"
                }
            ],
            "steps": [
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
                    "doc": "Generates PC7 features per residue. Output stored in 1 file per sequence.\n \n",
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
                        "location": "file:///Users/renskedewit/Documents/GitHub/cwl-epitope/tools/get_pc7_inputs.py"
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
                        "location": "file:///Users/renskedewit/Documents/GitHub/cwl-epitope/tools/get_psp19_inputs.py"
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