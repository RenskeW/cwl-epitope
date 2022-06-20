"""
This script combines the separately generated labels (epitope annotations, PPI annotations, secondary structure and surface accessibility into 1 file per protein sequence. 
The generated files are later used as input for model training.

@author: Renske de Wit
@dateCreated: 2022-05-27

Inputs:
- Directory of epitope annotation files (.fasta files)
- Directory of PPI annotation files (.fasta files)
- Directory of DSSP output files (<pdb_id>_RASA.csv)

Output:
- Directory of files, where each file corresponds to 1 protein sequence (nrows=len(seq), ncols = 1 epitope + 1 PPI + 1 BU + 1 SA + 3 SS)

python3 combine_labels.py /Users/renskedewit/Documents/GitHub/cwl-epitope/data/test_set/epitope_fasta /Users/renskedewit/Documents/GitHub/cwl-epitope/data/test_set/ppi_fasta /Users/renskedewit/Documents/GitHub/cwl-epitope/data/test_set/dssp_scores --outdir /Users/renskedewit/Documents/GitHub/cwl-epitope/data/test_set/combined_labels
"""

import os
import pandas as pd
import argparse
from pathlib import Path
import platform

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('epitope_dir', help='Path to directory with epitope annotations in fasta format.')
    parser.add_argument('ppi_dir', help='Path to directory with PPI annotations in fasta format.')
    parser.add_argument('dssp_dir', help='Path to directory with DSSP output.')
    parser.add_argument('--outdir', help='Path to output directory.', default="./combined_labels")

    return parser.parse_args()

# def get_files(dir, ext=""):
#     path = str(Path(dir) / f"*{ext}")
#     files = glob(path)
#     return files

def print_versions():
    print(f"Packages in execution of {__file__}:")
    print(f"pandas version: {pd.__version__}")
    print(f"System information:")
    print(f"{os.name}")
    print(f"Python version: {platform.python_version()}")
    print(f"{platform.processor()}")
    print(f"{platform.platform()}")

def extract_interaction_labels(fasta_file):
    """
    Extracts the binary epitope and ppi annotations from the previously generated fasta files in epitope_dir and/or ppi_dir.   
    
    fasta_file format (3 lines): 

    >1HEZ_E                                                             (pdb identifier + optionally UNP <uniprot_id>)
    EVTIKVNLIFADGKIQTAEFKGTFEEATAEAYRYADLLAKVNGEYTADLEDGGNHMNIKFA       (protein sequence)
    0000000000000000000000011001100110011000000011111101100000000       (ppi/epitope annotations)
    
    """
    # Return None if there are no annotations
    if fasta_file is None:
        return None, None
    
    with open(fasta_file, 'r') as f:
        lines = f.readlines()
        annotations = lines[2].strip()
        annotations_list = [float(c) for c in annotations] # split into list
        fasta = lines[1].strip()
        return annotations_list, fasta

def extract_secondary_structure_labels(ss: pd.Series):
    """
    Converts secondary structure information from dssp output into binary values.

    From Bio.PDB.DSSP documentation (https://biopython.org/docs/1.75/api/Bio.PDB.DSSP.html):

    H = alpha helix
    B = isolated beta-bridge residue
    E = strand
    G = 3-10 helix
    I = Pi helix
    T = turn
    S = Bend
    - = None

    Following Xu et al (2020), for ss3: coil = None, S, T ; a_helix = H, G, I ; b_strand = E, B
    """

    ss_df = pd.DataFrame(data = {"ss": ss, "value":[1]*len(ss)})

    ss8 = pd.pivot(ss_df, columns="ss", values="value").fillna(0)

    for c in "HBEGITS-":
        if c not in ss8.columns:
            ss8[c] = 0.0

    assert all(ss8.sum(axis=1)) == 1 # Make sure that only 1 type of ss8 is assigned per residue

    # Convert to ss3 labels:
    ss3 = pd.DataFrame(data = {
        "dssp_coil": ss8[["-", "S", "T"]].sum(axis=1), 
        "dssp_a_helix": ss8[["H", "G", "I"]].sum(axis=1),
        "dssp_b_strand": ss8[["E", "B"]].sum(axis=1)
        })

    assert all(ss3.sum(axis=1)) == 1 # Make sure that only 1 type of ss3 is assigned per residue

    new_columns = [f"ss8_{c}" if c != "-" else "ss8_none" for c in ss8.columns] # the order of columns is preserved

    ss8 = ss8.rename(columns = {ss8.columns[i]: new_columns[i] for i in range(len(new_columns))} )
    
    return ss8, ss3

def compare_protein_sequences(dssp_seq, ppi_seq, epitope_seq):
    """
    Compares the protein sequences of the FASTA files and retrieved from BioDL. 
    """
    pass

def labels_to_generate(epitope_files, ppi_files):
    """
    Takes 2 lists of files and extracts the chains for which to generate labels.
    """
    all_files = epitope_files + ppi_files
    chains = []
    for f in all_files:
        chain = f.split('.')[0].split('_')[-1]
        if not chain in chains:
            chains.append(chain)
    return chains

def process_dssp_output(dssp_output, protein_chain):
    """Only use the part of DSSP output which overlaps with the protein chain for which we have ppi/epitope annotations"""

    # Temporary hack:
    dssp_subset = dssp_output.loc[:len(protein_chain), :]

    return dssp_subset

def main():
    args = parse_args()
    epitope_dir = args.epitope_dir
    ppi_dir = args.ppi_dir
    dssp_dir = args.dssp_dir
    out_dir = args.outdir

    print_versions() 
    
    # Create output directory
    if not os.path.exists(out_dir): # Maybe introduce some safeguards here to avoid overwriting existing files.
        os.mkdir(out_dir)

    # The order of the labels in Henriette's model + epitope annotations = 37 labels in total
    columns = ['ss8_none', 'ss8_S', 'ss8_T', 'ss8_H', 'ss8_G', 'ss8_I', 'ss8_E', 'ss8_B', # 8-category secondary structure, order is manually checked with .labels files
                'csf_1', 'csf_2', 'csf_3', 
                'phipsi_1', 'phipsi_2', 'phipsi_3', 'phipsi_4', 
                'dihedrals_1', 'dihedrals_2', 'dihedrals_3', 'dihedrals_4', 
                'dihedrals_4', 'dihedrals_6', 'dihedrals_7', 'dihedrals_8', 
                'asa',                                                              # is this relative asa (dssp output?)
                'real_phi', 'real_psi', 'real_x1', 'real_x2', 'real_x3', 'real_x4', # real_phi / real_psi are dssp output??
                'dssp_coil', 'dssp_a_helix', 'dssp_b_strand',                       # dssp output; 3-category secondary structure
                'buried', 'non_buried',                                             # dssp output, determined by rsa_cutoff
                'ppi_res',                                                          # extracted from BioDL
                'epitope']                                                          # processed from SAbDab metadata

    all_dssp_files = os.listdir(dssp_dir)
    epitope_files = os.listdir(epitope_dir)
    ppi_files = os.listdir(ppi_dir)
    

    
    lost_proteins = []

    for file in all_dssp_files: # loop through the dssp output files
        dssp_path = Path(dssp_dir) / file

        if not file.endswith('.csv'):
            continue

        # find the pdb id
        pdb_id = dssp_path.stem.split(sep="_")[0].upper() # retrieve the pdb id from the filename as uppercase

        # dssp output
        dssp_output = pd.read_csv(dssp_path)
        dssp_output["secondary_structure"] = 'H' # temporary hack
        
        ss8_labels, ss3_labels = extract_secondary_structure_labels(dssp_output["secondary_structure"])
        dssp_seq = "".join([aa for aa in dssp_output["amino_acid"]])
        print(f"Length {pdb_id}: {len(dssp_seq)}")
        
        # for which chains do we need to produce labels?
        epitope_f = [f for f in epitope_files if f.startswith(pdb_id)]
        ppi_f = [f for f in ppi_files if f.startswith(pdb_id)]

        chains = labels_to_generate(epitope_f, ppi_f)

        # loop over chains
        for chain in chains:
            pdb_chain = f"{pdb_id}_{chain}"
            ppi_file = Path(ppi_dir) / f"{pdb_chain}.fasta" if f"{pdb_chain}.fasta" in ppi_files else None
            epitope_file = Path(epitope_dir) / f"{pdb_chain}.fasta" if f"{pdb_chain}.fasta" in epitope_files else None

            # annotations
            epitope_annotations, epitope_fasta = extract_interaction_labels(epitope_file)
            ppi_annotations, ppi_fasta = extract_interaction_labels(ppi_file)

            if not (epitope_fasta == None or ppi_fasta == None):
                if not epitope_fasta == ppi_fasta:
                    print(f"Epitope and ppi protein sequences do not correspond for {pdb_chain}.")
                    lost_proteins.append(pdb_chain)
                    #continue

            if not epitope_fasta == None and epitope_fasta != dssp_seq:
                print(f"epitope & dssp seq don't correspond for {pdb_chain}")
            if not ppi_fasta == None and ppi_fasta != dssp_seq:
                print(f"ppi & dssp seq don't correspond for {pdb_chain}")

            # Only use the subset of DSSP output which is relevant for this protein chain        
            if not ppi_fasta is None:
                dssp_output_subset = process_dssp_output(dssp_output, ppi_fasta)
            else:
                dssp_output_subset = process_dssp_output(dssp_output, epitope_fasta)


            # add to dataframe
            combined_data = pd.DataFrame(columns=columns)
            combined_data["epitope"] = epitope_annotations
            combined_data["ppi_res"] = ppi_annotations
            combined_data["asa"] = dssp_output_subset["RASA_score"]
            combined_data["buried"] = dssp_output_subset["RASA_bool"].astype(float)
            combined_data["non_buried"] = (dssp_output_subset["RASA_bool"] == 0).astype(float)

            for col in ss8_labels.columns:
                combined_data[col] = ss8_labels[col]
            for col in ss3_labels.columns:
                combined_data[col] = ss3_labels[col]

            assert len(combined_data.columns) == len(columns)

            # Fill missing data & round to 4 decimal values
            combined_data = combined_data.fillna("None") # this is wrong
            # Write combined labels to output directory
            out_file = Path(out_dir) / f"{pdb_chain}.labels"
            combined_data.to_csv(out_file, index=False, sep="\t", float_format="%.4f")



    print(f"Number of lost proteins: {len(lost_proteins)}\n{lost_proteins}")


if __name__ == "__main__":
    main()