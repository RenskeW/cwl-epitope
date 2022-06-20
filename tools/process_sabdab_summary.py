"""
This script processes the summary file downloaded from SAbDab.

Inputs:
- SAbDab summary file (.tsv)

Outputs:
- Processed summary file (.csv)
"""

import argparse
import pandas as pd
import os
import platform


def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Script processes summary file from SAbDab.')
    
    # Arguments
    parser.add_argument('summary_file', help='Path to summary file downloaded from SAbDab.')
    parser.add_argument('-o', dest='out_file', help='Path to output file.', default="./SAbDab_protein_antigens_PDB_chains.csv")

    return parser.parse_args()

def print_versions():
    print(f"Packages in execution of {__file__}:")
    print(f"pandas version: {pd.__version__}")
    print(f"System information:")
    print(f"{os.name}")
    print(f"Python version: {platform.python_version()}")
    print(f"{platform.processor()}")
    print(f"{platform.platform()}")

def create_summary_SAbDab_entries(df_in, onlypaired=True, output_dir=None):
    """
    Takes a SAbDab summary as input.
    Removes all entries without sufficient information.
    Outputs a dataframe with an entry for every unique PDB ID with one combination of L, H and antigen chain.
    Saves the dataframe to a csv file if directory is specified.
    """
    
    # drop entries without antigen chain, type or species information
    df_in.dropna(axis=0, subset=["antigen_chain", "antigen_type", "antigen_species"], inplace=True)
    
    # drop entries without paired L and H chain 
    if onlypaired == True:
        df_in.dropna(axis=0, subset=["Hchain", "Lchain"], inplace=True)
        
    # drop entries solved by NMR
    df_in = df_in[df_in["method"].isin(["X-RAY DIFFRACTION", "ELECTRON MICROSCOPY"])]
    
    # remove duplicate PDB entries
    df_in.drop_duplicates(subset=["pdb"], inplace=True)
    
    # keep only relevant columns
    df = df_in.copy()[["pdb", "Hchain", "Lchain", "antigen_chain"]]
    
    # convert PDB IDs to upper case
    df["pdb"] = df["pdb"].apply(lambda x: x.upper())
    
    # drop PDB ID that contains nucleotide antigen
    df = df[df["pdb"] != "6CF2"]
    
    # save dataframe to csv
    if output_dir != None:
        try:
            df.to_csv(path_or_buf=output_dir, index=False)
            print("File saved.")
            return df
        except IOError: 
            print("Directory not found. File not saved.")
            return df
    else:
        return df

def main():
    args = parse_args()

    print_versions()

    summary_file = args.summary_file # tsv file
    out_file = args.out_file
    
    SAbDab_protein_antigens = pd.read_csv(summary_file, sep="\t")

    result_df = create_summary_SAbDab_entries(SAbDab_protein_antigens, output_dir=out_file)


if __name__ == "__main__":
    main()