"""
Script which creates a subset of biodl test dataset for script writing purposes.

"""

import pandas as pd
from pathlib import Path 

file = Path(__file__).parent.parent / 'data' / 'prepared_biolip_win_p_testing.csv'

data_all = pd.read_csv(file)

data_small_A = data_all.loc[:10, :]

data_small_B = data_all.loc[223:, :]

out_path = Path(__file__).parent.parent / 'data' 

data_small_A.to_csv(out_path / 'biodl_small_a.csv', index=False, header=True)
data_small_B.to_csv(out_path / 'biodl_small_b.csv', index=False, header=True)