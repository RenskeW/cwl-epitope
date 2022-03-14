# Combine input features into 1 file per fasta sequence.

# Function copied from OPUS-TASS GitHub repository
def make_input(file, preparation_config):
    """
    20pssm + 30hhm + 7pc + 19psp
    """    
    filename = file[0].split('.')[0]
    fasta = file[1]   
    
    seq_len = len(fasta)

    pssm_path = os.path.join(preparation_config["tmp_files_path"], filename+'.pssm')
    hhm_path = os.path.join(preparation_config["tmp_files_path"], filename+'.hhm')
    input_path = os.path.join(preparation_config["tmp_files_path"], filename+'.inputs')
    
    pssm = read_pssm(pssm_path, fasta)
    hhm = read_hhm(hhm_path, fasta)
    
    pc7 = np.zeros((seq_len, 7))
    for i in range(seq_len):
        pc7[i] = resname_to_pc7_dict[fasta[i]]
    
    psp = np.zeros((seq_len, 19))
    for i in range(seq_len):
        psp19 = resname_to_psp_dict[fasta[i]]
        for j in psp19:
            psp[i][j-1] = 1
    
    input_data = np.concatenate((pssm, hhm, pc7, psp),axis=1)
    assert input_data.shape == (seq_len,76)
    np.savetxt(input_path, input_data, fmt="%.4f")
