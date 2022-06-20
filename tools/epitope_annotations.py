"""
Test script for running MMCIF2DICT in docker container.
"""

import argparse
import pandas as pd
import os

# from Bio.PDB.MMCIF2Dict import MMCIF2Dict
import locale

print(f"Pandas version: {pd.__version__}")

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('mmcif', help='Path to mmcif file.')
    # parser.add_argument('--outpath', help='Output file', default="./combined_labels")

    return parser.parse_args()

def main():
    args = parse_args()
    mmcif_file = args.mmcif
    
    # mmcif_dict = MMCIF2Dict(mmcif_file)

    print("So far everything seems to be working :)")
    os.system("python3 --version")

    # f = '/Users/renskedewit/Documents/GitHub/cwl-epitope/data/1am2.cif'
    f = mmcif_file
    with open(f, 'r', encoding="us-ascii") as ff:
        print("yay") # Renske: replaced since Biopython function is slightly different

if __name__ == "__main__":
    main()

