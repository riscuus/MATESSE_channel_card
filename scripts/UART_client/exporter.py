##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 07.28.2022
#
# Name: exporter.py
# Description: File in charge of exporting the data to a file
#
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################

import csv as csv


def export_data_payloads_to_csv(data_packets : list):
    # Writes a matrix to csv, each line is a frame
    f = open("data/raw_data_1.csv", "w")
    writer = csv.writer(f)
    for p in data_packets:
        writer.writerow(p.payload[43:])
    f.close()

