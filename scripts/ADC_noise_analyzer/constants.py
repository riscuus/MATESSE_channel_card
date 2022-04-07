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

class Test_2_scenarios(Enum):
    NO_ALUMINUM = 1
    ALUMINUM = 2

class Test_3_scenarios(Enum):
    NO_PROBE = 1
    WITH_PROBE = 2
    WITH_CAP = 3
    NO_PROBE_2 = 4
    WITH_PROBE_2 = 5
    NO_PROBE_3 = 6
    NO_PROBE_4 = 7
    ALUMINUM = 8
    TEMP = 9

VIO_PARAMETER_TO_PROBE = {Vio_parameter.CNV_LENGTH  : "probe_out7",
                          Vio_parameter.SCK_DELAY   : "probe_out8", 
                          Vio_parameter.HALF_PERIOD : "probe_out9"}

VIO_PARAMETER_TO_MIN_VALUE = {Vio_parameter.CNV_LENGTH  : MIN_CNV_LENGTH,
                              Vio_parameter.SCK_DELAY   : MIN_SCK_DELAY, 
                              Vio_parameter.HALF_PERIOD : MIN_HALF_PERIOD}

VIO_PARAMETER_TO_MAX_VALUE = {Vio_parameter.CNV_LENGTH  : MAX_CNV_LENGTH,
                              Vio_parameter.SCK_DELAY   : MAX_SCK_DELAY, 
                              Vio_parameter.HALF_PERIOD : MAX_HALF_PERIOD}

VIO_PARAMETER_TO_DATA_DIRECTORY = {Vio_parameter.CNV_LENGTH  : "data\\test_1\\cnv_sweep",
                                            Vio_parameter.SCK_DELAY   : "data\\test_1\\sck_sweep", 
                                            Vio_parameter.HALF_PERIOD : "data\\test_1\\period_sweep"}

TEST_1_RESULTS_DIRECTORY = "results\\test_1"

TEST_2_DATA_DIRECTORIES = {Test_2_scenarios.NO_ALUMINUM : "data\\test_2\\ADC_big_sample",
                                    Test_2_scenarios.ALUMINUM    : "data\\test_2\\aluminum2"}

TEST_2_RESULTS_DIRECTORY = "results\\test_2"

TEST_3_DATA_DIRECTORIES = {Test_3_scenarios.NO_PROBE       : "data\\test_3\\no_probe",
                           Test_3_scenarios.NO_PROBE_2     : "data\\test_3\\no_probe_2",
                           Test_3_scenarios.NO_PROBE_3     : "data\\test_3\\no_probe_3",
                           Test_3_scenarios.NO_PROBE_4     : "data\\test_3\\no_probe_4",
                           Test_3_scenarios.WITH_PROBE     : "data\\test_3\\with_probe",
                           Test_3_scenarios.WITH_PROBE_2   : "data\\test_3\\with_probe_2",
                           Test_3_scenarios.WITH_CAP       : "data\\test_3\\with_cap",
                           Test_3_scenarios.TEMP           : "data\\test_3\\temp",
                           Test_3_scenarios.ALUMINUM       : "data\\test_3\\aluminum"}

TEST_3_RESULTS_DIRECTORY = "results\\test_3"

CURRENT_DIRECTORY = os.path.dirname(os.path.realpath(__file__))