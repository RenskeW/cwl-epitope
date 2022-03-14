# Generation of psp19 features

# This function is copied from OPUS-TASS GitHub repo: https://github.com/thuxugang/opus_tass/blob/master/inference_utils.py
def get_psp_dict():
    resname_to_psp_dict = {}
    resname_to_psp_dict['G'] = [1,4,7]
    resname_to_psp_dict['A'] = [1,3,7]
    resname_to_psp_dict['V'] = [1,7,12]
    resname_to_psp_dict['I'] = [1,3,7,12]
    resname_to_psp_dict['L'] = [1,5,7,12]
    resname_to_psp_dict['S'] = [1,2,5,7]
    resname_to_psp_dict['T'] = [1,7,15]
    resname_to_psp_dict['D'] = [1,5,7,11]
    resname_to_psp_dict['N'] = [1,5,7,14]
    resname_to_psp_dict['E'] = [1,6,7,11]
    resname_to_psp_dict['Q'] = [1,6,7,14]
    resname_to_psp_dict['K'] = [1,5,6,7,10]
    resname_to_psp_dict['R'] = [1,5,6,7,13]
    resname_to_psp_dict['C'] = [1,7,8]
    resname_to_psp_dict['M'] = [1,6,7,9]
    resname_to_psp_dict['F'] = [1,5,7,16]
    resname_to_psp_dict['Y'] = [1,2,5,7,16]
    resname_to_psp_dict['W'] = [1,5,7,18]
    resname_to_psp_dict['H'] = [1,5,7,17]
    resname_to_psp_dict['P'] = [7,19]
    return resname_to_psp_dict
    
# This function is copied from OPUS-TASS GitHub repo:
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

