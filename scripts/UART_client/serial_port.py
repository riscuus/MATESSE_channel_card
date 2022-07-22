##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 05.21.2022
#
# Name: serial_port.py
# Description: File in charge of the serial port configuration
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################

import serial
import time
import struct

PORT_NAME = "COM4"
BAUDRATE = 19200
PARITY = "even"
TIMEOUT = 10 # Seconds

ser = serial.Serial()

def init_serial_port(port_name = PORT_NAME, baudrate = BAUDRATE, parity = PARITY):
    ser.close()
    print("Initializing \"" + port_name + "\" serial port")
    print("baudrate = " + str(baudrate))
    print("parity = " + parity)
    ser.baudrate = baudrate
    ser.port = port_name
    ser.parity = get_parity(parity)
    #ser.timeout = TIMEOUT
    ser.open()


def get_parity(parity):
    if (parity == "even"):
        return serial.PARITY_EVEN
    else:
        return serial.PARITY_NONE

def write_word(word):
    #if (ser == None):
    #    print("[ERROR] Serial Port not initialized")
    #    return
    #print(word, end = " ")
    word = '{:08x}'.format(struct.unpack("<I", struct.pack(">I", int(word, 16)))[0])
    #print("Mod: ", word)
    data = bytes.fromhex(word)
    ser.write(data)

def read_data():
    p = []
    while ser.in_waiting > 0:
        p.append(read_word())
        time.sleep(0.001)
    return p

def read_word():
    bytes_read = ser.read(4)
    w = bytes_read.hex()
    w = hex(struct.unpack("<I", struct.pack(">I", int(w, 16)))[0]) 
    w = w[2:len(w)]
    print("Word read: " + w)
    return w

