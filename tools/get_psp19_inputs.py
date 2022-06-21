"""
Definition:
Generation of PSP19 input features.

Inputs: 
- *.fasta: file containing fasta sequences in ??? format
- name of output directory to store script output. Will be created if it doesn't exist already.


Outputs: 
- *.input files for every sequence in the .fasta file.

"""

import argparse
import os
#import sys
import numpy as np
from pathlib import Path

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Generates PC7 features for every sequence in .fasta file.')
    
    # Arguments
    parser.add_argument('fasta', help='Path to .fasta file containing fasta sequences.')
    parser.add_argument('-o', dest='out_path', help='Path to output directory. This argument is required!', required=True)

    return parser.parse_args()

def read_fasta_dir(fasta_dir, ext=".fasta"):
    """
    Adapted from read_fasta() in OPUS-TASS repository: https://github.com/thuxugang/opus_tass/blob/master/inference_utils.py
    Reads directory of FASTA files, returns list of lists [[pdb_id1.pdb, seq1], [pdb_id2.pdb, seq2], ... ]
    format FASTA files:
    > header        # > pdbID \t uniprotID
    FASTASEQUENCE
    0011011010100 # possibly annotations
    """
    fasta_files = os.listdir(fasta_dir)
    seq_list = []
    for file in fasta_files:
        
        if not file.endswith(ext):
            continue
        
        path = Path(fasta_dir) / file
        tmp = []
        f = open(path, 'r')
        for i in f.readlines():
            line = i.strip()
            if line[0] == '>': # header
                tmp.append(line[1:].split(sep='\t')[0]) # the PDB ID header, not the UniProt ID
            elif line[0] not in "0 1": # we don't want the annotations
                tmp.append(line)
                seq_list.append(tmp)
    
    return seq_list

def get_psp_dict():
    """
    Returns dictionary of PSP19 features per amino acid type.
    This function was copied from OPUS-TASS Github repo https://github.com/thuxugang/opus_tass/blob/master/inference_utils.py
    """   
    resname_to_psp_dict = {}
    resname_to_psp_dict['G'] = [1,4,7]
    resname_to_psp_dict['A'] = [1,3,7]
    resname_to_psp_dict['V'] = [1,7,12]
    resname_to_psp_dict['I'] = [1,3,7,12]
    resname_to_psp_dict['L'] = [1,5,7,12]
    resname_to_psp_dict['S'] = [1,2,5,7]
    resname_to_psp_dict['T'] = [1,7,15]
    resname_to_psp_dict['D'] = [1,5,7,11]
    resname_to_psp_dict['N'] = [1,5,7,14]
    resname_to_psp_dict['E'] = [1,6,7,11]
    resname_to_psp_dict['Q'] = [1,6,7,14]
    resname_to_psp_dict['K'] = [1,5,6,7,10]
    resname_to_psp_dict['R'] = [1,5,6,7,13]
    resname_to_psp_dict['C'] = [1,7,8]
    resname_to_psp_dict['M'] = [1,6,7,9]
    resname_to_psp_dict['F'] = [1,5,7,16]
    resname_to_psp_dict['Y'] = [1,2,5,7,16]
    resname_to_psp_dict['W'] = [1,5,7,18]
    resname_to_psp_dict['H'] = [1,5,7,17]
    resname_to_psp_dict['P'] = [7,19]
    return resname_to_psp_dict

def make_psp19(file, resname_to_psp_dict):
    """
    This function was adapted from make_input() from OPUS-TASS Github repo https://github.com/thuxugang/opus_tass/blob/master/inference_utils.py
    Assigns 19 PSP19 features (binary) to each residue in the the sequence.
    """    
    filename = file[0].split('.')[0] # PDB ID
    fasta = file[1]  # fasta sequence  
    
    seq_len = len(fasta)

    psp = np.zeros((seq_len, 19))

    for i in range(seq_len):
        psp19 = resname_to_psp_dict[fasta[i]]
        for j in psp19:
            psp[i][j-1] = 1
 
    assert psp.shape == (seq_len,19)
    return psp, filename
    

def main():
    args = parse_args() 
    fasta_path = args.fasta
    out_path = args.out_path

    files = read_fasta_dir(fasta_path) 

    # Create directory to store output files
    if not os.path.exists(out_path):
        os.mkdir(out_path)
        print(f"Created new directory {out_path} to store PSP19 input features.")
    else:
        print(f"Using existing directory {out_path} to store PSP19 input features.")

    # Create PSP19 dictionary
    resname_to_psp_dict = get_psp_dict()

    # Loop through sequences, assign pc7 features to each residue in each sequence.
    for file in files:
        psp19, filename = make_psp19(file, resname_to_psp_dict)

        # Save PSP19 features for this sequence
        psp19_path = f"{out_path}/psp19_{filename}.input"

        np.savetxt(psp19_path, psp19, fmt="%.4f")
        
    print(f"Saved PSP19 input features for all sequences in {fasta_path} in {out_path}.")
    
    
if __name__ == "__main__":
    main()
