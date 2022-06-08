"""
This script combines multiple BioDL datasets and extracts the relevant information. 
In addition, it uses the UniProt mapping_dict tool to find pdb identifiers for each UniProt identifier in the dataset.

@author: Renske de Wit
@dateCreated: 2022-05-27

Inputs:
- biodl_training_....csv
- biodl_test_....csv

Outputs:
- directory with fasta files for each protein in the combined bioDL dataset (and which maps to a UniProt identifier)

"""

import argparse
import pandas as pd
import urllib.parse
import urllib.request
from pathlib import Path
import os

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('train_biodl_path', help='Path to biodl training dataset.')
    parser.add_argument('test_biodl_path', help='Path to biodl testing dataset.')
    parser.add_argument('--outdir', help='Path to output directory.', default="./fasta_files")

    return parser.parse_args()

def merge_datasets(df1, df2):
    """
    Merge testing and training set into one dataframe.
    """
    assert sorted(list(df1.columns)) == sorted(list(df2.columns))
    new_df = pd.concat([df1, df2], axis=0, ignore_index=True)

    assert len(new_df) == len(df1) + len(df2)

    return new_df

def use_uniprot_mapping_tool(uniprot_ids):
    """
    Queries UniProt API to return PDB ids associated with query UniProt IDs. 
    Code adapted from the example at https://www.uniprot.org/help/api_idmapping.
    """
    url = 'https://www.uniprot.org/uploadlists/'

    query = " ".join(uniprot_ids)
    params = {
        'from': 'ACC+ID',
        'to': 'PDB_ID',
        'format': 'tab',
        'query': query
    }
    data = urllib.parse.urlencode(params)
    data = data.encode('utf-8')
    req = urllib.request.Request(url, data)
    with urllib.request.urlopen(req) as f:
        response = f.read()
    return response

def response_to_dictionary(response):
    """
    Converts the response obtained from UniProt mapping tool to a dictionary.
    Output: Dictionary with Uniprot IDs as keys and a lists of PDB ids as values (single UniProt IDs may map to different PDB ids).
    """
    list = response.decode('utf-8').split(sep="\n") # output: ['From\tTo', uniprot1\tpdb1, uniprot2\tpdb2, ... ]
    split = [a.split('\t') for a in list[1:]] # output: [ [uniprot1, pdb1], [uniprot2, pdb2], ... ]
   
    mapping_dict = {}
    for id in split: 
        if len(id) == 2:
            if id[0] not in mapping_dict.keys():
                mapping_dict[id[0]] = [id[1]]
            else:
                mapping_dict[id[0]].append(id[1])

    return mapping_dict

def map_identifiers(dataset):
    """
    Uses the UniProt mapping_dict tool to map pdb identifiers to every UniProt ID in the dataset.
    """
    uniprot_ids = [i for i in dataset["uniprot_id"]]

    response = use_uniprot_mapping_tool(uniprot_ids)

    # Convert response to dictionary
    mapping = response_to_dictionary(response)

    # Arbitrary & not necessarily correct choice: map the first pdb id to the uniprot id.

    dataset.insert(len(dataset.columns), "pdb_id", "")
    for i in dataset.index:
        uniprot_id = dataset.loc[i, "uniprot_id"]
        try:
            pdb_id = mapping[uniprot_id][0]
            dataset.loc[i, "pdb_id"] = pdb_id
        except KeyError:
            dataset = dataset.drop(index = i) # drop rows which do not map to any pdb id

    return dataset, response.decode('utf-8')

def write_fasta_files(dataset, out_dir):
    """
    Writes a fasta file for every pdb id in the dataset, which includes which residues are PPI residues.
    """

    for i in dataset.index:
        pdb_id = dataset.loc[i, "pdb_id"]
        sequence = dataset.loc[i, "sequence"]
        domain = dataset.loc[i, "domain"]

        # Remove commas from domain and sequence
        sequence = "".join(sequence.split(sep=","))
        domain = "".join(domain.split(sep=","))

        assert len(sequence) == len(domain)

        # Write fasta file
        filename = f"{pdb_id}.fasta"
        out_path = Path(out_dir) / filename

        with open(out_path, 'w') as f:
            f.writelines(f">{pdb_id}\n{sequence}\n{domain}")


def main():
    args = parse_args()
    train_biodl_path = args.train_biodl_path
    test_biodl_path = args.test_biodl_path
    out_dir = args.outdir

    # Create output directory
    if not os.path.exists(out_dir): # maybe introduce some safeguards here to avoid overwriting existing files
        os.mkdir(out_dir)

    # Read input data
    data_train = pd.read_csv(train_biodl_path)
    data_test = pd.read_csv(test_biodl_path)
    
    # Extract columns of interest from both dataframes
    relevant_columns = [ "domain", "sequence", "uniprot_id" ] 

    data_train_slim = data_train[relevant_columns]
    data_test_slim = data_test[relevant_columns]

    # Merge the two datasets
    combined_data = merge_datasets(data_train_slim, data_test_slim)

    # Map the UniProt identifiers in the dataset to their associated pdb ids (obtained from UniProt mapping tool)
    mapped_dataset, uniprot_response = map_identifiers(combined_data)

    # Write each protein sequence together with its interface residues to a separate .fasta file.
    write_fasta_files(mapped_dataset, out_dir)

    # Write UniProt response to a file as well
    with open(Path(out_dir).parent / 'uniprot_mapping.tsv', 'w') as f:
        f.write(uniprot_response)

    

if __name__ == "__main__":
    main()