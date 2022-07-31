##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 05.21.2022
#
# Name: ui.py
# Description: Module in charge of the user interface of the uart client: printing text to console and getting user input
#
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################
from enum import Enum
# Custom Imports
import packet_fields as pf

class User_action(Enum):
    read    = 1
    write   = 2
    start   = 3
    stop    = 4

def print_welcome_message():
    print("")
    print("----------------------------")
    print("Welcome to UART client v0.01")
    print("----------------------------")

def get_user_action():
    while True:
        print("")
        print("[0] Read parameter")
        print("[1] Write parameter")
        print("[2] Start Acquisition")
        print("[3] Stop Acquisition")

        print("Please choose an action:", end = ' ')
        usr_input = input()

        if (usr_input == str(0)):
            return User_action.read
        elif (usr_input == str(1)):
            return User_action.write
        elif (usr_input == str(2)):
            return User_action.start
        elif (usr_input == str(3)):
            return User_action.stop
        else:
            print ("Invalid Input")

def get_param(param_list):
    while True:
        i = 0
        print("")
        for param in param_list:
            print("[" + str(i) + "] " + param.name + " (0x" + param.value + ")")
            i = i + 1
        
        print("Please choose parameter:", end = ' ')
        usr_input = input()

        try:
            val = int(usr_input)
            if (val >= 0 and val < len(param_list)):
                return val
            else:
                print("\n[ERROR] Please insert a number between 0 and " + str(len(param_list) - 1))

        except ValueError:
            print("\n[ERROR] Please insert a number")

def get_param_data_to_write(param, num_words):
    data = []
    print("")
    print("Please insert the data to write to the parameter " + param.name + " (" + str(num_words) + " words)")
    for i in range(num_words):
        while True:
            print("Word " + str(i) + ": ", end = ' ')
            usr_input = input()
            try:
                val = int(usr_input)
                if (val >= -2**31 - 1 and val <= 2**31 - 1):
                    data.append(val)
                    break
                else:
                    print("\n[ERROR] Please insert a number between 0 and " + str(2**32 - 1))
            except ValueError:
                print("\n[ERROR] Please insert a number")
    return data

def print_about_to_send_packet(packet : pf.CMD_packet):
    print("\nAbout to send packet with: ")
    print("Preamble: " + str(["0x" + p for p in packet.preamble]))
    print("Command type: " + packet.packet_type.name + " (0x" + packet.packet_type.value + ")")
    print("Card id: (0x" + packet.card_id + ")")
    print("Param id: "+ packet.param_id.name + " (0x" + packet.param_id.value + ")") 
    print("Payload size: " + str(packet.payload_size))
    print("Payload: " + str(["0x" + p for p in packet.payload]))
    print("Checksum: (0x" + packet.checksum + ")\n")






