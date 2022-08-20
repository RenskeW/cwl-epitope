"""
DESCRIPTION:
Combine input features into 1 file per fasta sequence.

Inputs: 4 directories:
- pc7 files
- psp19 files
- hhm profiles
- fasta: ppi fasta files

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
    parser.add_argument('fasta', help='Path to directory containing fasta sequences.')
    parser.add_argument('hhm', help='Path to directory containing hhm profiles.')
    parser.add_argument('pc7', help='Path to directory containing pc7 features.')
    parser.add_argument('psp19', help='Path to directory containing psp19 features.')
    parser.add_argument('--outdir', help='Path to output directory.', default="./opus_tass_inputs")

    return parser.parse_args()

def read_fasta(fasta_path):
    """
    Reads fasta file, returns list of lists [[pdb_id1.pdb, seq1], [pdb_id2.pdb, seq2], ... ]
    This function was adapted from OPUS-TASS repository: https://github.com/thuxugang/opus_tass/blob/master/inference_utils.py
    """
    files = []

    f = open(fasta_path, 'r')
    tmp = []
    for i in f.readlines():
        line = i.strip()
        if line[0] == '>': # This function can't handle empty lines
            tmp.append(line.split(sep='\t')[0][1:])
        elif line[0] not in '10': # if not the ppi annotations
            tmp.append(line)
            files.append(tmp)
            tmp = []
    f.close()      
    return files

def read_hhm(fname, seq):
    """
    Adapted from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L75
    """
    num_hhm_cols = 23 # 20 amino acids + extra columns
    
    hhm_col_names = [str(j) for j in range(num_hhm_cols)]
    
    with open(fname,'r') as f:
        hhm = pd.read_csv(f, delim_whitespace=True, names=hhm_col_names)

    pos1 = (hhm['0']=='HMM').idxmax()+3 # the line of the first amino acid
    
    # hhm_reshaped:
    # Trim the hhm: strip header rows and last row (empty), remove last column.
    # Reshape pd.DataFrame to np.array of nrows=len(seq) 
    # Trim excess columns such that ncols=30 (20 amino acids (= emission probabilities) + 10 transition probabilities)
    # Replace '*' with 9999 
    hhm_reshaped = hhm.iloc[pos1:-1, :num_hhm_cols-1].to_numpy().reshape([-1, 2 * (num_hhm_cols-1)])[:,2:-12]
    hhm_reshaped[hhm_reshaped=='*']='9999'
    if hhm_reshaped.shape[0] != len(seq):
        raise ValueError('HHM file is in wrong format or incorrect!')
    return hhm_reshaped.astype(float)

def make_input(file, parameters):
    """
    30hhm + 7pc + 19psp
    Adapted from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L155
    """    
    n_features = 56 # 30 hhm + 7 pc + 19 psp
    filename = file[0].split('.')[0]
    fasta = file[1]   
    
    seq_len = len(fasta)

    # Define paths
    hhm_path = Path(parameters["hhm"]) / f"{filename}.hhm"
    pc7_path = Path(parameters["pc7"]) / f"pc7_{filename}.input"
    psp19_path = Path(parameters["psp19"]) / f"psp19_{filename}.input"    
    input_path = Path(parameters["out_dir"]) / f"{filename}.inputs" # output file which stores complete set of OPUS-TASS input features  

    if os.path.exists(hhm_path) and os.path.exists(pc7_path) and os.path.exists(psp19_path):      
        # Read files and combine into one file with all the input features
        hhm = read_hhm(hhm_path, fasta)
        pc7 = np.loadtxt(pc7_path, dtype=float)
        psp = np.loadtxt(psp19_path, dtype=float)
        
        input_data = np.concatenate((hhm, pc7, psp),axis=1)

        assert input_data.shape == (seq_len, n_features)
        np.savetxt(input_path, input_data, fmt="%.4f")

        print(f"{input_path} saved.")


def main():
    # TODO: fix duplicate names for hhm_path etc

    args = parse_args()
    
    ppi_dir = args.fasta
    hhm_dir = args.hhm
    pc7_dir = args.pc7
    psp19_dir = args.psp19
    out_dir = args.outdir
    # fasta_path = "/Users/renskedewit/Documents/GitHub/cwl-epitope/test.fasta" 
    # hhm_dir = "/Users/renskedewit/Documents/GitHub/cwl-epitope/prov_output/hhm_features"
    # pc7_dir = "/Users/renskedewit/Documents/GitHub/cwl-epitope/prov_output/pc7_features"
    # psp19_dir = "/Users/renskedewit/Documents/GitHub/cwl-epitope/prov_output/psp19_features"
    # out_dir = "/Users/renskedewit/Documents/GitHub/cwl-epitope/prov_output/combined_inputs"

    # Store parameters in dictionary
    parameters = {"hhm" : hhm_dir, "pc7" : pc7_dir, "psp19" : psp19_dir, "out_dir" : out_dir}
    
    # Create directory to store output files
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    all_ppi_files = os.listdir(ppi_dir)

    for file in all_ppi_files:
        fasta_path = Path(ppi_dir) / file
        [file_content] = read_fasta(fasta_path)
        make_input(file_content, parameters)


if __name__ == "__main__":
    main()