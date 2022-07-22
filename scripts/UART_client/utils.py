##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 07.21.2022
#
# Name: utils.py
# Description: File that includes some useful functions that can be used across all modules
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################


def calculate_checksum(content):
    current_checksum = 0
    for w in content:
        current_checksum = current_checksum ^ int(w, 16)
    return '{:08x}'.format(current_checksum)

def format_int_to_hex_str(num):
    return'{:08x}'.format(num) 