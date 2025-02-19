##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 07.27.2022
#
# Name: params_quantizer.py
# Description: Small script to convert the filter coefficients exported by matlab to the uart params format
#
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################

from math import log2


B1_LINE = 9
B2_LINE = 10
K1_LINE = 12
B3_LINE = 22
B4_LINE = 23
K2_LINE = 25

B_PARAMS = [B1_LINE, B2_LINE, B3_LINE, B4_LINE]
K_PARAMS = [K1_LINE, K2_LINE]

TXT_LINES = 29

def get_raw_coeff():
    print("Please copy-paste the coefficients text file generated by matlab:")
    s = ""
    for i in range(TXT_LINES):
        s = s + input() + "\n"
    return s

def quantize_params(coeff_txt):
    result = []
    txt_array = coeff_txt.split("\n")
    for line_num in B_PARAMS:
        coeff = float(txt_array[line_num])
        result.append(quantize_coeff(coeff))
    for line_num in K_PARAMS:
        gain = float(txt_array[line_num])
        result.append(quantize_gains(gain))
    
    return result

def quantize_coeff(num : float):
    return int(num * 2**14)

def quantize_gains(gain : float):
    return int(log2(1 / gain))


if __name__ == "__main__" :
    coeff_txt = get_raw_coeff()
    print()
    print("Copy-paste the following in the UART client:\n")
    print("\n".join([str(x) for x in quantize_params(coeff_txt)]))
