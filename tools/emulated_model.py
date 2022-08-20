"""
This is a placeholder for the real model.
Inputs:
- configuration file
- directory of labels
- directory of input features

Outputs:
- text file with 'predictions'

"""
import argparse

def parse_args():
    """
    Parses arguments from the command line.
    """

    parser = argparse.ArgumentParser(description='Combines features into 1 file for every fasta sequence, stores files in 1 output directory.')
    
    # Arguments
    parser.add_argument('model_config', help='Path to model configuration file')
    parser.add_argument('input_features', help='Path to directory containing input features.')
    parser.add_argument('input_labels', help='Path to directory containing labels.')

    return parser.parse_args()

def main():
    args = parse_args()

    config = args.model_config
    input_features = args.input_features
    input_labels = args.input_labels

    print("Model training emulation step...")

    model_output = "This is the output of the model..."

    print(model_output)


    
