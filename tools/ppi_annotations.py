"""
Script which extracts protein sequence and UniProt ID from mmcif files, extracts ppi annotations from BioDL and writes them to fasta files.
@author: Renske de Wit
@dateCreated: 2022-06-03
"""
from pathlib import Path
import pdbecif
from pdbecif.mmcif_io import MMCIF2Dict
import pandas as pd
import argparse
import os
import platform

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('mmcif_dir', help='Path to directory with epitope annotations in fasta format.')
    parser.add_argument('biodl_train', help='Path to prepared_biolip_win_p_train.csv.')
    parser.add_argument('biodl_test', help='Path to prepared_biolip_win_p_testing.csv.')
    parser.add_argument('--outdir', help='Path to output directory.', default="./ppi_fasta_files")

    return parser.parse_args()

def print_versions():
    print(f"Packages in execution of {__file__}:")
    print(f"pandas version: {pd.__version__}")
    print(f"pdbecif version: {pdbecif.__version__}")
    print(f"system information:")
    print(f"{os.name}")
    print(f"Python version: {platform.python_version()}")
    print(f"{platform.processor()}")
    print(f"{platform.platform()}")
    
def merge_datasets(df1_path, df2_path):
    # Read input data
    data1 = pd.read_csv(df1_path)
    data2 = pd.read_csv(df2_path)

    # Extract columns of interest from both dataframes
    relevant_columns = [ "domain", "sequence", "uniprot_id" ] 

    data_1_slim = data1[relevant_columns]
    data_2_slim = data2[relevant_columns]

    assert sorted(list(data_1_slim.columns)) == sorted(list(data_2_slim.columns))
    new_df = pd.concat([data_1_slim, data_2_slim], axis=0, ignore_index=True)
    
    assert len(new_df) == len(data_1_slim) + len(data_2_slim)

    new_df = new_df.drop_duplicates(subset='uniprot_id', keep='first')
    new_df = new_df.set_index(keys='uniprot_id')

    return new_df

def read_mmcif(file):
    """Returns pdb id and """
    mmcif_dict = MMCIF2Dict()
    cif_dict = mmcif_dict.parse(file)
    pdb_id = next(iter(cif_dict))
    struct = cif_dict[pdb_id] 

    chains_df = pd.DataFrame()
    chains_df['chain_id'] = struct['_struct_ref_seq']['pdbx_strand_id']
    chains_df['entity_id'] = struct['_struct_ref_seq']['ref_id']
    chains_df['pdbx_db_accession'] = struct['_struct_ref_seq']['pdbx_db_accession']

    for i in chains_df.index:
        # find the entity id
        entity_id = chains_df.loc[i, 'entity_id']
        # find the corresponding db_name
        accession_id = chains_df.loc[i, 'pdbx_db_accession']

        struct_ref = struct['_struct_ref']
        # find the corresponding index with the same accession id
        for j in range(len(struct_ref['pdbx_db_accession'])):
            if struct_ref['pdbx_db_accession'][j] == accession_id:
                chains_df.loc[i, 'db_name'] = struct_ref['db_name'][j]
                protein_seq = struct_ref['pdbx_seq_one_letter_code'][j]
                chains_df.loc[i, 'protein_sequence'] = "".join(protein_seq.split(sep='\n'))
                
                break
    chains_df_seqs = chains_df[chains_df['protein_sequence'] != '?'] if 'protein_sequence' in chains_df.columns else None
    return pdb_id, chains_df_seqs
    
def write_fasta_files(chains_df_seq, pdb_id, out_dir):
    """Loops through chains in df, makes fasta files."""
    for i in chains_df_seq.index:
        chain_id = chains_df_seq.loc[i, 'chain_id']
        uniprot_id = chains_df_seq.loc[i, 'pdbx_db_accession']
        out_path = Path(out_dir) / f"{pdb_id}_{chain_id}.fasta"
        seq = chains_df_seq.loc[i, 'biodl_seq'] # this is a hack!
        seq = chains_df_seq.loc[i, 'protein_sequence'] # check if this is better
        ppi = chains_df_seq.loc[i, 'ppi_res']

        with open(out_path, 'w') as f:
            f.write(f">{pdb_id}_{chain_id}\tUNP\t{uniprot_id}\n{seq}\n{ppi}")


def main():
    # add parse_args function
    args = parse_args()
    mmcif_dir = args.mmcif_dir   
    out_dir = args.outdir
    
    biodl_train_path = args.biodl_train
    biodl_test_path = args.biodl_test

    # print system information
    print_versions()

    files = os.listdir(mmcif_dir)

    # make output directory
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)

    # merge biodl datasets
    biodl_dataset = merge_datasets(biodl_train_path, biodl_test_path)

    # Read the mmcif file, return dataframe
    for file in files:
        print(file)
        if not file.endswith('.cif'):
            continue
        
        path = Path(mmcif_dir) / file
        pdb_id, chains_df_seqs = read_mmcif(path)

        if chains_df_seqs is None:
            continue

        for i in chains_df_seqs.index:
            if chains_df_seqs.loc[i, 'db_name'] == 'UNP':
                unp_id = chains_df_seqs.loc[i, 'pdbx_db_accession']

                slice = biodl_dataset.loc[unp_id, :] if unp_id in biodl_dataset.index else None

                if slice is not None:
                    seq = "".join(slice['sequence'].split(sep=','))
                    ppi = "".join(slice['domain'].split(sep=','))
                    chains_df_seqs.loc[i, 'biodl_seq'] = seq
                    chains_df_seqs.loc[i, 'ppi_res'] = ppi


        # Add some processing steps so only a subset of chains gets their own fasta files
        fasta_chains = chains_df_seqs.dropna(subset=['ppi_res']) if 'ppi_res' in chains_df_seqs.columns else None
        # Write the fasta files for this pdb
        if fasta_chains is not None:
            write_fasta_files(fasta_chains, pdb_id, out_dir) # check if correct sequence is written

if __name__ == '__main__':
    main()