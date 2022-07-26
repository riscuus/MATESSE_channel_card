##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 07.21.2022
#
# Name: receiver.py
# Description: File in charge of receiving packets from the FPGA
#
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################

import time
# Custom imports
import serial_port as sp
import packet_fields as pf
import utils as utils

def wait_data():
    time.sleep(1)
    p = sp.read_data()
    if (len(p) != 0):
        return True, p
    print("[ERROR] Wait packet timeout")
    return False, []


def parse_packet(p : list):
    packet = pf.Packet()

    if (p[0] != pf.PREAMBLE_1):
        print("Preamble_1: NOT OK: 0x" + p[0])
        return False, packet
    else:
        packet.preamble.append(p[0])
        print("\nPreamble_1: OK")

    if (p[1] != pf.PREAMBLE_2):
        print("Preamble_2: NOT OK: 0x" + p[1])
        return False, packet
    else:
        packet.preamble.append(p[1])
        print("Preamble_2: OK")

    match p[2]:
        case pf.Packet_type.CMD_RB.value:
            print("Packet Type: CMD_RB")
            packet_type = pf.Packet_type.CMD_RB
            analyse_cmd_packet(p)
        case pf.Packet_type.CMD_WB.value:
            print("Packet Type: CMD_WB")
            packet_type = pf.Packet_type.CMD_WB
            analyse_cmd_packet(p)
        case pf.Packet_type.CMD_GO.value:
            print("Packet Type: CMD_GO")
            packet_type = pf.Packet_type.CMD_GO
            analyse_cmd_packet(p)
        case pf.Packet_type.CMD_ST.value:
            print("Packet Type: CMD_ST")
            packet_type = pf.Packet_type.CMD_ST
            analyse_cmd_packet(p)
        case pf.Packet_type.CMD_RS.value:
            print("Packet Type: CMD_RS")
            packet_type = pf.Packet_type.CMD_RS
            analyse_cmd_packet(p)
        case pf.Packet_type.REPLY.value:
            packet_type = pf.Packet_type.REPLY
            print("Packet Type: Reply")
            return parse_reply_packet(p, pf.Reply_packet(packet))
        case pf.Packet_type.DATA.value:
            packet_type = pf.Packet_type.DATA
            print("Packet Type: DATA")
            return parse_data_packet(p, pf.Data_packet(packet))
        case _:
            print("Packet Type: NOT OK" + p[2])
            return False, packet
    return False, packet

def analyse_cmd_packet(p):
    get_id(p[3])
    n = get_payload_size(p[4], pf.Packet_type.CMD_GO)
    payload = p[5:62] # Cmd has a fixed size of 58 words of the payload
    print_payload(payload)
    check_checksum(p[63], payload)

def parse_reply_packet(p : list, packet : pf.Reply_packet):
    n = get_payload_size(p[3], pf.Packet_type.REPLY)
    packet.payload_size = n
    packet.cmd_type, packet.err_ok = get_type_and_error(p[4])
    packet.card_id, packet.param_id = get_id(p[5])
    packet.payload = p[6:6+n]
    print_payload(packet.payload)
    checksum = p[6+n]
    if(check_checksum(checksum, p[4:6+n]) == False):
        return False, packet
    packet.total_words = 6 + n + 1
    return True, packet

def parse_data_packet(p : list, packet : pf.Data_packet):
    n = get_payload_size(p[3], pf.Packet_type.DATA)
    packet.payload_size = n
    packet.payload = p[4:4+n] 
    print_payload(packet.payload)
    packet.checksum = p[4+n]
    if (check_checksum(packet.checksum, packet.payload) == False):
        return False, packet
    packet.total_words = 4 + n + 1
    return True, packet

def get_id(word):
    card_id = word[0:4]
    param_id = word[4:8]
    print("Card ID: " + card_id)
    print("Param ID: " + param_id)
    return card_id, param_id

def get_type_and_error(word):
    cmd_type_rx = word[0:4]
    err_rx = word[4:8]
    cmd_type = None
    err = None
    match cmd_type_rx:
        case pf.Cmd_type.RB.value:
            print("Cmd Type: CMD_RB")
            cmd_type = pf.Cmd_type.RB
        case pf.Cmd_type.WB.value:
            print("Cmd Type: CMD_WB")
            cmd_type = pf.Cmd_type.WB
        case pf.Cmd_type.GO.value:
            print("Cmd Type: CMD_GO")
            cmd_type = pf.Cmd_type.GO
        case pf.Cmd_type.ST.value:
            print("Cmd Type: CMD_ST")
            cmd_type = pf.Cmd_type.ST
        case pf.Cmd_type.RS.value:
            print("Cmd Type: CMD_RS")
            cmd_type = pf.Cmd_type.RS
        case _:
            print("Cmd Type: NOT OK")
            print(cmd_type_rx)
            return False

    match err_rx:
        case pf.Ok_err.OK.value:
            err = pf.Ok_err.OK
            print("Error/OK: OK")
        case pf.Ok_err.ER.value:
            err = pf.Ok_err.ER
            print("Error/OK: ER")
        case _:
            print("Error/OK: NOT OK")
            print(err_rx)

    return cmd_type, err

def get_payload_size(word, p_type):
    if (p_type == pf.Packet_type.CMD_RB or p_type == pf.Packet_type.CMD_WB or p_type == pf.Packet_type.CMD_GO or 
        p_type == pf.Packet_type.CMD_ST or p_type == pf.Packet_type.CMD_RS):
        s = int(word, 16)
        print("Payload size: ", s)
        return s
    elif (p_type == pf.Packet_type.REPLY):
        s = int(word, 16) - 3 
        print("Payload size: ", s)
        return s
    elif (p_type == pf.Packet_type.DATA):
        s = int(word, 16) - 1
        print("Payload size: ", s)
        return s
    else:
        print("Error wrong type when getting payload")
        return -1

def print_payload(words):
    print("Payload : 0x" + ", 0x".join(words))

def check_checksum(checksum, content):
    calculated_checksum = utils.calculate_checksum(content)
    print("Calculated checksum: ", calculated_checksum)
    if (int(calculated_checksum, 16) != int(checksum, 16)):
        print("Checksum doesn't match, calculated: ", calculated_checksum, " Received: ", checksum)
        return False
    else:
        print("Checksum OK")
        return True