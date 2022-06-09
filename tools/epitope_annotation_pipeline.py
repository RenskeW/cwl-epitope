"""# -*- coding: utf-8 -*-"""
"""
Created on Thu Feb 10 11:42:00 2022

@author: Katharina Waury (k.waury@vu.nl)
"""

# notes Renske:
# version pdecif: pdbecif-1.5

import argparse
from pathlib import Path

import numpy as np
import os
import pandas as pd
import time

from pdbecif.mmcif_io import MMCIF2Dict

# from Bio.PDB.MMCIF2Dict import MMCIF2Dict


#### functions ####
def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Extracts epitope annotations from mmCIF files.')
    
    # Arguments
    parser.add_argument('pdb_dir', help='Path to directory with mmCIF files.')
    parser.add_argument('sabdab_chains', help='Path to csv file processed from SAbDab summary file.')
    parser.add_argument('--fasta_directory', help='Path to directory where FASTA output files will be stored.', default='./FASTA')
    parser.add_argument('--df_directory', help='Path to directory where output dataframes will be stored.', default="./df_directory")

    return parser.parse_args()

def define_chains(pdb_id, sabdab_chains_df):
    """
    """
    entry = sabdab_chains_df[sabdab_chains_df["pdb"] == pdb_id].values[0]
    
    Hchain = entry[1]
    Lchain = entry[2]
    
    # check if antigen has more than one chain
    if len(entry[3]) > 1:
        antigen_chain = entry[3].split(" | ")
    else:
        antigen_chain = list(entry[3])

    return Hchain, Lchain, antigen_chain 


def create_coordinate_dict(atom_df):
    """
    """
    coordinate_dict = {}
    for res in atom_df["id"]:
        coordinate_dict[res] = np.array([float(atom_df[atom_df["id"] == res]["Cartn_x"].values[0]), \
                                float(atom_df[atom_df["id"] == res]["Cartn_y"].values[0]), \
                                float(atom_df[atom_df["id"] == res]["Cartn_z"].values[0])])
    return coordinate_dict


def calculate_distance(atom1, atom2):
    """
    """
    distance = np.sqrt(np.sum((atom1 - atom2) ** 2, axis=0))
    return distance


def create_FASTA_file(pdb_id, seq_list, epitope_annotation_list, chain, directory):
    """
    """
    
    # create file to write to
    filename = pdb_id + "_" + chain + ".fasta"
#     print(filename)
    f = open(Path(directory) / filename, "w") # Renske changed this

    # add FASTA header
    f.write(">" + pdb_id + "_" + chain + "\n")


    # create strings of list elements
    seq_str = "".join(seq_list)
    epitope_annotation_seq = "".join(epitope_annotation_list)
    
    # add sequence and annotation line
    f.write(seq_str + "\n")
    f.write(epitope_annotation_seq + "\n")

    f.close()

    return None


def create_dataframe(pdb_id, res_list, seq_list, epitope_annotation_list, chain, directory):
    """
    """
#     df_directory = os.getcwd() + "/Data/dataframes/"
    # set directory, create if it does not exist yet
#    try:
#        os.mkdir(directory)
#    except FileExistsError:
#        pass
    
    # create file to write to
    chain_name = pdb_id + "_" + chain
    filename = chain_name + ".csv"
#     print(filename)
    
    filepath = Path(directory) / filename # Renske changed this
#     print(filepath)
    
    # create dictionary of lists 
    results_dict = {"PDB": [chain_name] * len(res_list), 
                    "residue_number": res_list, 
                    "residue": seq_list, 
                    "epitope": epitope_annotation_list} 

    # create dataframe from dictionary
    df = pd.DataFrame(results_dict)
    
    # save dataframe to csv
    df.to_csv(filepath, index=False)
    
    return df  


def create_epitope_annotation(pdb_id, pdb_atom_df, Hchain, Lchain, antigen_chain, df_directory, fasta_directory, 
                              min_distance=4):
    """
    """

    three_to_one = {
        "ALA" : "A",
        "CYS" : "C",
        "ASP" : "D",
        "GLU" : "E",
        "PHE" : "F",
        "GLY" : "G",
        "HIS" : "H",
        "ILE" : "I",
        "LYS" : "K",
        "LEU" : "L",
        "MET" : "M",
        "ASN" : "N",
        "PRO" : "P",
        "GLN" : "Q",
        "ARG" : "R",
        "SER" : "S",
        "THR" : "T",
        "VAL" : "V",
        "TRP" : "W",
        "TYR" : "Y",
	"UNK" : "X"
        }
    
    # create coordinate dictionaries of H and L chain
    Hchain_atom_df = pdb_atom_df[pdb_atom_df["auth_asym_id"] == Hchain]
    Hchain_coordinate_dict = create_coordinate_dict(Hchain_atom_df)
    Lchain_atom_df = pdb_atom_df[pdb_atom_df["auth_asym_id"] == Lchain]
    Lchain_coordinate_dict = create_coordinate_dict(Lchain_atom_df)
    
    # loop over antigen chain(s)
    for chain in antigen_chain:
#         print("Chain:", chain)
        
        # retrieve atom information for antigen chain, ignore HETATOMs
        antigen_chain_atom_df = pdb_atom_df[(pdb_atom_df["auth_asym_id"] == chain) &
                                               (pdb_atom_df["group_PDB"] == "ATOM")]  
        
        # create empty or 0-filled lists to save residue numbers, residues and epitope annotation
        res_list = []
        seq_list = []
        epitope_annotation_list = ["0"] * len(antigen_chain_atom_df["label_seq_id"].unique())
        
        # loop over residues within one antigen chain
        for i, res in enumerate(antigen_chain_atom_df["label_seq_id"].unique()):
            
            # set default epitope status to False
            is_epitope = False
            
            # add residue number to residue list
            res_list.append(res)
            # retrieve amino acid one letter code and add to sequence list
            amino_acid = antigen_chain_atom_df[antigen_chain_atom_df["label_seq_id"] == res]["label_comp_id"].values[0]
            seq_list.append(three_to_one[amino_acid])

            # subset data frame for current residue
            res_atom_df = antigen_chain_atom_df[antigen_chain_atom_df["label_seq_id"] == res]
            
            # loop over atom within one residue
            for atom in res_atom_df["id"].unique():              # TO DO: remove "."?
                
                # retrieve coordiantes of antigen atom
                atom1 = np.array([float(res_atom_df[res_atom_df["id"] == atom]["Cartn_x"].values[0]), \
                         float(res_atom_df[res_atom_df["id"] == atom]["Cartn_y"].values[0]), \
                         float(res_atom_df[res_atom_df["id"] == atom]["Cartn_z"].values[0])])
                
                # compare distance between antigen atoms and heavy chain atoms
                for k in Hchain_coordinate_dict:
                    atom2 = Hchain_coordinate_dict[k]
                    # check distance for selected antigen residue with antibody chains
                    distance = calculate_distance(atom1, atom2)                    
                    # if distance between two atoms is below minimum distance, set epitope annotation to True
                    if distance < min_distance:
                        is_epitope = True
                        # skip rest of heavy chain
                        break
                
                # only check light chain distance if epitope annotation is False
                if is_epitope == False:
                    # compare distance between antigen atoms and light chain atoms                                
                    for k in Lchain_coordinate_dict:
                        atom2 = Lchain_coordinate_dict[k]
                        # check distance for selected antigen residue with antibody chains
                        distance = calculate_distance(atom1, atom2)
                        if distance < min_distance:
                            is_epitope = True
                            # skip rest of light chain
                            break
                
                if is_epitope == True:
                    epitope_annotation_list[i] = "1"
                    # if distance of one atom in current residue is below minimum distance, skip to next residue
                    break
            
        # TO DO: test if all lists have same length, could also move to create_FASTA_file
        
#         print(res_list)
#         print(len(res_list))           
#         print(seq_list)
#         print(len(seq_list))        
#         print(epitope_annotation_list)
#         print(len(epitope_annotation_list))
        
        # TO DO: Check if there are any epitopes in chain, otherwise skip?
        
        # create data frame of antigen chain with epitope annotation
        create_dataframe(pdb_id, res_list, seq_list, epitope_annotation_list, chain, df_directory)
        
        # create FASTA file of antigen chain with epitope annotation
        create_FASTA_file(pdb_id, seq_list, epitope_annotation_list, chain, fasta_directory)
        
    # for multi-chain antigens would only return last chain
#     return None
    return res_list, seq_list, epitope_annotation_list    
                    

def run_pipeline(sabdab_chains_df, path_dict):   
    # Renske: added path_dict
    """
    """
    biopython = False
    # set fasta directory, create if it does not exist yet
    # fasta_directory = "/scistor/informatica/kwy700/epitope_annotation_pipeline/results/FASTA/"
    fasta_directory = path_dict["fasta_dir"] 
    df_directory = path_dict["df_dir"] 
    pdb_directory = path_dict["pdb_dir"]

    try:
        os.makedirs(fasta_directory)
    except FileExistsError:
        pass    
    
    # set dataframe directory, create if it does not exist yet
    # df_directory = "/scistor/informatica/kwy700/epitope_annotation_pipeline/results/dataframes/"
    try:
        os.makedirs(df_directory)
    except FileExistsError:
        pass
    
    # loop over files in PDB directory
    for pdb_file in os.listdir(pdb_directory): # added [:2]
	
        start_time = time.time()

        # create path to files in directory
        # f = os.path.join(pdb_directory, pdb_file)
        f = Path(pdb_directory) / pdb_file
#         # checking if it is a file
#         if os.path.isfile(f):
#             print(f)
    
        # initiate PDB file parser
        mmcif_dict = MMCIF2Dict()
        cif_dict = mmcif_dict.parse(f)
        # with open(f, 'r', encoding="us-ascii") as ff:
        #     cif_dict = MMCIF2Dict(ff) # Renske: replaced since Biopython function is slightly different
        if biopython:
            cif_dict = MMCIF2Dict(f)
            [pdb_id] = cif_dict["_entry.id"] # Renske: changed this
        
        pdb_id = next(iter(cif_dict))
        print(pdb_id, flush=True)
        
        
        # skip if PDB ID doesn't exist
        if pdb_id not in sabdab_chains_df["pdb"].values:
            print("PDB ID %s not found in SAbDab summary file and will be skipped." %(pdb_id))
            continue # skip this PDB file
        
        # pdb_id = pdb_id.lower() # renske changed this
        pdb_dict = cif_dict[pdb_id]
        
        Hchain, Lchain, antigen_chain = define_chains(pdb_id, sabdab_chains_df)
#        print(Hchain, Lchain, antigen_chain)
        pdb_atom_df = pd.DataFrame.from_dict(pdb_dict["_atom_site"])
	
        # skip if results files already exist
        if os.path.isfile(fasta_directory + pdb_id + "_" + antigen_chain[0] + ".fasta"):
            continue

        # create list of all epitope residues on antigen chain(s)
        create_epitope_annotation(pdb_id, pdb_atom_df, Hchain, Lchain, antigen_chain, df_directory, fasta_directory)
        end_time = time.time()

        duration = end_time - start_time
        print(duration, flush=True)

    return None



def main():
    args = parse_args()
    pdb_directory = args.pdb_dir
    sabdab_chains = args.sabdab_chains
    df_directory = args.df_directory
    fasta_directory = args.fasta_directory
    # pdb_directory = "/scistor/informatica/kwy700/epitope_annotation_pipeline/PDB/antigen_antibody_complexes/"
    # sabdab_chains_df = pd.read_csv("SAbDab_protein_antigens_PDB_chains.csv")
    path = "/Users/renskedewit/Documents/Bioinformatics_Systems_Biology/CWLproject/learn-git/epitope_annotation/"
    # pdb_directory = path + "pdb_directory/"
    # df_directory = path + "results/df_directory/"
    # fasta_directory = path + "results/FASTA/"
    # sabdab_chains_df = pd.read_csv(path + "SAbDab_protein_antigens_PDB_chains.csv")

    sabdab_chains_df = pd.read_csv(sabdab_chains)


    
    path_dict = {
        "pdb_dir": pdb_directory,
        "df_dir": df_directory,
        "fasta_dir": fasta_directory
    }
    # print(path_dict)
    # directory = os.getcwd() + "/antigen_antibody_complexes/"
    # run_pipeline(pdb_directory, sabdab_chains_df)
    run_pipeline(sabdab_chains_df, path_dict)

# def test_function():
#     args = parse_args()
#     mmcif_dir = args.pdb_dir

#     mmcif = Path(mmcif_dir) / "1am2.cif"

#     cif_dict = MMCIF2Dict(mmcif)

if __name__ == "__main__":
    main()
