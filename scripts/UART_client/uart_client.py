##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 05.21.2022
#
# Name: uart_client.py
# Description: Main entry point for the uart client that communicates with the FPGA Spartan 7 xc7s25csga324-1. Running
#              MATESSE
#
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################

import ui as ui
import serial_port as sp
import sender as sender


def main():

    ui.print_welcome_message()

    sp.init_serial_port()

    while True:
        action = ui.get_user_action()
        run_action(action)


def run_action(action):
    if (action == ui.User_action.read):
        sender.start_read_param()
    elif (action == ui.User_action.write):
        sender.start_write_param()
    elif (action == ui.User_action.start):
        sender.start_acquisition()
    elif (action == ui.User_action.stop):
        sender.stop_acquisition()
    else:
        print("Invalid action")
        return

        
if __name__ == "__main__" :
    main()