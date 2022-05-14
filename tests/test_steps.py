"""
Test script for reference data of workflow steps.
"""
import os
import shutil
import pandas as pd
from pathlib import Path
import hashlib

def calculate_checksum(file_path):
    with open(file_path, 'rb') as file:
        bytes = file.read()
        checksum = hashlib.sha1(bytes).hexdigest()
    return checksum


def compare_contents(expected_dir, computed_dir):
    expected_files = sorted(os.listdir(expected_dir))
    computed_files = sorted(os.listdir(computed_dir))

    assert expected_files == computed_files

    for file in expected_files:
        expected_path = expected_dir / file
        computed_path = computed_dir / file

        expected_checksum = calculate_checksum(expected_path)
        computed_checksum = calculate_checksum(computed_path)

        assert computed_checksum == expected_checksum


def test_pc7(test_dir):
    expected_dir = test_dir / 'data' / 'pc7_expected'

    tool_path = test_dir.parent / 'tools' / 'pc7_inputs.cwl'
    input_fasta = test_dir / 'data' / 'test.fasta'
    output_dir = 'pc7_computed'
    computed_dir = test_dir / 'data' / output_dir

    os.chdir(test_dir / 'data')
    cmd = f"cwltool {tool_path} --fasta {input_fasta} --outdir {output_dir}"

    os.system(cmd)

    # Compare the expected and computed output
    compare_contents(expected_dir = expected_dir, computed_dir = computed_dir)

    # Remove the computed files
    shutil.rmtree(computed_dir)

    print("PC7: Computed values match expected values!")

def test_psp(test_dir):
    expected_dir = test_dir / 'data' / 'psp19_expected'

    tool_path = test_dir.parent / 'tools' / 'psp19_inputs.cwl'
    input_fasta = test_dir / 'data' / 'test.fasta'
    output_dir = 'psp19_computed'
    computed_dir = test_dir / 'data' / output_dir

    os.chdir(test_dir / 'data')
    cmd = f"cwltool {tool_path} --fasta {input_fasta} --outdir {output_dir}"

    os.system(cmd)

    # Compare the expected and computed output
    compare_contents(expected_dir = expected_dir, computed_dir = computed_dir)

    # Remove the computed files
    shutil.rmtree(computed_dir)

    print("PSP19: Computed values match expected values!")

def test_hhm(test_dir):
    """This function tests extraction from .hhm files"""

    



def main():
    test_dir = Path(__file__).absolute().parent
    #test_pc7(test_dir)
    # test_psp(test_dir)



if __name__ == "__main__":
    main()