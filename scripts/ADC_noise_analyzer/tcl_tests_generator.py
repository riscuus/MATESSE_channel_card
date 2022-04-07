from enum import Enum
import constants as cts


def sweep_ADC_vio_parameters():
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
    return s

def sweep_ADC_vio_parameter(parameter):
    s = ""
    for value in range(cts.VIO_PARAMETER_TO_MIN_VALUE[parameter], cts.VIO_PARAMETER_TO_MAX_VALUE[parameter] + 1):
        s = s + set_new_parameter_value(parameter, value)
        s = s + trigger_ila()
        filename = "" + parameter.name + "_" + str(value)
        s = s + save_ila_data(cts.VIO_PARAMETER_TO_DATA_DIRECTORY[parameter], filename)
    return s

def trigger_ila_multiple_times(N, relative_path):
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
    #export_string_to_file(sweep_ADC_vio_parameters())
    #export_string_to_file(sweep_ADC_vio_parameter(cts.Vio_parameter.HALF_PERIOD))
    export_string_to_file(trigger_ila_multiple_times(500, cts.TEST_3_DATA_DIRECTORIES[cts.Test_3_scenarios.TEMP]))

if __name__ == "__main__" :
    main()