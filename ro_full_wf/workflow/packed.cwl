{
    "$graph": [
        {
            "class": "Workflow",
            "intent": [
                "http://edamontology.org/operation_2423"
            ],
            "doc": "This workflow calculates input features and labels which are used to train a deep learning model for epitope prediction.",
            "requirements": [
                {
                    "class": "ScatterFeatureRequirement"
                },
                {
                    "class": "StepInputExpressionRequirement"
                },
                {
                    "class": "SubworkflowFeatureRequirement"
                }
            ],
            "inputs": [
                {
                    "type": "File",
                    "doc": "BioDL test dataset with PPI interactions.",
                    "id": "#main/biodl_test_dataset"
                },
                {
                    "type": "File",
                    "doc": "BioDL training dataset containing PPI interactions",
                    "id": "#main/biodl_train_dataset"
                },
                {
                    "type": "Directory",
                    "doc": "Directory with reference database for HHblits",
                    "id": "#main/hhblits_db_dir"
                },
                {
                    "type": "string",
                    "doc": "Name of hhblits reference database",
                    "id": "#main/hhblits_db_name"
                },
                {
                    "type": "File",
                    "doc": "File with structured query in JSON format for PDB API.",
                    "id": "#main/pdb_search_api_query"
                },
                {
                    "type": "File",
                    "doc": "Summary file downloaded from SAbDab containing metadata about all structures in the database.",
                    "id": "#main/sabdab_summary_file"
                }
            ],
            "steps": [
                {
                    "in": [
                        {
                            "source": "#main/generate_hhm/hhm_file_array",
                            "id": "#main/combine_features/hhm_features"
                        },
                        {
                            "source": "#main/generate_ppi_labels/ppi_fasta_files",
                            "id": "#main/combine_features/input_sequences"
                        },
                        {
                            "source": "#main/generate_pc7/pc7_features",
                            "id": "#main/combine_features/pc7_features"
                        },
                        {
                            "source": "#main/generate_psp19/psp19_features",
                            "id": "#main/combine_features/psp19_features"
                        }
                    ],
                    "out": [
                        "#main/combine_features/combined_features"
                    ],
                    "run": "#combine_features.cwl",
                    "id": "#main/combine_features"
                },
                {
                    "doc": "Combine labels into 1 file per protein sequence.",
                    "run": "#combine_labels.cwl",
                    "in": [
                        {
                            "source": "#main/generate_dssp_labels/dssp_output_files",
                            "id": "#main/combine_labels/dssp_directory"
                        },
                        {
                            "source": "#main/generate_epitope_labels/epitope_fasta_dir",
                            "id": "#main/combine_labels/epitope_directory"
                        },
                        {
                            "source": "#main/generate_ppi_labels/ppi_fasta_files",
                            "id": "#main/combine_labels/ppi_directory"
                        }
                    ],
                    "out": [
                        "#main/combine_labels/labels_combined"
                    ],
                    "id": "#main/combine_labels"
                },
                {
                    "in": [
                        {
                            "source": "#main/download_pdb_files/pdb_files",
                            "id": "#main/decompress_pdb_files/in_gz"
                        }
                    ],
                    "out": [
                        "#main/decompress_pdb_files/out_cif",
                        "#main/decompress_pdb_files/out_pdb"
                    ],
                    "run": "#decompress.cwl",
                    "doc": "Decompress files using gzip",
                    "id": "#main/decompress_pdb_files"
                },
                {
                    "in": [
                        {
                            "source": "#main/run_pdb_query/processed_response",
                            "id": "#main/download_pdb_files/input_file"
                        },
                        {
                            "default": true,
                            "id": "#main/download_pdb_files/mmcif_format"
                        },
                        {
                            "default": true,
                            "id": "#main/download_pdb_files/pdb_format"
                        }
                    ],
                    "out": [
                        "#main/download_pdb_files/pdb_files"
                    ],
                    "run": "#pdb_batch_download.cwl",
                    "id": "#main/download_pdb_files"
                },
                {
                    "in": [
                        {
                            "source": "#main/decompress_pdb_files/out_pdb",
                            "id": "#main/generate_dssp_labels/pdb_files"
                        },
                        {
                            "default": 0.06,
                            "id": "#main/generate_dssp_labels/rsa_cutoff"
                        }
                    ],
                    "out": [
                        "#main/generate_dssp_labels/dssp_output_files"
                    ],
                    "run": "#dssp.cwl",
                    "doc": "Use DSSP to extract secondary structure and solvent accessibility from PDB files.",
                    "id": "#main/generate_dssp_labels"
                },
                {
                    "in": [
                        {
                            "source": "#main/decompress_pdb_files/out_cif",
                            "id": "#main/generate_epitope_labels/mmcif_files"
                        },
                        {
                            "source": "#main/preprocess_sabdab_data/processed_summary_file",
                            "id": "#main/generate_epitope_labels/sabdab_processed_file"
                        }
                    ],
                    "out": [
                        "#main/generate_epitope_labels/epitope_fasta_dir"
                    ],
                    "run": "#epitope_annotations.cwl",
                    "doc": "Extract epitope annotations from PDB files.",
                    "id": "#main/generate_epitope_labels"
                },
                {
                    "in": [
                        {
                            "source": "#main/hhblits_db_dir",
                            "id": "#main/generate_hhm/hhblits_db_dir"
                        },
                        {
                            "source": "#main/hhblits_db_name",
                            "id": "#main/generate_hhm/hhblits_db_name"
                        },
                        {
                            "default": 1,
                            "id": "#main/generate_hhm/hhblits_n_iterations"
                        },
                        {
                            "source": "#main/generate_ppi_labels/ppi_fasta_files",
                            "valueFrom": "$(self.listing)",
                            "id": "#main/generate_hhm/query_sequences"
                        }
                    ],
                    "out": [
                        "#main/generate_hhm/hhm_file_array"
                    ],
                    "run": {
                        "class": "Workflow",
                        "inputs": [
                            {
                                "type": "Directory",
                                "id": "#main/generate_hhm/run/hhblits_db_dir"
                            },
                            {
                                "type": "string",
                                "id": "#main/generate_hhm/run/hhblits_db_name"
                            },
                            {
                                "type": "int",
                                "id": "#main/generate_hhm/run/hhblits_n_iterations"
                            },
                            {
                                "type": {
                                    "type": "array",
                                    "items": "File"
                                },
                                "id": "#main/generate_hhm/run/query_sequences"
                            }
                        ],
                        "outputs": [
                            {
                                "type": {
                                    "type": "array",
                                    "items": "File"
                                },
                                "outputSource": "#main/generate_hhm/run/run_hhblits/hhm_file",
                                "id": "#main/generate_hhm/run/hhm_file_array"
                            }
                        ],
                        "steps": [
                            {
                                "in": [
                                    {
                                        "source": "#main/generate_hhm/run/hhblits_db_dir",
                                        "id": "#main/generate_hhm/run/run_hhblits/database"
                                    },
                                    {
                                        "source": "#main/generate_hhm/run/hhblits_db_name",
                                        "id": "#main/generate_hhm/run/run_hhblits/database_name"
                                    },
                                    {
                                        "source": "#main/generate_hhm/run/hhblits_n_iterations",
                                        "id": "#main/generate_hhm/run/run_hhblits/n_iterations"
                                    },
                                    {
                                        "source": "#main/generate_hhm/run/query_sequences",
                                        "id": "#main/generate_hhm/run/run_hhblits/protein_query_sequence"
                                    }
                                ],
                                "out": [
                                    "#main/generate_hhm/run/run_hhblits/hhm_file"
                                ],
                                "scatter": "#main/generate_hhm/run/run_hhblits/protein_query_sequence",
                                "run": "#hhm_inputs_scatter.cwl",
                                "id": "#main/generate_hhm/run/run_hhblits"
                            }
                        ]
                    },
                    "id": "#main/generate_hhm"
                },
                {
                    "doc": "Calculate PC7 features for each residue in each protein sequence.",
                    "run": "#pc7_inputs.cwl",
                    "in": [
                        {
                            "source": "#main/generate_ppi_labels/ppi_fasta_files",
                            "id": "#main/generate_pc7/fasta"
                        }
                    ],
                    "out": [
                        "#main/generate_pc7/pc7_features"
                    ],
                    "id": "#main/generate_pc7"
                },
                {
                    "in": [
                        {
                            "source": "#main/decompress_pdb_files/out_cif",
                            "id": "#main/generate_ppi_labels/mmcif_files"
                        },
                        {
                            "source": "#main/biodl_test_dataset",
                            "id": "#main/generate_ppi_labels/test_dataset"
                        },
                        {
                            "source": "#main/biodl_train_dataset",
                            "id": "#main/generate_ppi_labels/train_dataset"
                        }
                    ],
                    "out": [
                        "#main/generate_ppi_labels/ppi_fasta_files"
                    ],
                    "run": "#ppi_annotations.cwl",
                    "doc": "Extract ppi annotations from BioDL. This step is partly emulated.",
                    "id": "#main/generate_ppi_labels"
                },
                {
                    "label": "Calculate PSP19 features for each residue in each protein sequence.",
                    "run": "#psp19_inputs.cwl",
                    "in": [
                        {
                            "source": "#main/generate_ppi_labels/ppi_fasta_files",
                            "id": "#main/generate_psp19/fasta"
                        }
                    ],
                    "out": [
                        "#main/generate_psp19/psp19_features"
                    ],
                    "id": "#main/generate_psp19"
                },
                {
                    "doc": "Extract antigen chains from SAbDab summary file.",
                    "in": [
                        {
                            "source": "#main/sabdab_summary_file",
                            "id": "#main/preprocess_sabdab_data/sabdab_summary_file"
                        }
                    ],
                    "out": [
                        "#main/preprocess_sabdab_data/processed_summary_file"
                    ],
                    "run": "#process_sabdab.cwl",
                    "id": "#main/preprocess_sabdab_data"
                },
                {
                    "in": [
                        {
                            "source": "#main/pdb_search_api_query",
                            "id": "#main/run_pdb_query/pdb_search_query"
                        }
                    ],
                    "out": [
                        "#main/run_pdb_query/processed_response"
                    ],
                    "run": "#pdb_query.cwl",
                    "doc": "\"Use PDB search API to run a query on the Protein Data Bank. Returns .txt file with comma-separated PDB IDs which satisfy the query requirements.\nSee https://search.rcsb.org/index.html#search-api for a tutorial.\"\n",
                    "id": "#main/run_pdb_query"
                },
                {
                    "in": [
                        {
                            "source": "#main/combine_features/combined_features",
                            "id": "#main/train_epitope_prediction_model/input_features"
                        },
                        {
                            "source": "#main/combine_labels/labels_combined",
                            "id": "#main/train_epitope_prediction_model/input_labels"
                        }
                    ],
                    "out": [
                        "#main/train_epitope_prediction_model/train_log"
                    ],
                    "run": "#train_epitope_model.cwl",
                    "doc": "\"Predict epitope residues using a multi-task learning approach. This step is not real yet.\"  \n",
                    "id": "#main/train_epitope_prediction_model"
                }
            ],
            "s:author": [
                {
                    "s:name": "Renske de Wit",
                    "s:identifier": "https://orcid.org/0000-0003-0902-0086"
                },
                {
                    "s:name": "Katharina Waury"
                }
            ],
            "s:license": "https://spdx.org/licenses/Apache-2.0",
            "id": "#main",
            "outputs": [
                {
                    "type": "File",
                    "outputSource": "#main/train_epitope_prediction_model/train_log",
                    "doc": "Output of the prediction model.",
                    "id": "#main/model_output"
                }
            ]
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "label": "Combine input features",
            "doc": "\"Combines the input features for each protein sequence into 1 file per sequence. Output is stored in a new directory.\"\n",
            "hints": [
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
                            "version": [
                                "1.21.4"
                            ],
                            "package": "numpy"
                        },
                        {
                            "specs": [
                                "https://anaconda.org/conda-forge/pandas"
                            ],
                            "version": [
                                "1.3.4"
                            ],
                            "package": "pandas"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "requirements": [
                {
                    "listing": "${\n     return [{\"entry\": {\"class\": \"Directory\", \"basename\": \"hhm_features_dir\", \"listing\": inputs.hhm_features}, \"writable\": true}]\n }\n",
                    "class": "InitialWorkDirRequirement"
                },
                {
                    "class": "InlineJavascriptRequirement"
                }
            ],
            "arguments": [
                "$(inputs.script.path)",
                "$(inputs.input_sequences.path)",
                "hhm_features_dir",
                "$(inputs.pc7_features.path)",
                "$(inputs.psp19_features.path)",
                "--outdir",
                "./$(inputs.outdir_name)"
            ],
            "inputs": [
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "id": "#combine_features.cwl/hhm_features"
                },
                {
                    "type": "Directory",
                    "id": "#combine_features.cwl/input_sequences"
                },
                {
                    "type": "string",
                    "default": "input_features",
                    "id": "#combine_features.cwl/outdir_name"
                },
                {
                    "type": "Directory",
                    "id": "#combine_features.cwl/pc7_features"
                },
                {
                    "type": "Directory",
                    "id": "#combine_features.cwl/psp19_features"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/combine_inputs.py"
                    },
                    "id": "#combine_features.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "./$(inputs.outdir_name)"
                    },
                    "id": "#combine_features.cwl/combined_features"
                }
            ],
            "id": "#combine_features.cwl"
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "arguments": [
                "$(inputs.script.path)",
                "$(inputs.epitope_directory.path)",
                "$(inputs.ppi_directory.path)",
                "$(inputs.dssp_directory.path)",
                "--outdir",
                "$(inputs.output_directory)"
            ],
            "inputs": [
                {
                    "type": "Directory",
                    "doc": "Directory with DSSP output files.",
                    "id": "#combine_labels.cwl/dssp_directory"
                },
                {
                    "type": "Directory",
                    "doc": "Directory with FASTA files with epitope annotations.",
                    "id": "#combine_labels.cwl/epitope_directory"
                },
                {
                    "type": "string",
                    "default": "./combined_labels",
                    "id": "#combine_labels.cwl/output_directory"
                },
                {
                    "type": "Directory",
                    "doc": "Directory with FASTA files with PPI annotations.",
                    "id": "#combine_labels.cwl/ppi_directory"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/combine_labels.py"
                    },
                    "id": "#combine_labels.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "doc": "Directory with 1 file per sequence, containing label values for each residue",
                    "outputBinding": {
                        "glob": "$(inputs.output_directory)"
                    },
                    "id": "#combine_labels.cwl/labels_combined"
                }
            ],
            "id": "#combine_labels.cwl"
        },
        {
            "class": "CommandLineTool",
            "requirements": [
                {
                    "class": "InlineJavascriptRequirement"
                },
                {
                    "class": "InitialWorkDirRequirement",
                    "listing": "${ var LIST = inputs.in_gz; return LIST; }"
                }
            ],
            "baseCommand": [
                "gzip"
            ],
            "arguments": [
                {
                    "position": 1,
                    "prefix": "-df",
                    "valueFrom": "$(inputs.in_gz)"
                }
            ],
            "inputs": [
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "id": "#decompress.cwl/in_gz"
                }
            ],
            "outputs": [
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "outputBinding": {
                        "glob": "${ var A = inputs.in_gz; var B = []; for(var i = 0; i < A.length; i++){ if (A[i].nameroot.endsWith(\".cif\")) { B.push(A[i].nameroot); } } return B; }"
                    },
                    "id": "#decompress.cwl/out_cif"
                },
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "outputBinding": {
                        "glob": "${ var A = inputs.in_gz; var B = []; for(var i = 0; i < A.length; i++){ if (A[i].nameroot.endsWith(\".pdb\")) { B.push(A[i].nameroot); } } return B; }"
                    },
                    "id": "#decompress.cwl/out_pdb"
                }
            ],
            "id": "#decompress.cwl",
            "https://schema.org/isBasedOn": [
                {
                    "class": "https://schema.org/SoftwareApplication",
                    "https://schema.org/url": "https://github.com/NAL-i5K/Organism_Onboarding/blob/e3b7029fab3518f07d5376dfec73790a77b458ed/flow_md5checksums/gunzip_multi.cwl"
                }
            ]
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "doc": "Use DSSP to extract secondary structure and solvent accessibility from PDB files.",
            "intent": [
                "http://edamontology.org/operation_0320"
            ],
            "requirements": [
                {
                    "listing": "${\n     return [{\"entry\": {\"class\": \"Directory\", \"basename\": \"pdb_source_dir\", \"listing\": inputs.pdb_files}, \"writable\": true}]\n }\n",
                    "class": "InitialWorkDirRequirement"
                },
                {
                    "class": "InlineJavascriptRequirement"
                }
            ],
            "hints": [
                {
                    "dockerPull": "biopython/biopython@sha256:437075df44b0c9b3da96f71040baef0086789de7edf73c81de4ace30a127a245",
                    "class": "DockerRequirement"
                },
                {
                    "packages": [
                        {
                            "specs": [
                                "https://pypi.org/project/biopython/"
                            ],
                            "version": [
                                "1.75"
                            ],
                            "package": "biopython"
                        },
                        {
                            "specs": [
                                "https://swift.cmbi.umcn.nl/gv/dssp/"
                            ],
                            "version": [
                                "2.0.4"
                            ],
                            "package": "dssp"
                        },
                        {
                            "version": [
                                "0.19.1"
                            ],
                            "specs": [
                                "https://pypi.org/project/pandas/"
                            ],
                            "package": "pandas"
                        },
                        {
                            "version": [
                                "3.5"
                            ],
                            "package": "python"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "arguments": [
                "$(inputs.script.path)",
                "pdb_source_dir",
                "-o",
                "$(inputs.output_dir)",
                "-d",
                "$(inputs.dssp)",
                "-c",
                "$(inputs.rsa_cutoff)"
            ],
            "inputs": [
                {
                    "type": "string",
                    "default": "dssp",
                    "id": "#dssp.cwl/dssp"
                },
                {
                    "type": "string",
                    "default": "dssp_output",
                    "id": "#dssp.cwl/output_dir"
                },
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "doc": "Protein structures in PDB format.",
                    "id": "#dssp.cwl/pdb_files"
                },
                {
                    "type": "float",
                    "default": 0.06,
                    "doc": "Threshold exposed surface area for considering amino acids buried.",
                    "id": "#dssp.cwl/rsa_cutoff"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/dssp_RASA.py"
                    },
                    "id": "#dssp.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "$(inputs.output_dir)"
                    },
                    "id": "#dssp.cwl/dssp_output_files"
                }
            ],
            "id": "#dssp.cwl",
            "https://schema.org/author": [
                {
                    "class": "https://schema.org/Person",
                    "https://schema.org/name": "Renske de Wit"
                }
            ],
            "https://schema.org/license": "https://spdx.org/licenses/Apache-2.0",
            "https://schema.org/dateCreated": "2022-05-28",
            "https://schema.org/mainEntity": {
                "class": "https://schema.org/SoftwareApplication",
                "https://schema.org/license": "https://spdx.org/licenses/Apache-2.0",
                "https://schema.org/author": [
                    {
                        "class": "https://schema.org/Person",
                        "https://schema.org/name": "DS"
                    }
                ],
                "https://schema.org/description": "Script which takes a directory of pdb files as input and calculates relative surface accessibility for each residue in the protein sequence.",
                "https://schema.org/basedOn": [
                    {
                        "class": "https://schema.org/SoftwareApplication",
                        "https://schema.org/name": "DSSP"
                    }
                ]
            }
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "intent": [
                "http://edamontology.org/operation_0320"
            ],
            "requirements": [
                {
                    "listing": "${\n     return [{\"entry\": {\"class\": \"Directory\", \"basename\": \"mmcif_directory\", \"listing\": inputs.mmcif_files}, \"writable\": true}]\n }\n",
                    "class": "InitialWorkDirRequirement"
                },
                {
                    "class": "InlineJavascriptRequirement"
                }
            ],
            "doc": "Runs Python script which takes directory of mmCIF files as input and outputs directory of FASTA files with protein sequence + epitope annotations.\n",
            "hints": [
                {
                    "packages": [
                        {
                            "specs": [
                                "https://anaconda.org/conda-forge/pandas"
                            ],
                            "version": [
                                "1.2.4"
                            ],
                            "package": "pandas"
                        },
                        {
                            "specs": [
                                "https://pypi.org/project/PDBeCif/"
                            ],
                            "version": [
                                "1.5"
                            ],
                            "package": "pdbecif"
                        },
                        {
                            "version": [
                                "3.9.1"
                            ],
                            "package": "python"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "arguments": [
                "$(inputs.script.path)",
                "mmcif_directory",
                "$(inputs.sabdab_processed_file.path)",
                "--fasta_directory",
                "$(inputs.fasta_output_dir)",
                "--df_directory",
                "$(inputs.df_output_dir)"
            ],
            "inputs": [
                {
                    "type": "string",
                    "default": "./epitope_df",
                    "id": "#epitope_annotations.cwl/df_output_dir"
                },
                {
                    "type": "string",
                    "default": "./epitope_fasta",
                    "id": "#epitope_annotations.cwl/fasta_output_dir"
                },
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "doc": "mmCIF file array",
                    "id": "#epitope_annotations.cwl/mmcif_files"
                },
                {
                    "type": "File",
                    "doc": ".csv file with PDB entries with associated H, L and antigen chain.",
                    "id": "#epitope_annotations.cwl/sabdab_processed_file"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/epitope_annotation_pipeline.py"
                    },
                    "id": "#epitope_annotations.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "$(inputs.df_output_dir)"
                    },
                    "id": "#epitope_annotations.cwl/epitope_df_dir"
                },
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "$(inputs.fasta_output_dir)"
                    },
                    "id": "#epitope_annotations.cwl/epitope_fasta_dir"
                }
            ],
            "id": "#epitope_annotations.cwl",
            "https://schema.org/dateCreated": "2022-05-30",
            "https://schema.org/mainEntity": {
                "https://schema.org/additionalType": "s:SoftwareApplication",
                "https://schema.org/author": [
                    {
                        "https://schema.org/name": "Katharina Waury"
                    }
                ],
                "https://schema.org/dateCreated": "2022-02-10",
                "https://schema.org/programmingLanguage": "Python",
                "https://schema.org/description": "Script which extracts epitope annotations and dataframes from mmCIF files."
            }
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "hhblits",
            "doc": "CommandLineTool for hhblits, part of HH-suite. See https://github.com/soedinglab/hh-suite for documentation.\n",
            "inputs": [
                {
                    "type": "Directory",
                    "id": "#hhm_inputs_scatter.cwl/database"
                },
                {
                    "type": "string",
                    "id": "#hhm_inputs_scatter.cwl/database_name"
                },
                {
                    "type": "int",
                    "default": 2,
                    "id": "#hhm_inputs_scatter.cwl/n_iterations"
                },
                {
                    "type": "File",
                    "id": "#hhm_inputs_scatter.cwl/protein_query_sequence"
                }
            ],
            "arguments": [
                "-i",
                "$(inputs.protein_query_sequence.path)",
                "-d",
                "$(inputs.database.path)/$(inputs.database_name)",
                "-o",
                "$(inputs.protein_query_sequence.nameroot).hhr",
                "-ohhm",
                "$(inputs.protein_query_sequence.nameroot).hhm",
                "-n",
                "$(inputs.n_iterations)"
            ],
            "outputs": [
                {
                    "type": "File",
                    "outputBinding": {
                        "glob": "*.hhm"
                    },
                    "id": "#hhm_inputs_scatter.cwl/hhm_file"
                }
            ],
            "id": "#hhm_inputs_scatter.cwl",
            "https://schema.org/author": [
                {
                    "https://schema.org/identifier": "https://orcid.org/0000-0003-0902-0086"
                }
            ],
            "https://schema.org/license": "Apache-2.0",
            "https://schema.org/mainEntity": {
                "https://schema.org/identifier": "https://bio.tools/hhsuite",
                "https://schema.org/citation": {
                    "https://schema.org/identifier": "https://doi.org/10.1186/s12859-019-3019-7"
                }
            }
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
            "doc": "PC7 features are assigned to each residue in each protein sequence. Output is a directory of files (1 per sequence).",
            "inputs": [
                {
                    "type": "Directory",
                    "format": "http://edamontology.org/format_2200",
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
            "id": "#pc7_inputs.cwl",
            "https://schema.org/mainEntity": {
                "https://schema.org/programmingLanguage": "Python",
                "https://schema.org/codeRepository": "https://github.com/RenskeW/cwl-epitope/blob/b5e31d42006fd7003716f57963646d47d1154549/tools/get_pc7_inputs.py",
                "https://schema.org/isBasedOn": [
                    {
                        "https://schema.org/additionalType": "s:SoftwareApplication",
                        "https://schema.org/name": "OPUS-TASS",
                        "https://schema.org/identifier": "https://bio.tools/opus-tass"
                    }
                ]
            }
        },
        {
            "class": "CommandLineTool",
            "baseCommand": [
                "bash"
            ],
            "doc": "Download files from the PDB in a specific format.",
            "intent": [
                "http://edamontology.org/operation_2422"
            ],
            "requirements": [
                {
                    "networkAccess": true,
                    "class": "NetworkAccess"
                }
            ],
            "inputs": [
                {
                    "doc": "Comma-separated .txt file with pdb entries to download",
                    "type": "File",
                    "format": "https://www.iana.org/assignments/media-types/text/csv",
                    "inputBinding": {
                        "position": 3,
                        "prefix": "-f"
                    },
                    "id": "#pdb_batch_download.cwl/input_file"
                },
                {
                    "type": "boolean",
                    "inputBinding": {
                        "position": 4,
                        "prefix": "-c"
                    },
                    "default": true,
                    "id": "#pdb_batch_download.cwl/mmcif_format"
                },
                {
                    "type": "boolean",
                    "inputBinding": {
                        "position": 9,
                        "prefix": "-m"
                    },
                    "default": false,
                    "id": "#pdb_batch_download.cwl/mr_format"
                },
                {
                    "type": "boolean",
                    "inputBinding": {
                        "position": 10,
                        "prefix": "-r"
                    },
                    "default": false,
                    "id": "#pdb_batch_download.cwl/mr_str_format"
                },
                {
                    "type": "string",
                    "inputBinding": {
                        "prefix": "-o",
                        "position": 2
                    },
                    "default": ".",
                    "doc": "Where downloaded files are stored.",
                    "id": "#pdb_batch_download.cwl/output_dir"
                },
                {
                    "type": "boolean",
                    "inputBinding": {
                        "position": 6,
                        "prefix": "-a"
                    },
                    "default": false,
                    "id": "#pdb_batch_download.cwl/pdb1_format"
                },
                {
                    "type": "boolean",
                    "inputBinding": {
                        "position": 5,
                        "prefix": "-p"
                    },
                    "default": false,
                    "id": "#pdb_batch_download.cwl/pdb_format"
                },
                {
                    "type": "File",
                    "inputBinding": {
                        "position": 1
                    },
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/pdb_batch_download.sh"
                    },
                    "id": "#pdb_batch_download.cwl/script"
                },
                {
                    "type": "boolean",
                    "inputBinding": {
                        "position": 8,
                        "prefix": "-s"
                    },
                    "default": false,
                    "id": "#pdb_batch_download.cwl/sfcif_format"
                },
                {
                    "type": "boolean",
                    "inputBinding": {
                        "position": 7,
                        "prefix": "-x"
                    },
                    "default": false,
                    "id": "#pdb_batch_download.cwl/xml_format"
                }
            ],
            "outputs": [
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "outputBinding": {
                        "glob": "*.gz"
                    },
                    "doc": "Downloaded files",
                    "id": "#pdb_batch_download.cwl/pdb_files"
                }
            ],
            "id": "#pdb_batch_download.cwl"
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "requirements": [
                {
                    "networkAccess": true,
                    "class": "NetworkAccess"
                }
            ],
            "intent": [
                "http://edamontology.org/operation_2421"
            ],
            "hints": [
                {
                    "dockerPull": "nyurik/alpine-python3-requests@sha256:e0553236e3ebaa240752b41b8475afb454c5ab4c17eb023a2a904637eda16cf6",
                    "class": "DockerRequirement"
                },
                {
                    "packages": [
                        {
                            "version": [
                                "3.9.5"
                            ],
                            "package": "python3"
                        },
                        {
                            "version": [
                                "2.25.1"
                            ],
                            "package": "requests"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "arguments": [
                "$(inputs.script.path)",
                "$(inputs.pdb_search_query.path)",
                "--outpath",
                "$(inputs.return_file)"
            ],
            "inputs": [
                {
                    "type": "File",
                    "label": "Query for PDB search API in json format",
                    "format": "https://www.iana.org/assignments/media-types/application/json",
                    "id": "#pdb_query.cwl/pdb_search_query"
                },
                {
                    "type": "string",
                    "label": "Path to output file",
                    "default": "./pdb_ids.txt",
                    "doc": "Comma-separated text file with PDB ids",
                    "id": "#pdb_query.cwl/return_file"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/pdb_query.py"
                    },
                    "id": "#pdb_query.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "File",
                    "format": "https://www.iana.org/assignments/media-types/text/csv",
                    "doc": "Comma-separated text file with returned identifiers from PDB search API",
                    "outputBinding": {
                        "glob": "$(inputs.return_file)"
                    },
                    "id": "#pdb_query.cwl/processed_response"
                }
            ],
            "doc": "\"This tool invokes a Python script which uses requests library to query PDB search API and return a comma-separated file of identifiers returned by the API.\nMore information about PDB search API: https://search.rcsb.org/index.html\"\n",
            "id": "#pdb_query.cwl",
            "https://www.schema.org/author": [
                {
                    "https://www.schema.org/identifier": "https://orcid.org/0000-0003-0902-0086"
                }
            ],
            "https://www.schema.org/mainEntity": {
                "https://www.schema.org/author": [
                    {
                        "https://www.schema.org/identifier": "https://orcid.org/0000-0003-0902-0086"
                    }
                ]
            }
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "doc": "Extract PPI annotations from BioDL.",
            "intent": [
                "http://edamontology.org/operation_0320"
            ],
            "hints": [
                {
                    "packages": [
                        {
                            "specs": [
                                "https://anaconda.org/conda-forge/pandas"
                            ],
                            "version": [
                                "1.2.4"
                            ],
                            "package": "pandas"
                        },
                        {
                            "specs": [
                                "https://pypi.org/project/PDBeCif/"
                            ],
                            "version": [
                                "1.5"
                            ],
                            "package": "pdbecif"
                        },
                        {
                            "version": [
                                "3.9.1"
                            ],
                            "package": "python"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "requirements": [
                {
                    "listing": "${\n     return [{\"entry\": {\"class\": \"Directory\", \"basename\": \"mmcif_directory\", \"listing\": inputs.mmcif_files}, \"writable\": true}]\n }\n",
                    "class": "InitialWorkDirRequirement"
                },
                {
                    "class": "InlineJavascriptRequirement"
                }
            ],
            "arguments": [
                "$(inputs.script.path)",
                "mmcif_directory",
                "$(inputs.train_dataset.path)",
                "$(inputs.test_dataset.path)",
                "--outdir",
                "$(inputs.output_directory)"
            ],
            "inputs": [
                {
                    "type": {
                        "type": "array",
                        "items": "File"
                    },
                    "id": "#ppi_annotations.cwl/mmcif_files"
                },
                {
                    "type": "string",
                    "default": "ppi_fasta",
                    "id": "#ppi_annotations.cwl/output_directory"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/ppi_annotations.py"
                    },
                    "id": "#ppi_annotations.cwl/script"
                },
                {
                    "type": "File",
                    "doc": "BioDL test set",
                    "id": "#ppi_annotations.cwl/test_dataset"
                },
                {
                    "type": "File",
                    "doc": "BioDL training set",
                    "id": "#ppi_annotations.cwl/train_dataset"
                }
            ],
            "outputs": [
                {
                    "type": "Directory",
                    "outputBinding": {
                        "glob": "$(inputs.output_directory)"
                    },
                    "id": "#ppi_annotations.cwl/ppi_fasta_files"
                }
            ],
            "id": "#ppi_annotations.cwl"
        },
        {
            "class": "CommandLineTool",
            "doc": "Preprocess SAbDab summary file.",
            "intent": [
                "http://edamontology.org/operation_2409"
            ],
            "hints": [
                {
                    "dockerPull": "amancevice/pandas:1.3.4-slim",
                    "class": "DockerRequirement"
                },
                {
                    "packages": [
                        {
                            "version": [
                                "1.3.4"
                            ],
                            "package": "pandas"
                        },
                        {
                            "version": [
                                "3.9.7"
                            ],
                            "package": "python"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "baseCommand": "python3",
            "arguments": [
                "$(inputs.script.path)",
                "$(inputs.sabdab_summary_file.path)",
                "-o",
                "$(inputs.out_file)"
            ],
            "inputs": [
                {
                    "type": "string",
                    "label": "Name of output file in which processed results are stored.",
                    "default": "SAbDab_protein_antigens_PDB_chains.csv",
                    "id": "#process_sabdab.cwl/out_file"
                },
                {
                    "type": "File",
                    "label": "Summary file downloaded from SAbDab.",
                    "format": "https://www.iana.org/assignments/media-types/text/tab-separated-values",
                    "id": "#process_sabdab.cwl/sabdab_summary_file"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/process_sabdab_summary.py"
                    },
                    "id": "#process_sabdab.cwl/script"
                }
            ],
            "outputs": [
                {
                    "type": "File",
                    "format": "https://www.iana.org/assignments/media-types/text/csv",
                    "outputBinding": {
                        "glob": "$(inputs.out_file)"
                    },
                    "id": "#process_sabdab.cwl/processed_summary_file"
                }
            ],
            "id": "#process_sabdab.cwl",
            "https://schema.org/author": [
                {
                    "class": "https://schema.org/Person",
                    "https://schema.org/name": "Renske de Wit",
                    "https://schema.org/identifier": "https://orcid.org/0000-0003-0902-0086"
                }
            ],
            "https://schema.org/license": "https://spdx.org/licenses/Apache-2.0",
            "https://schema.org/mainEntity": {
                "class": "https://schema.org/SoftwareApplication",
                "https://schema.org/license": "https://spdx.org/licenses/Apache-2.0",
                "https://schema.org/author": [
                    {
                        "class": "https://schema.org/Person",
                        "https://schema.org/name": "Katharina Waury",
                        "https://schema.org/identifier": "<Kathi's ORCID identifier>"
                    }
                ]
            }
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "inputs": [
                {
                    "type": "Directory",
                    "format": "http://edamontology.org/format_2200",
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
        },
        {
            "class": "CommandLineTool",
            "baseCommand": "python3",
            "doc": "Model training.",
            "intent": [
                "http://edamontology.org/operation_2423"
            ],
            "hints": [
                {
                    "packages": [
                        {
                            "version": [
                                "8.0.4"
                            ],
                            "package": "click"
                        },
                        {
                            "specs": [
                                "https://pypi.org/project/commentjson/"
                            ],
                            "version": [
                                "0.9.0"
                            ],
                            "package": "commentjson"
                        },
                        {
                            "version": [
                                "1.21.5"
                            ],
                            "package": "numpy"
                        },
                        {
                            "version": [
                                "3.9"
                            ],
                            "package": "python"
                        },
                        {
                            "specs": [
                                "https://pypi.org/project/tensorflow-addons/"
                            ],
                            "version": [
                                "0.17.1"
                            ],
                            "package": "tensorflow-addons"
                        },
                        {
                            "specs": [
                                "https://pypi.org/project/tensorflow-gpu/"
                            ],
                            "version": [
                                "2.9.1"
                            ],
                            "package": "tensorflow-gpu"
                        },
                        {
                            "specs": [
                                "https://pypi.org/project/tqdm/"
                            ],
                            "version": [
                                "4.64.0"
                            ],
                            "package": "tqdm"
                        }
                    ],
                    "class": "SoftwareRequirement"
                }
            ],
            "arguments": [
                "$(inputs.script.path)",
                "$(inputs.config_file.path)",
                "$(inputs.input_features.path)",
                "$(inputs.input_labels.path)"
            ],
            "inputs": [
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/model_example_params.json"
                    },
                    "doc": "Configuration file used for the model. Here: standard file, but in real workflow it should be generated from previous steps.",
                    "id": "#train_epitope_model.cwl/config_file"
                },
                {
                    "type": "Directory",
                    "id": "#train_epitope_model.cwl/input_features"
                },
                {
                    "type": "Directory",
                    "id": "#train_epitope_model.cwl/input_labels"
                },
                {
                    "type": "File",
                    "default": {
                        "class": "File",
                        "location": "file:///scistor/informatica/hwt330/cwl-epitope/tools/emulated_model.py"
                    },
                    "id": "#train_epitope_model.cwl/script"
                }
            ],
            "stdout": "training_log.txt",
            "outputs": [
                {
                    "type": "File",
                    "doc": "Output of the model containing predictions and/or performance on the test set.",
                    "id": "#train_epitope_model.cwl/train_log",
                    "outputBinding": {
                        "glob": "training_log.txt"
                    }
                }
            ],
            "id": "#train_epitope_model.cwl"
        }
    ],
    "cwlVersion": "v1.2",
    "$schemas": [
        "https://schema.org/version/latest/schemaorg-current-https.rdf",
        "https://edamontology.org/EDAM_1.25.owl"
    ]
}