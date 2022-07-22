##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 07.21.2022
#
# Name: sender.py
# Description: File in charge of sending commands to the FPGA
#
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################

from tabnanny import check
import struct
import time

# Custom imports
import ui as ui
import packet_fields as pf
import serial_port as sp
import utils as utils
import receiver as receiver

def start_read_param():
    preamble = [pf.PREAMBLE_1, pf.PREAMBLE_2]
    payload = ["00000000"] * 58

    param_index = ui.get_param(pf.PARAMS_LIST)
    packet = pf.CMD_packet(preamble, pf.Packet_type.CMD_RB, pf.CARD_ID, pf.PARAMS_LIST[param_index], len(payload), payload, utils.calculate_checksum(payload))
    ui.print_about_to_send_packet(packet)
    send_packet(packet)

    packet_words = receiver.wait_data()
    received_packet = receiver.parse_packet(packet_words)

def start_write_param():
    preamble = [pf.PREAMBLE_1, pf.PREAMBLE_2]
    payload = ["00000000"] * 58
    
    # Get the param id to write
    param_id = pf.PARAMS_LIST[ui.get_param(pf.PARAMS_LIST)]
    num_words = pf.PARAM_ID_TO_SIZE[param_id]

    # Get the data to write
    payload[0:num_words] = [utils.format_int_to_hex_str(p) for p in ui.get_param_data_to_write(param_id, num_words)]

    packet = pf.CMD_packet(preamble, pf.Packet_type.CMD_WB, pf.CARD_ID, param_id, num_words, payload, utils.calculate_checksum(payload))

    ui.print_about_to_send_packet(packet)
    send_packet(packet)

    packet_words = receiver.wait_data()
    received_packet = receiver.parse_packet(packet_words)


def start_acquisition():
    preamble = [pf.PREAMBLE_1, pf.PREAMBLE_2]
    payload = ["00000000"] * 58
    param_id = pf.Param_id.RET_DATA_ID
    num_words = 1
    payload[0] = utils.format_int_to_hex_str(1)

    packet = pf.CMD_packet(preamble, pf.Packet_type.CMD_GO, pf.CARD_ID, param_id, num_words, payload, utils.calculate_checksum(payload))

    ui.print_about_to_send_packet(packet)
    send_packet(packet)

    # If the acq has been successful we will receive more than one packet (at least 2 [reply + data])
    words = receiver.wait_data()
    received_packet, packet_length = receiver.parse_packet(words)
    words = words[packet_length:]
    while len(words) > 0:
        received_packet, packet_length = receiver.parse_packet(words)
        words = words[packet_length:]



def stop_acquisition():
    print("Stop acquisition")

def build_cmd_packet(cmd_type, card_id, param_id, payload_size, payload, checksum):
    return 


def send_packet(packet):
    send_preamble(packet.preamble)
    send_cmd_type(packet.cmd_type)
    send_id(packet.card_id, packet.param_id)
    send_payload_size(packet.payload_size)
    send_payload(packet.payload)
    send_checksum(packet.checksum)

def send_preamble(preamble):
    for p in preamble:
        sp.write_word(p)

def send_cmd_type(cmd_type):
    sp.write_word(cmd_type.value)

def send_id(card_id, param_id):
    sp.write_word(card_id + param_id.value)

def send_payload_size(size):
    s = '{:08x}'.format(size)
    sp.write_word(s)

def send_payload(payload):
    for w in payload:
        sp.write_word(w)

def send_checksum(checksum):
    sp.write_word(checksum)




if __name__ == "__main__" :
    main()