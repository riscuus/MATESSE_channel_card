from tabnanny import check
import serial
import struct
import constants as cts
import time

def main():
    ser = init_serial_port()
    #cmd = get_user_command()
    #print("Sending packet to FPGA...")
    #send_command(ser, cmd)

    print("Waiting FPGA packet...\n")
    while True:
        p = read_packet(ser)
        if (len(p) != 0):
            analyse_packet(p)

def init_serial_port():
    print("Initializing \"COM4\" serial port")
    print("baudrate = 19200")
    print("parity = even")
    ser = serial.Serial()
    ser.baudrate = 19200
    ser.port = "COM4"
    ser.parity = serial.PARITY_EVEN
    ser.open()
    open_serial_port(ser)
    return ser

def open_serial_port(ser):
    try:
        ser.open()
    except:
        print("Port open")

def get_user_command():
    print("Please enter your command:")
    return input()

def send_command(ser, cmd):
    params = cmd.split()
    card_id = params[1] 
    param_id = params[2]
    payload = ["00000000"] * 58

    if (params[0] == "wb"):
        params[3:] = map(lambda x : '{:08x}'.format(int(x)), params[3:])
        payload[0:len(params)-3] = params[3:]
        send_packet(ser, cts.Packet_type.CMD_WB, payload, card_id, param_id)
        return
    elif (params[0] == "rb"):
        send_packet(ser, cts.Packet_type.CMD_RB, payload, card_id, param_id)
        return
    elif (params[0] == "go"):
        send_packet(ser, cts.Packet_type.CMD_GO, payload, card_id, param_id)
        return
    elif (params[0] == "st"):
        send_packet(ser, cts.Packet_type.CMD_ST, payload, card_id, param_id)
        return
    elif (params[0] == "rs"):
        send_packet(ser, cts.Packet_type.CMD_RS, payload, card_id, param_id)
        return
    
    print("Incorrect params")
def send_packet(ser, packet_type, payload, card_id = "ff00", param_id = "00ff"):
    checksum = calculate_checksum(payload)
    send_preamble(ser)
    send_packet_type(ser, packet_type)
    send_id(ser, card_id, param_id)
    send_payload_size(ser, len(payload))
    send_payload(ser, payload)
    send_checksum(ser, checksum)

def calculate_checksum(content):
    current_checksum = 0
    for w in content:
        current_checksum = current_checksum ^ int(w, 16)
    return '{:08x}'.format(current_checksum)

def send_preamble(ser):
    write_word(ser, cts.PREAMBLE_1)
    write_word(ser, cts.PREAMBLE_2)

def send_packet_type(ser, packet_type):
    write_word(ser, packet_type.value)

def send_id(ser, card_id, param_id):
    write_word(ser, card_id+param_id)

def send_payload_size(ser, size):
    s = '{:08x}'.format(size)
    write_word(ser, s)

def send_payload(ser, payload):
    for w in payload:
        write_word(ser, w)

def send_checksum(ser, checksum):
    write_word(ser, checksum)

def write_word(ser, word):
    print(word, end = " ")
    word = '{:08x}'.format(struct.unpack("<I", struct.pack(">I", int(word, 16)))[0])
    #print("Mod: ", word)
    data = bytes.fromhex(word)
    ser.write(data)

def read_packet(ser):
    p = []
    while ser.in_waiting > 0:
        p.append(read_word(ser))
        time.sleep(0.001)
    return p

def read_word(ser):
    bytes_read = ser.read(4)
    print("Word read:")
    w = bytes_read.hex()
    w = hex(struct.unpack("<I", struct.pack(">I", int(w, 16)))[0]) 
    w = w[2:len(w)]
    print(w)
    return w

def analyse_packet(p):
    if (p[0] != cts.PREAMBLE_1):
        print("Preamble_1: NOT OK")
        return False
    else:
        print("\nPreamble_1: OK")

    if (p[1] != cts.PREAMBLE_2):
        print("Preamble_2: NOT OK")
        return False
    else:
        print("Preamble_2: OK")

    match p[2]:
        case cts.Packet_type.CMD_RB.value:
            print("Packet Type: CMD_RB")
            analyse_cmd_packet(p)
        case cts.Packet_type.CMD_WB.value:
            print("Packet Type: CMD_WB")
            analyse_cmd_packet(p)
        case cts.Packet_type.CMD_GO.value:
            print("Packet Type: CMD_GO")
            analyse_cmd_packet(p)
        case cts.Packet_type.CMD_ST.value:
            print("Packet Type: CMD_ST")
            analyse_cmd_packet(p)
        case cts.Packet_type.CMD_RS.value:
            print("Packet Type: CMD_RS")
            analyse_cmd_packet(p)
        case cts.Packet_type.REPLY.value:
            print("Packet Type: Reply")
            analyse_reply_packet(p)
        case cts.Packet_type.DATA.value:
            print("Packet Type: DATA")
            analyse_data_packet(p)
        case _:
            print(p[2])
            print(cts.Packet_type.cmd)
            print("Packet Type: NOT OK")
            return False
    return True

def analyse_cmd_packet(p):
    get_id(p[3])
    n = get_payload_size(p[4], cts.Packet_type.CMD_GO)
    payload = p[5:62] # Cmd has a fixed size of 58 words of the payload
    print_payload(payload)
    check_checksum(p[63], payload)

def analyse_reply_packet(p):
    n = get_payload_size(p[3], cts.Packet_type.REPLY)
    cmd_type, err = get_type_and_error(p[4])
    get_id(p[5])
    print_payload(p[6:6+n])
    check_checksum(p[6+n], p[4:6+n])

def analyse_data_packet(p):
    n = get_payload_size(p[3], cts.Packet_type.DATA)
    payload = p[4:4+n] 
    print_payload(payload)
    check_checksum(p[4+n], payload)

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
        case cts.Cmd_type.RB.value:
            print("Cmd Type: CMD_RB")
            cmd_type = cts.Cmd_type.RB
        case cts.Cmd_type.WB.value:
            print("Cmd Type: CMD_WB")
            cmd_type = cts.Cmd_type.WB
        case cts.Cmd_type.GO.value:
            print("Cmd Type: CMD_GO")
            cmd_type = cts.Cmd_type.GO
        case cts.Cmd_type.ST.value:
            print("Cmd Type: CMD_ST")
            cmd_type = cts.Cmd_type.ST
        case cts.Cmd_type.RS.value:
            print("Cmd Type: CMD_RS")
            cmd_type = cts.Cmd_type.RS
        case _:
            print("Cmd Type: NOT OK")
            print(cmd_type_rx)
            return False

    match err_rx:
        case cts.Ok_err.OK.value:
            err = cts.Ok_err.OK
            print("Error/OK: OK")
        case cts.Ok_err.ER.value:
            err = cts.Ok_err.ER
            print("Error/OK: ER")
        case _:
            print("Error/OK: NOT OK")
            print(err_rx)

    return cmd_type, err

def get_payload_size(word, p_type):
    if (p_type == cts.Packet_type.CMD_RB or p_type == cts.Packet_type.CMD_WB or p_type == cts.Packet_type.CMD_GO or 
        p_type == cts.Packet_type.CMD_ST or p_type == cts.Packet_type.CMD_RS):
        s = int(word, 16)
        print("Payload size: ", s)
        return s
    elif (p_type == cts.Packet_type.REPLY):
        s = int(word, 16) - 3 
        print("Payload size: ", s)
        return s
    elif (p_type == cts.Packet_type.DATA):
        s = int(word, 16) - 1
        print("Payload size: ", s)
        return s
    else:
        print("Error wrong type when getting payload")
        return -1

def print_payload(words):
    print("Payload :", ", ".join(words))

def check_checksum(checksum, content):
    calculated_checksum = calculate_checksum(content)
    print("Calculated checksum: ", calculated_checksum)
    if (calculated_checksum != checksum):
        print("Checksum doesn't match, calculated: ", hex(calculated_checksum), " Received: ", checksum)
    else:
        print("Checksum OK")


if __name__ == "__main__" :
    main()