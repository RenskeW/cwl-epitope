"""
date: 3 April 2022
@author: Renske de Wit

Documentation:
This script takes a file of fasta sequences, makes separate .fasta files for each query sequence in the file 
and runs them against hhblits. 

For each .fasta file, the script outputs the command:

<hhblits> -i <query>.fasta -d <database> -n 3 -Z 0 -o <query>.hhr -ohhm <query>.hhm -oa3m <query.a3m>

Outputs:
- *.fasta for each query sequence (name=pdb identifier)
- *.hhm for each query sequence

"""

import argparse
import os

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('hhblits', help='Path to hhblits', type=str)
    parser.add_argument('fasta', help='Path to file containing fasta sequences')
    parser.add_argument('database', help='Path to database')

    return parser.parse_args()

def read_fasta(fasta_path):
    """ Reads fasta file, outputs list of lists:
    [[id1, seq1], [id2, seq2], ... ]
    Code copied from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L88
    """
    files = []
    f = open(fasta_path, 'r')
    tmp = []
    for i in f.readlines():
        line = i.strip()
        if line[0] == '>':
            tmp.append(line[1:])
        else:
            tmp.append(line)
            files.append(tmp)
            tmp = []
    f.close()      
    return files

def create_fasta(file, out_path):
    """
    Create a new .fasta file for every query sequence.
    Code adapted from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L127
    """
    filename = file[0].split('.')[0]
    fasta_content = ">" + filename + '\n' + file[1]
    
    #fasta_path = os.path.join(out_path, filename+'.fasta')
    fasta_path = f"{out_path}{filename}.fasta"
  
    if not os.path.exists(fasta_path):
        f = open(fasta_path, 'w')
        f.writelines(fasta_content)
        f.close()

    return fasta_path[:-6]  # name without .fasta extension   

def read_hhm(fname,seq):
    """
    Read hhblits output and extract hhm input features for OPUS-TASS
    This function was copied from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L75
    """
    num_hhm_cols = 22
    hhm_col_names = [str(j) for j in range(num_hhm_cols)]
    with open(fname,'r') as f:
        hhm = pd.read_csv(f,delim_whitespace=True,names=hhm_col_names)
    pos1 = (hhm['0']=='HMM').idxmax()+3
    num_cols = len(hhm.columns)
    hhm = hhm[pos1:-1].values[:,:num_hhm_cols].reshape([-1,44])
    hhm[hhm=='*']='9999'
    if hhm.shape[0] != len(seq):
        raise ValueError('HHM file is in wrong format or incorrect!')
    return hhm[:,2:-12].astype(float)
    

def main():
    ## parse input arguments
    args = parse_args()

    hhblits = args.hhblits
    database = args.database
    fasta_path = args.fasta 

    out_dir = "/scistor/informatica/hwt330/cwl-epitope/hhm_features/" # Change this later!
    
    # Read fasta file, create new .fasta file for each sequence
    files = read_fasta(fasta_path)

    if not os.path.exists(out_dir):
        os.mkdir(out_dir)
    
    for file in files:
        filename = create_fasta(file, out_dir)
        seq = file[1] # the protein sequence
 
        print(f"Running {filename}.fasta against HHblits database...")

        #cmd = f"{hhblits} -i {filename}.fasta -d {database} -n 3 -Z 0 -o {filename}.hhr -ohhm {filename}.hhm"
        cmd = f"{hhblits} -i {filename}.fasta -d {database} -ohhm {filename}.hhm"


        os.system(cmd) # run the shell command
        ## The following lines were adapted from get_hhm in OPUS-TASS repo (same as create_fasta)
        if os.path.exists(f"{filename}.a3m"): # Remove the files which are not necesssary for OPUS-TASS
            os.remove(f"{filename}.a3m")
        if os.path.exists(f"{filename}.hhr"):
            os.remove(f"{filename}.hhr")

        # Extract the hhm input features from the .hhm file 
        hhm = read_hhm(f"{filename}.hhm", seq) # adapted from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py#L169
      
        # Save hhm features for this sequence, adapted from https://github.com/thuxugang/opus_tass/blob/ede95534e429da0949916aaff604cf11942264fc/inference_utils.py
        hhm_feature_outpath = f"{filename}.input"
        np.savetxt(hhm_feature_outpath, hhm, fmt="%.4f")
        
    
    print(f"Saved hhm input features for all sequences in {fasta_path} in {out_dir}.")



if __name__ == "__main__":
    main()

