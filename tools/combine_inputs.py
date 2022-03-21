"""
DESCRIPTION:
Combine input features into 1 file per fasta sequence.

Inputs: 4 directories:
- pc7 files
- psp19 files
- hhm profiles
- pssm profiles

Outputs are stored in new directory: opus_tass_inputs
"""

import argparse
import os
#import sys
import numpy as np

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('fasta', help='Path to .fasta file containing fasta sequences.')
    parser.add_argument('pssm', help='Path to directory containing pssm features.')
    parser.add_argument('hhm', help='Path to directory containing hhm features')
    parser.add_argument('pc7', help='Path to directory containing pc7 features.')
    parser.add_argument('psp19', help='Path to directory containing psp19 features.')
    parser.add_argument('-o', dest='out_path', help='Path to output directory. This argument is required!', required=True)

    return parser.parse_args()


# Function copied from OPUS-TASS GitHub repository
def make_input(file, preparation_config):
    """
    20pssm + 30hhm + 7pc + 19psp
    """    
    filename = file[0].split('.')[0]
    fasta = file[1]   
    
    seq_len = len(fasta)

    pssm_path = os.path.join(preparation_config["tmp_files_path"], filename+'.pssm')
    hhm_path = os.path.join(preparation_config["tmp_files_path"], filename+'.hhm')
    input_path = os.path.join(preparation_config["tmp_files_path"], filename+'.inputs')
    
    pssm = read_pssm(pssm_path, fasta)
    hhm = read_hhm(hhm_path, fasta)
    
    pc7 = np.zeros((seq_len, 7))
    for i in range(seq_len):
        pc7[i] = resname_to_pc7_dict[fasta[i]]
    
    psp = np.zeros((seq_len, 19))
    for i in range(seq_len):
        psp19 = resname_to_psp_dict[fasta[i]]
        for j in psp19:
            psp[i][j-1] = 1
    
    input_data = np.concatenate((pssm, hhm, pc7, psp),axis=1)
    assert input_data.shape == (seq_len,76)
    np.savetxt(input_path, input_data, fmt="%.4f")
