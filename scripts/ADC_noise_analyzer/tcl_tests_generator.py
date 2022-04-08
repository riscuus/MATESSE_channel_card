from enum import Enum
import constants as cts
import utils

def generate_test_1():
    s = ""
    s = s + set_ADC_vio_parameters_to_default()
    # Sweep CNV length
    s = s + sweep_ADC_vio_parameter(cts.Vio_parameter.CNV_LENGTH)
    s = s + set_ADC_vio_parameters_to_default()
    # Sweep SCK delay
    s = s + sweep_ADC_vio_parameter(cts.Vio_parameter.SCK_DELAY)
    s = s + set_ADC_vio_parameters_to_default()
    # Sweep half period
    s = s + sweep_ADC_vio_parameter(cts.Vio_parameter.HALF_PERIOD)
    s = s + set_ADC_vio_parameters_to_default()

    export_string_to_file(s)

def generate_test_2(test_2_scenario):
    export_string_to_file(trigger_ila_multiple_times(1000, cts.TEST_2_DATA_DIRECTORIES[test_2_scenario]))

def generate_test_3(test_3_scenario):
    # Between each scenario the user should setup the hardware and then run the test
    export_string_to_file(trigger_ila_multiple_times(500, cts.Test_3_scenarios[test_3_scenario]))

def generate_test_4(initial_DAC_value : int, final_DAC_value : int, increment : int, num_triggers : int, attempt : int):
    # This test changes multiple parameters of the DAC to generate input voltages along the whole input dynamic range
    # of the ADC. For each input voltage triggers multiple times the ILA component.
    
    # Create attempt directory
    attempt_directory = cts.TEST_4_DATA_DIRECTORY + str(attempt)
    utils.create_folder(attempt_directory)

    # Initial setup
    s = ""
    s = s + inital_setup_of_DAC_parameters()

    # Start sweeping
    for DAC_value in range(initial_DAC_value, final_DAC_value, increment):
        value_directory = attempt_directory+ f"\\{DAC_value}"
        utils.create_folder(value_directory)
        s = s + set_new_parameter_value(cts.Vio_parameter.DAC_VOLTAGE, DAC_value)
        s = s + push_new_DAC_voltage_value()
        s = s + trigger_ila_multiple_times(num_triggers, value_directory)
    
    export_string_to_file(s)

def sweep_ADC_vio_parameter(parameter):
    s = ""
    for value in range(cts.VIO_PARAMETER_TO_MIN_VALUE[parameter], cts.VIO_PARAMETER_TO_MAX_VALUE[parameter] + 1):
        s = s + set_new_parameter_value(parameter, value)
        s = s + trigger_ila()
        filename = "" + parameter.name + "_" + str(value)
        s = s + save_ila_data(cts.VIO_PARAMETER_TO_DATA_DIRECTORY[parameter], filename)
    return s

def inital_setup_of_DAC_parameters():
    s = ""
    # Set DAC Address to 1
    s = s + set_new_parameter_value(cts.Vio_parameter.DAC_ADDRESS, 1)
    # Set DAC voltage to HEX
    s = s + set_radix_of_parameter(cts.Vio_parameter.DAC_VOLTAGE, cts.Radix.HEX)
    # Set DAC U0B to 0 V
    s = s + set_new_parameter_value(cts.Vio_parameter.DAC_VOLTAGE, cts.DAC_UOB_0V_HEX)
    s = s + push_new_DAC_voltage_value()

    # Set DAC Address to 0
    s = s + set_new_parameter_value(cts.Vio_parameter.DAC_ADDRESS, 0)
    # Set DAC voltage radix to unsigned decimal
    s = s + set_radix_of_parameter(cts.Vio_parameter.DAC_VOLTAGE, cts.Radix.UNSIGNED)

    return s

def push_new_DAC_voltage_value():
    s = ""
    s = s + set_new_parameter_value(cts.Vio_parameter.DAC_SEND_PULSE, 0)
    s = s + set_new_parameter_value(cts.Vio_parameter.DAC_SEND_PULSE, 1)
    return s

def trigger_ila_multiple_times(N : int, relative_path : str):
    # Triggers N times ila. Used to get a big sample of ADC measurements without increasing ila samples
    s = ""
    for i in range(N):
        s = s + trigger_ila()
        s = s + save_ila_data(relative_path, str(i))
    return s

def set_ADC_vio_parameters_to_default():
    s = ""
    # Set all parameters to default
    s = s + set_new_parameter_value(cts.Vio_parameter.CNV_LENGTH, cts.DEFAULT_CNV_LENGTH)
    s = s + set_new_parameter_value(cts.Vio_parameter.SCK_DELAY, cts.DEFAULT_SCK_DELAY)
    s = s + set_new_parameter_value(cts.Vio_parameter.HALF_PERIOD, cts.DEFAULT_HALF_PERIOD)
    return s

def set_radix_of_parameter(parameter : cts.Vio_parameter, radix : cts.Radix):
    radix_str = {cts.Radix.BINARY   : "BINARY",
                 cts.Radix.OCTAL    : "OCTAL",
                 cts.Radix.HEX      : "HEX",
                 cts.Radix.UNSIGNED : "UNSIGNED",
                 cts.Radix.SIGNED   : "SIGNED"
                }
    set_radix = f"set_property OUTPUT_VALUE_RADIX {radix_str[radix]} [get_hw_probes {cts.VIO_PARAMETER_TO_PROBE[parameter]} " \
                f"-of_objects [get_hw_vios -of_objects [get_hw_devices xc7s25_0] -filter {{CELL_NAME=~\"vio\"}}]]"

    return set_radix + "\n"

def set_new_parameter_value(parameter, value):
    set_property = f"set_property OUTPUT_VALUE {value} [get_hw_probes {cts.VIO_PARAMETER_TO_PROBE[parameter]} " \
                   f"-of_objects [get_hw_vios -of_objects [get_hw_devices xc7s25_0] -filter {{CELL_NAME=~\"vio\"}}]]"
    
    commit = f"commit_hw_vio [get_hw_probes {{{cts.VIO_PARAMETER_TO_PROBE[parameter]}}} " \
             f"-of_objects [get_hw_vios -of_objects [get_hw_devices xc7s25_0] -filter {{CELL_NAME=~\"vio\"}}]]"
    return set_property + "\n" + commit + "\n"

def trigger_ila():
    run_ila = "run_hw_ila [get_hw_ilas -of_objects [get_hw_devices xc7s25_0] -filter {CELL_NAME=~\"u_ila_0\"}] -trigger_now"
    wait_ila = "wait_on_hw_ila [get_hw_ilas -of_objects [get_hw_devices xc7s25_0] -filter {CELL_NAME=~\"u_ila_0\"}]"
    #display_ila = "display_hw_ila_data [upload_hw_ila_data [get_hw_ilas -of_objects [get_hw_devices xc7s25_0] -filter {CELL_NAME=~\"u_ila_0\"}]]"
    display_ila = "upload_hw_ila_data [get_hw_ilas -of_objects [get_hw_devices xc7s25_0] -filter {CELL_NAME=~\"u_ila_0\"}]"

    return run_ila + "\n" + wait_ila + "\n" + display_ila + "\n"

def save_ila_data(relative_path, filename):
    # relative_path example (Note backslash and no backslash at the end) --> data\cnv_sweep
    # filename example (Note we don't include file extension) --> cnv_1 
    write_data = f"write_hw_ila_data -csv_file {{{cts.CURRENT_DIRECTORY}\{relative_path}\{filename}.csv}} hw_ila_data_1"
    return write_data + "\n"

def export_string_to_file(str):
    f = open("output.txt", "w")
    f.write(str)
    f.close()


def main():
    #generate_test_1()
    #generate_test_2(cts.Test_2_scenarios.ALUMINUM)
    #generate_test_3(cts.Test_3_scenarios.ALUMINUM)
    generate_test_4(1000, 2000, 10, 50, 2)

if __name__ == "__main__" :
    main()