##############################################################################################
#
# Company: NASA Goddard Space Flight Center
# Engineer: Albert Risco
# Create Date: 07.21.2022
#
# Name: packet_fields.py
# Description: File in charge of storing the essential constants for the communication protocol
#
# Dependencies: 
#
# Revision 0.01 - File Created
#
##############################################################################################

from enum import Enum

PREAMBLE_1 = "a5a5a5a5"
PREAMBLE_2 = "5a5a5a5a"

CARD_ID = "ffff"


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

class Param_id(Enum):
    ROW_ORDER_ID        = "0001"
    ON_BIAS_ID          = "0002"
    OFF_BIAS_ID         = "0003"
    SA_BIAS_ID          = "0010"
    FLTR_RST_ID         = "0014"
    RET_DATA_ID         = "0016"
    DATA_MODE_ID        = "0017"
    FILTR_COEFF_ID      = "001A"
    SERVO_MODE_ID       = "001B"
    RAMP_DLY_ID         = "001C"
    RAMP_AMP_ID         = "001D"
    RAMP_STEP_ID        = "001E"
    BIAS_ID             = "0021"
    ROW_LEN_ID          = "0030"
    NUM_ROWS_ID         = "0031"
    SAMPLE_DLY_ID       = "0032"
    SAMPLE_NUM_ID       = "0033"
    FB_DLY_ID           = "0034"
    RET_DATA_S_ID       = "0053"
    ADC_OFFSET_0_ID     = "0068"
    ADC_OFFSET_1_ID     = "0069"
    GAIN_0_ID           = "0078"
    GAIN_1_ID           = "0079"
    DATA_RATE_ID        = "00A0"
    NUM_COLS_REP_ID     = "00AD"
    SA_FB_ID            = "00F9"
    SQ1_BIAS_ID         = "00FA"
    SQ1_FB_ID           = "00FB"
    CNV_LEN_ID          = "00FC"
    SCK_DLY_ID          = "00FD"
    SCK_HALF_PERIOD_ID  = "00FE"

PARAMS_LIST = [
    Param_id.ROW_ORDER_ID      ,
    Param_id.ON_BIAS_ID        ,
    Param_id.OFF_BIAS_ID       ,
    Param_id.SA_BIAS_ID        ,
    Param_id.FLTR_RST_ID       ,
    Param_id.RET_DATA_ID       ,
    Param_id.DATA_MODE_ID      ,
    Param_id.FILTR_COEFF_ID    ,
    Param_id.SERVO_MODE_ID     ,
    Param_id.RAMP_DLY_ID       ,
    Param_id.RAMP_AMP_ID       ,
    Param_id.RAMP_STEP_ID      ,
    Param_id.BIAS_ID           ,
    Param_id.ROW_LEN_ID        ,
    Param_id.NUM_ROWS_ID       ,
    Param_id.SAMPLE_DLY_ID     ,
    Param_id.SAMPLE_NUM_ID     ,
    Param_id.FB_DLY_ID         ,
    Param_id.RET_DATA_S_ID     ,
    Param_id.ADC_OFFSET_0_ID   ,
    Param_id.ADC_OFFSET_1_ID   ,
    Param_id.GAIN_0_ID         ,
    Param_id.GAIN_1_ID         ,
    Param_id.DATA_RATE_ID      ,
    Param_id.NUM_COLS_REP_ID   ,
    Param_id.SA_FB_ID          ,
    Param_id.SQ1_BIAS_ID       ,
    Param_id.SQ1_FB_ID         ,
    Param_id.CNV_LEN_ID        ,
    Param_id.SCK_DLY_ID        ,
    Param_id.SCK_HALF_PERIOD_ID
]

PARAM_ID_TO_SIZE = {
    Param_id.ROW_ORDER_ID       : 12,
    Param_id.ON_BIAS_ID         : 12,
    Param_id.OFF_BIAS_ID        : 12,
    Param_id.SA_BIAS_ID         : 2,
    Param_id.FLTR_RST_ID        : 1,
    Param_id.RET_DATA_ID        : 1,
    Param_id.DATA_MODE_ID       : 1,
    Param_id.FILTR_COEFF_ID     : 6,
    Param_id.SERVO_MODE_ID      : 2,
    Param_id.RAMP_DLY_ID        : 1,
    Param_id.RAMP_AMP_ID        : 1,
    Param_id.RAMP_STEP_ID       : 1,
    Param_id.BIAS_ID            : 4,
    Param_id.ROW_LEN_ID         : 1,
    Param_id.NUM_ROWS_ID        : 1,
    Param_id.SAMPLE_DLY_ID      : 1,
    Param_id.SAMPLE_NUM_ID      : 1,
    Param_id.FB_DLY_ID          : 1,
    Param_id.RET_DATA_S_ID      : 2,
    Param_id.ADC_OFFSET_0_ID    : 12,
    Param_id.ADC_OFFSET_1_ID    : 12,
    Param_id.GAIN_0_ID          : 12,
    Param_id.GAIN_1_ID          : 12,
    Param_id.DATA_RATE_ID       : 1,
    Param_id.NUM_COLS_REP_ID    : 1,
    Param_id.SA_FB_ID           : 2,
    Param_id.SQ1_BIAS_ID        : 2,
    Param_id.SQ1_FB_ID          : 2,
    Param_id.CNV_LEN_ID         : 1,
    Param_id.SCK_DLY_ID         : 1,
    Param_id.SCK_HALF_PERIOD_ID : 1
}

class Packet():
    def __init__(self, 
                    total_words : int = 0, 
                    preamble    : list = [], 
                    packet_type : Packet_type = None):

        self.total_words = total_words
        self.preamble = preamble
        self.packet_type = packet_type

class CMD_packet(Packet):
    def __init__(self, 
                    total_words     : int = 0, 
                    preamble        : list = [], 
                    packet_type     : Packet_type = None, 
                    card_id         : str = CARD_ID, 
                    param_id        : Param_id = None , 
                    payload_size    : int = 0, 
                    payload         : list = [], 
                    checksum        : str = []):

        Packet.__init__(self, total_words, preamble, packet_type)
        self.card_id = card_id
        self.param_id = param_id
        self.payload_size = payload_size
        self.payload = payload
        self.checksum = checksum

class Reply_packet(Packet):
    def __init__(self, 
                    total_words     : int = 0, 
                    preamble        : list = [], 
                    packet_type     : Packet_type = None, 
                    payload_size    : int = 0, 
                    cmd_type        : Packet_type = None, 
                    err_ok          : Ok_err = None, 
                    card_id         : str = CARD_ID, 
                    param_id        : str = '', 
                    payload         : list = [], 
                    checksum        : str = ''):

        Packet.__init__(self, total_words, preamble, packet_type)
        self.payload_size = payload_size
        self.cmd_type = cmd_type
        self.err_ok = err_ok
        self.card_id = card_id
        self.param_id = param_id
        self.payload = payload
        self.checksum = checksum

class Data_packet(Packet):
    def __init__(self, 
                    total_words     : int = 0, 
                    preamble        : list = [], 
                    packet_type     : Packet_type = None, 
                    payload_size    : int = 0, 
                    payload         : list = [], 
                    checksum        : str = ''):

        Packet.__init__(self, total_words, preamble, packet_type)
        self.payload_size = payload_size
        self.payload = payload
        self.checksum = checksum