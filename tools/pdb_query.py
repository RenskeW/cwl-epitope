"""
This script uses requests library to query the PDB search API to return a list of identifiers.
More information: https://search.rcsb.org/index.html
"""

__author__ = "Renske de Wit"

import argparse
import requests
import sys

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('query', help='Path to file containing query in JSON format.')

    parser.add_argument('--outpath', help='Path to output file.', default="./pbd_ids.txt")

    return parser.parse_args()

def print_resource_specs():
    print(f"RESOURCES:\n")
    print(f"Python version: {sys.version}")
    print(f"requests version: {requests.__version__}")
    print(f"\n")

def extract_identifiers(response):
    """
    Extract identifiers from raw response and return as a list.
    """
    results = response["result_set"]
    print(results)

    ids = [res["identifier"] for res in results]

    return ids

def write_to_file(ids, out_path):
    """
    Writes list of pdb ids to a comma-separated text file.
    """
    id_string = ", ".join(ids)

    with open(out_path, 'w') as f:
        f.write(id_string)


def main():
    print(f"\nStart execution of {__file__}:\n")
    print_resource_specs()
    
    args = parse_args()
    query = args.query
    out_path = args.outpath

    with open(query, 'r') as f:
        search_request = f.read()
    
    url = f"https://search.rcsb.org/rcsbsearch/v2/query?json={search_request}"

    response = requests.get(url).json()

    print(f"PDB search API response:\n{response}")

    ids = extract_identifiers(response)

    write_to_file(ids, out_path)

    print(f"\nFinished execution of {__file__}.\n")

if __name__ == "__main__":
    main()
