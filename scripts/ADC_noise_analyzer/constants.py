from enum import Enum
import os


DEFAULT_CNV_LENGTH = 3
MIN_CNV_LENGTH = 3
MAX_CNV_LENGTH = 7
DEFAULT_SCK_DELAY = 1
MIN_SCK_DELAY = 1 
MAX_SCK_DELAY = 7
DEFAULT_HALF_PERIOD = 2
MIN_HALF_PERIOD = 2
MAX_HALF_PERIOD = 7

class Vio_parameter(Enum):
    CNV_LENGTH = 1
    SCK_DELAY = 2
    HALF_PERIOD = 3

VIO_PARAMETER_TO_PROBE = {Vio_parameter.CNV_LENGTH  : "probe_out7",
                          Vio_parameter.SCK_DELAY   : "probe_out8", 
                          Vio_parameter.HALF_PERIOD : "probe_out9"}

VIO_PARAMETER_TO_MIN_VALUE = {Vio_parameter.CNV_LENGTH  : MIN_CNV_LENGTH,
                              Vio_parameter.SCK_DELAY   : MIN_SCK_DELAY, 
                              Vio_parameter.HALF_PERIOD : MIN_HALF_PERIOD}

VIO_PARAMETER_TO_MAX_VALUE = {Vio_parameter.CNV_LENGTH  : MAX_CNV_LENGTH,
                              Vio_parameter.SCK_DELAY   : MAX_SCK_DELAY, 
                              Vio_parameter.HALF_PERIOD : MAX_HALF_PERIOD}

VIO_PARAMETER_TO_RELATIVE_DIRECTORY = {Vio_parameter.CNV_LENGTH  : "data\cnv_sweep",
                                       Vio_parameter.SCK_DELAY   : "data\sck_sweep", 
                                       Vio_parameter.HALF_PERIOD : "data\period_sweep"}

CURRENT_DIRECTORY = os.path.dirname(os.path.realpath(__file__))