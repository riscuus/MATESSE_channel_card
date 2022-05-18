from enum import Enum
from lib2to3.pgen2.token import RBRACE

PREAMBLE_1 = "a5a5a5a5"
PREAMBLE_2 = "5a5a5a5a"


class Packet_type(Enum):
    CMD_RB = "20205242"
    CMD_WB = "20205742"
    CMD_GO = "2020474f"
    CMD_ST = "20205354"
    CMD_RS = "20205253"
    REPLY  = "20205250"
    DATA   = "20204441"

class Cmd_type(Enum):
    RB = "5242"
    WB = "5742"
    GO = "474f"
    ST = "5354"
    RS = "5253"

class Ok_err(Enum):
    OK = "4f4b"
    ER = "4552"



