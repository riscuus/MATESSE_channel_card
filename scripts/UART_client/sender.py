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
    packet = pf.CMD_packet(preamble = preamble, packet_type = pf.Packet_type.CMD_RB, card_id = pf.CARD_ID, param_id = pf.PARAMS_LIST[param_index], payload_size = len(payload), payload = payload, checksum = utils.calculate_checksum(payload))
    ui.print_about_to_send_packet(packet)
    send_packet(packet)

    result, packet_words = receiver.wait_data()
    if (result == True):
        received_packet = receiver.parse_packet(packet_words)

def start_write_param():
    packet = pf.CMD_packet()
    packet.preamble = [pf.PREAMBLE_1, pf.PREAMBLE_2]
    packet.packet_type = pf.Packet_type.CMD_WB
    packet.payload = ["00000000"] * 58
    
    # Get the param id to write
    packet.param_id = pf.PARAMS_LIST[ui.get_param(pf.PARAMS_LIST)]
    packet.payload_size = pf.PARAM_ID_TO_SIZE[packet.param_id]

    # Get the data to write
    packet.payload[0:packet.payload_size] = [utils.format_int_to_hex_str(p) for p in ui.get_param_data_to_write(packet.param_id, packet.payload_size)]

    packet.checksum = utils.calculate_checksum(packet.payload)

    ui.print_about_to_send_packet(packet)
    send_packet(packet)

    result, packet_words = receiver.wait_data()
    if (result == True):
        received_packet = receiver.parse_packet(packet_words)


def start_acquisition():
    packet = pf.CMD_packet()
    packet.preamble = [pf.PREAMBLE_1, pf.PREAMBLE_2]
    packet.packet_type = pf.Packet_type.CMD_GO
    packet.param_id = pf.Param_id.RET_DATA_ID
    packet.payload_size = 1
    packet.payload = ["00000000"] * 58
    packet.payload[0] = utils.format_int_to_hex_str(1)
    packet.checksum = utils.calculate_checksum(packet.payload)

    ui.print_about_to_send_packet(packet)
    send_packet(packet)

    # If the acq has been successful we will receive more than one packet (at least 2 [reply + data])
    result, words = receiver.wait_data()
    if (result == False):
        return

    result, received_packet = receiver.parse_packet(words)
    if (result == False):
        return
    words = words[received_packet.total_words:]
    while len(words) > 0:
        result, received_packet = receiver.parse_packet(words)
        if (result == False):
            return
        words = words[received_packet.total_words:]



def stop_acquisition():
    print("Stop acquisition")

def build_cmd_packet(cmd_type, card_id, param_id, payload_size, payload, checksum):
    return 


def send_packet(packet : pf.CMD_packet):
    send_preamble(packet.preamble)
    send_packet_type(packet.packet_type)
    send_id(packet.card_id, packet.param_id)
    send_payload_size(packet.payload_size)
    send_payload(packet.payload)
    send_checksum(packet.checksum)

def send_preamble(preamble : list):
    for p in preamble:
        sp.write_word(p)

def send_packet_type(packet_type : pf.Packet_type):
    sp.write_word(packet_type.value)

def send_id(card_id : str, param_id : pf.Param_id):
    sp.write_word(card_id + param_id.value)

def send_payload_size(size : int):
    s = '{:08x}'.format(size)
    sp.write_word(s)

def send_payload(payload : list):
    for w in payload:
        sp.write_word(w)

def send_checksum(checksum : str):
    sp.write_word(checksum)
