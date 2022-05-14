"""
Script which transforms reference data retrieved from OPUS-TASS/Henriettes model

Inputs:
- reference data from Henriette's model

Outputs:
- reference pc7 features
- reference psp19 features
- reference hhm, pc7 and psp19 features
"""

import os
from pathlib import Path
import numpy as np

def main():
    all_features_path = Path(r'/Users/renskedewit/Documents/GitHub/cwl-epitope/tests/data/delete') # directory with reference data with all input features
    files = os.listdir(all_features_path)

    test_data_path = Path(r'/Users/renskedewit/Documents/GitHub/cwl-epitope/tests/data')

    # Create path where reference data is stored
    pc7_path = test_data_path / 'pc7_expected'
    psp19_path = test_data_path / 'psp19_expected'
    all_inputs_path = test_data_path / 'input_features_expected'

    if not os.path.exists(pc7_path):
        os.mkdir(pc7_path)
    if not os.path.exists(psp19_path):
        os.mkdir(psp19_path)
    if not os.path.exists(all_inputs_path):
        os.mkdir(all_inputs_path)

    for file in files:
        # extract the filename
        path = all_features_path / file
        pdb_id = path.stem

        data = np.loadtxt(path, dtype=float)

        # Extract the features of interest from the reference data
        pc7_data = data[:, 50:57] # 7 pc7 features
        psp19_data = data[:, 57:] # 19 psp19 features
        all_inputs_data = data[:, 20:] # 30 hmm + 7 pc7 + 19 psp19 features

        pc7_name = f"pc7_{pdb_id}.input"
        psp19_name = f"psp19_{pdb_id}.input"
        all_inputs_name = f"{pdb_id}.inputs"
        
        # Save data
        np.savetxt(pc7_path / pc7_name, pc7_data, fmt="%.4f")
        np.savetxt(psp19_path / psp19_name, psp19_data, fmt="%.4f")
        np.savetxt(all_inputs_path / all_inputs_name, all_inputs_data, fmt="%.4f")

if __name__=="__main__":
    main()