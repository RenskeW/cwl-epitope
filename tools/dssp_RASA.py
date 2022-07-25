"""
This script uses BioPython & DSSP to calculate surface accessiblity.

@author: DS
adapted by: RW (make script also produce secondary structure)

"""

from glob import glob
from os.path import join
import argparse
from pathlib import Path
import pandas as pd
from os import getcwd
import logging
from Bio.PDB import PDBParser
from Bio.PDB.DSSP import DSSP
import warnings


"""
"""

logging.basicConfig(level=logging.DEBUG)

def get_file_list(dir, ext=".pdb"):
    
    files_path = join(dir, "*"+ ext)
    files = glob(files_path)
    return files

def calculate_rsa(filename, rsa_cutoff, dssp_algo, output_dir):
    """Returns a list of surface exposed residues as determined by relative solvent accessibility.
    Parameters
    ---------
    filename: str
        Name of pdb file to be analyzed
    model: :class:`Bio.PDB.Model.Model`
        Model under analysis
    rsa_cutoff: float
        Cutoff for buried/surface exposed
    """
    p = PDBParser()

    name = filename.split('/')[-1]
    name = name.split('.')[0]

    structure = p.get_structure(name.upper(), filename)
    model = structure[0]
    
    surface_exposed_res = []
    surface_exposed_score = []
    amino_acid = []
    # phi = []
    # psi = []
    ss = []

    try:
        dssp = DSSP(model, filename, dssp=dssp_algo)
        for key in dssp.keys():
            
            if  dssp[key][3] >= rsa_cutoff:
                surface_exposed_res.append(1)
            else:
                surface_exposed_res.append(0)
                
            surface_exposed_score.append(dssp[key][3])
            amino_acid.append(dssp[key][1])

            ## Also extract phi/psi + secondary structure:
            ss.append(dssp[key][2])
            # phi.append(dssp[key][4])
            # psi.append(dssp[key][5])


        df = pd.DataFrame({"amino_acid": amino_acid, "RASA_score": surface_exposed_score, "RASA_bool": surface_exposed_res, "secondary_structure": ss})

        dest = join(output_dir, name+'_RASA.csv')
        df.to_csv(dest, index=False)

    except Exception:
        warnings.warn("Unable to calculate solvent accessibility. Check that DSSP is installed. Omitting " +filename,
                      RuntimeWarning,
                      stacklevel=2)
    
def main(args):
    source = args.source
    output = args.output

    files = get_file_list(source)
    print("The file list as input for dssp_RASA.py is:\n")
    print(files)
    Path(output).mkdir(parents=True, exist_ok=True)
    for file in files:
        calculate_rsa(filename=file,rsa_cutoff=args.cutoff,dssp_algo=args.dssp,output_dir=output)

        
    return 0

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=str, help = "path to directory containing pdb files with extension .pdb")
    parser.add_argument("--output",'-o', type=str, help = "Destinition  for output (default is current directory + dssp_scores)", default = join(getcwd(), 'dssp_scores'))
    parser.add_argument("--dssp", "-d", type=str, help="DSSP algorothim to use, default = mkdssp", default = "mkdssp")
    parser.add_argument("--cutoff", "-c", type=float, help = "cutoff value for accesibility bool for Relative Accesible Surface Area, defaut = 0.06", default = 0.06)
    args = parser.parse_args()
    main(args)
