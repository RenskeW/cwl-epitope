"""
DESCRIPTION:
Combine input features into 1 file per fasta sequence.

Inputs: 3 directories:
- pc7 files
- psp19 files
- hhm profiles

Outputs are stored in new directory: opus_tass_inputs
"""

import argparse
import os
import numpy as np
import pandas as pd
from pathlib import Path

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('fasta', help='Path to .fasta file containing fasta sequences.')
    parser.add_argument('hhm', help='Path to directory containing hhm profiles.')
    parser.add_argument('pc7', help='Path to directory containing pc7 features.')
    parser.add_argument('psp19', help='Path to directory containing psp19 features.')
    parser.add_argument('--outdir', help='Path to output directory.', default=".")

    return parser.parse_args()

def read_fasta(fasta_path):
    """
    Reads fasta file, returns list of lists [[pdb_id1.pdb, seq1], [pdb_id2.pdb, seq2], ... ]
    This function was copied from OPUS-TASS repository: https://github.com/thuxugang/opus_tass/blob/master/inference_utils.py
    """
    files = []

    f = open(fasta_path, 'r')
    tmp = []
    for i in f.readlines():
        line = i.strip()
        if line[0] == '>': # This function can't handle empty lines
            tmp.append(line[1:])
        else:
            tmp.append(line)
            files.append(tmp)
            tmp = []
    f.close()      
    return files

def read_hhm(fname, seq):
    """
    Adapted from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L75
    """
    #num_hhm_cols = 22 # what was originally in OPUS-TASS code
    num_hhm_cols = 23 # for some reason 22 gives an error
    
    hhm_col_names = [str(j) for j in range(num_hhm_cols)]
    with open(fname,'r') as f:
        hhm = pd.read_csv(f, delim_whitespace=True, names=hhm_col_names)

    pos1 = (hhm['0']=='HMM').idxmax()+3
    print(pos1)
    # num_cols = len(hhm.columns)
    # hhm = hhm[pos1:-1].values[:,:num_hhm_cols].reshape([-1,44])
    # hhm[hhm=='*']='9999'
    # if hhm.shape[0] != len(seq):
    #     raise ValueError('HHM file is in wrong format or incorrect!')
    # return hhm[:,2:-12].astype(float)

def make_input(file, parameters):
    """
    30hhm + 7pc + 19psp
    Adapted from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L155
    """    
    n_features = 56 # 30 hhm + 7 pc + 19 psp
    filename = file[0].split('.')[0]
    #print(filename)
    fasta = file[1]   
    
    seq_len = len(fasta)

    # Define paths
    hhm_path = Path(parameters["hhm"]) / f"{filename}.hhm"
    pc7_path = Path(parameters["pc7"]) / f"pc7_{filename}.input"
    psp19_path = Path(parameters["psp19"]) / f"psp19_{filename}.input"    
    input_path = Path(parameters["out_dir"]) / f"{filename}.inputs" # output file which stores complete set of OPUS-TASS input features
    
    #print(hhm_path)
    # Read files
    hhm = read_hhm(hhm_path, fasta)
    pc7 = pd.read_csv(pc7_path, header=None)

    #print(pc7)



    
    # pc7 = np.zeros((seq_len, 7))
    # for i in range(seq_len):
    #     pc7[i] = resname_to_pc7_dict[fasta[i]]
    
    # psp = np.zeros((seq_len, 19))
    # for i in range(seq_len):
    #     psp19 = resname_to_psp_dict[fasta[i]]
    #     for j in psp19:
    #         psp[i][j-1] = 1
    
    # input_data = np.concatenate((pssm, hhm, pc7, psp),axis=1)
    # assert input_data.shape == (seq_len, n_features)
    # np.savetxt(input_path, input_data, fmt="%.4f")


def main():
    # TODO: fix duplicate names for hhm_path etc

    args = parse_args()
    
    fasta_path = args.fasta 
    hhm_path = args.hhm
    pc7_path = args.pc7
    psp19_path = args.psp19
    out_dir = args.outdir

    # Store parameters in dictionary
    parameters = {"hhm" : hhm_path, "pc7" : pc7_path, "psp19" : psp19_path, "out_dir" : out_dir}
    
    # Create directory to store output files
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    files = read_fasta(fasta_path) # [[id1.pdb, seq1], [id2.pdb, seq2], ... ] 

    for file in files[2:]:
        make_input(file, parameters)
        #print(file)

    



if __name__ == "__main__":
    main()