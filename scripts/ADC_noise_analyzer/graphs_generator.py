from genericpath import isdir
from os import listdir
from os.path import isfile, join
import csv
import math
from numpy.fft import fft, ifft
import numpy as np
import matplotlib.pyplot as pyplot
from matplotlib.ticker import (MultipleLocator, FormatStrFormatter,
                               AutoMinorLocator)
import pprint


# local files
import constants as cts
import utils

#######################################################
# test_1
#######################################################

def generate_graph_test_1():
    generate_graph_parameter_sweep(cts.Vio_parameter.SCK_DELAY)
    generate_graph_parameter_sweep(cts.Vio_parameter.CNV_LENGTH)
    generate_graph_parameter_sweep(cts.Vio_parameter.HALF_PERIOD)

def generate_graph_parameter_sweep(parameter):
    files = get_files_of_directory(cts.VIO_PARAMETER_TO_DATA_DIRECTORY[parameter])
    data = build_data_dictionary(files, parameter)
    std_deviations = calculate_std_deviations(data)
    plot_test1_parameter_data(parameter, data)
    plot_test1_parameter_std_deviation(parameter, std_deviations)

def build_data_dictionary(files, parameter):
    data = {}
    for file in files:
        csv_length = file[file.find(parameter.name + "_") + len(parameter.name + "_")]
        data[csv_length] = extract_data_from_file(file)
    return data

def calculate_std_deviations(data):
    std_deviations = {}
    for key in data:
        mean = calculate_mean_from_array(data[key])
        sum = 0
        for value in data[key]:
            squared_diff = pow(mean - value, 2)
            sum = sum + squared_diff
        std_deviations[key] = math.sqrt(sum/len(data[key]))
    return std_deviations

def plot_test1_parameter_data(parameter, data):
    parameter_values, adc_readings = build_sweep_axes(data)

    fig, ax = pyplot.subplots()

    # ADC readings points
    ax.scatter(parameter_values, adc_readings, label = "ADC readings", color = "black", marker = ".", s = 10)

    # Axes labels
    pyplot.xlabel(parameter.name + " (clock cycles)")
    pyplot.ylabel("ADC readings")

    ax.legend()

    filename = (cts.TEST_1_RESULTS_DIRECTORY+"\\"+parameter.name+".png").replace("\\", "/")
    pyplot.savefig(filename)
    pyplot.close()

def plot_test1_parameter_std_deviation(parameter, std_deviations):
    fig, ax = pyplot.subplots()

    # std deviation
    ax.plot(list(std_deviations.keys()), list(std_deviations.values()))

    # Axes labels
    pyplot.xlabel(parameter.name + " (clock cycles)")
    pyplot.ylabel("Std deviation")

    filename = (cts.TEST_1_RESULTS_DIRECTORY+"\\"+parameter.name+"_std_deviation.png").replace("\\", "/")
    pyplot.savefig(filename)
    pyplot.close()

def build_sweep_axes(data):
    x = []
    y = []
    for key in data:
        # We repeat the same 'x' value as 'y' values there are
        x.extend([key for i in range(len(data[key]))])
        # We simply join in the same list all the 'y' values
        y.extend(data[key])
    return x, y

#######################################################
# test_2
#######################################################
def generate_graph_test_2():
    generate_graph_test_2_scenario(cts.Test_2_scenarios.ALUMINUM)
    generate_graph_test_2_scenario(cts.Test_2_scenarios.NO_ALUMINUM)

def generate_graph_test_2_scenario(test_2_scenario):
    files = get_files_of_directory(cts.TEST_2_DATA_DIRECTORIES[test_2_scenario])
    data = get_test_2_data(files)
    plot_test_2_data(data, test_2_scenario)
    plot_fft(data, cts.TEST_2_RESULTS_DIRECTORY+"\\fft_"+test_2_scenario.name+".png")

def get_test_2_data(files):
    data = []
    for file in files:
        data.extend(extract_data_from_file(file))
    mean = calculate_mean_from_array(data)
    return list(map(lambda x : x - mean, data))

def plot_test_2_data(data, test_2_scenario):
    fig, ax = pyplot.subplots()

    # ADC readings points
    ax.scatter(list(range(len(data))), data, label = "ADC readings", color = "black", marker = ".", s = 10)

    # Axes labels
    #pyplot.xlabel(parameter.name + " (clock cycles)")
    pyplot.ylabel("ADC readings")

    #ax.legend()
    pyplot.savefig(cts.TEST_2_RESULTS_DIRECTORY+"\\"+test_2_scenario.name+".png")
    pyplot.close()


#######################################################
# test_3
#######################################################

def generate_graph_test_3():
    for scenario in cts.Test_3_scenarios:
        if scenario != cts.Test_3_scenarios.ALUMINUM:
            generate_graph_test_3_scenario(scenario)

def generate_graph_test_3_scenario(test_3_scenario):
    files = get_files_of_directory(cts.TEST_3_DATA_DIRECTORIES[test_3_scenario])
    data = get_test_3_data(files)
    no_mean_data = substract_mean_from_array(data)
    plot_test_3_data(no_mean_data, test_3_scenario)
    print("std deviation " + test_3_scenario.name + " " + str(calculate_std_deviation_from_array(data)))
    print("mean " + test_3_scenario.name + " " + "{:.3f}".format(calculate_mean_from_array(data)))
    plot_test_3_histogram(no_mean_data, test_3_scenario)
    plot_test_3_fft(no_mean_data, test_3_scenario)

def get_test_3_data(files):
    data = []
    for file in files:
        data.extend(extract_data_from_file(file))
    return data

def plot_test_3_data(data, test_3_scenario):
    filename = cts.TEST_3_RESULTS_DIRECTORY+"\\"+test_3_scenario.name+".png"
    plot_array_as_scatter(data, filename)


def plot_test_3_histogram(values, test_3_scenario):
    filename = cts.TEST_3_RESULTS_DIRECTORY + "\\" + test_3_scenario.name + "_hist.png"
    plot_histogram(values, test_3_scenario.name, filename)


def plot_test_3_fft(values, test_3_scenario):
    filename = cts.TEST_3_RESULTS_DIRECTORY + "\\" + test_3_scenario.name + "_fft.png"
    plot_fft(values, filename)

#######################################################
# test_4
#######################################################
def generate_graph_test_4_double(attempt_1 : int, attempt_2 : int):
    files_1 = get_test_4_files(attempt_1)
    data_dict_1 = get_test_4_data(files_1)
    print("Keys : " + str(len(data_dict_1.keys())))
    print("Samples per key : " + str(len(data_dict_1[1100])))
     #files_2 = get_test_4_files(attempt_2)
     #data_dict_2 = get_test_4_data(files_2)

     #plot_test_4_data_double(data_dict_1, data_dict_2)



def generate_graph_test_4(attempt : int):
    files = get_test_4_files(attempt)
    data_dict = get_test_4_data(files)
    #no_mean_data_dict = substract_mean_from_dict(data_dict)
    #pprint.pprint(no_mean_data_dict)
    plot_test_4_data(data_dict, attempt)


def get_test_4_files(attempt : int) -> dict[int, list]:
    files = {}
    folders = get_folders_of_directory(cts.TEST_4_DATA_DIRECTORY+str(attempt))
    for folder in folders:
        value = int(folder[len(cts.TEST_4_DATA_DIRECTORY) + len(str(attempt) + "\\") : len(folder)])
        files[value] = get_files_of_directory(cts.TEST_4_DATA_DIRECTORY+str(attempt)+"\\"+str(value))
    return files

def get_test_4_data(files_dict : dict[int, list]) -> dict[int, list]:
    data = {}
    for dac_value in files_dict:
        if(dac_value < 1100 or dac_value > 1800):
            continue
        data[dac_value] = []
        for file in files_dict[dac_value]:
            data[dac_value].extend(extract_data_from_file(file))
    return data

def plot_test_4_data(data_dict : dict[int, list], attempt : int):
    utils.create_folder(cts.TEST_4_RESULTS_DIRECTORY + str(attempt))
    filename = cts.TEST_4_RESULTS_DIRECTORY + str(attempt) + "\\dynamic_range.png"
    plot_dict_as_error_bars(data_dict, filename)

def plot_test_4_data_double(data_dict_1 : dict[int, list], data_dict_2 : dict[int, list]):
    utils.create_folder(cts.TEST_4_RESULTS_DIRECTORY + "double")
    filename_dyn_range = cts.TEST_4_RESULTS_DIRECTORY + "double" + "\\dynamic_range.png"
    filename_std_deviation = cts.TEST_4_RESULTS_DIRECTORY + "double" + "\\std_deviation.png"
    plot_two_dict_as_error_bars(data_dict_1, data_dict_2, filename_dyn_range)
    plot_two_dict_as_std_deviation(data_dict_1, data_dict_2, filename_std_deviation)

#######################################################
# Generic
#######################################################

def get_folders_of_directory(directory):
    return list(map(lambda s: "" + directory + "\\" + s, [f for f in listdir(directory) if isdir(join(directory, f))]))

def get_files_of_directory(directory):
    return list(map(lambda s: "" + directory + "/" + s, [f for f in listdir(directory) if isfile(join(directory, f))]))

def extract_data_from_file(filename : str):
    csvfile = open(filename, newline='')
    reader = csv.reader(csvfile, delimiter=' ', quotechar='|')
    adc_values = []
    for row in reader:
        row_list = row[0].split(",")
        if(len(row_list) < 12):
            continue
        
        adc_values.append(int(row_list[5]))
    return clean_adc_values(adc_values)

def clean_adc_values(adc_values):
    values = []
    for i in range(len(adc_values) - 2 ):
        if(adc_values[i] != 0 and adc_values[i+1] == 0):
            values.append(convert_adc_value_to_voltage(adc_values[i]))
    return values

def convert_adc_value_to_voltage(adc_value):
    return adc_value * 1.232 / (2**15 - 1)

def calculate_std_deviation_from_array(values):
    mean = calculate_mean_from_array(values)
    sum = 0
    for value in values:
        squared_diff = pow(mean - value, 2)
        sum = sum + squared_diff
    return math.sqrt(sum/len(values))

def calculate_mean_from_array(values):
    sum = 0
    for x in values:
        sum = sum + x
    return sum/len(values)

def substract_mean_from_dict(data_dict : dict[int, list]) -> dict[int, list]:
    no_mean_dict = {}
    for key in data_dict:
        no_mean_dict[key] = substract_mean_from_array(data_dict[key])
    return no_mean_dict

def substract_mean_from_array(values):
    mean = calculate_mean_from_array(values)
    return list(map(lambda x : x - mean, values))

def plot_array_as_scatter(data, filename):
    fig, ax = pyplot.subplots()

    # ADC readings points
    ax.scatter(list(range(len(data))), data, color = "black", marker = ".", s = 10)

    # Axes labels
    pyplot.xlabel("Sample nº")
    pyplot.ylabel("ADC readings (V)")

    # Axes limit
    pyplot.ylim([-0.08, 0.08])

    #ax.legend()
    pyplot.savefig(filename)
    pyplot.close()


def plot_fft(data, filename):
    X = fft(data)
    N = len(data)
    n = np.arange(int(N/2))
    sr = 2E6
    T = N/sr
    freq = n/T 
    fig, ax = pyplot.subplots()
    markerline, stemline, baseline = ax.stem(freq, np.abs(X[0:int(N/2)]))
    # Axes labels
    pyplot.xlabel("Frequency (Hz)")
    pyplot.ylabel("|FFT{ADC readings (V)}|")
    pyplot.ylim([0, 25])
    pyplot.setp(markerline, markersize = 1)
    pyplot.setp(stemline, linewidth = 1)
    pyplot.savefig(filename)
    pyplot.close()

def plot_histogram(values, title, filename):
    fig, ax = pyplot.subplots()
    pyplot.hist(values, 200)
    pyplot.xlim([-0.15, 0.15])
    pyplot.savefig(filename)
    pyplot.close()

def plot_dict_as_scatter(data_dict : dict[int, list], filename):
    fig, ax = pyplot.subplots()

    x, y = build_axes_from_dict(data_dict)
    # ADC readings points
    ax.scatter(x, y, color = "black", marker = ".", s = 10)

    # Axes labels
    pyplot.xlabel("DAC value")
    pyplot.ylabel("ADC readings (V)")

    # Axes limit
    #pyplot.ylim([-0.08, 0.08])

    #ax.legend()
    pyplot.savefig(filename)
    pyplot.close()


def plot_dict_as_error_bars(data_dict, filename):
    fig, ax = pyplot.subplots(figsize=(40,20))

    y = calculate_means_from_dict(data_dict)
    x = list(data_dict.keys())
    yerr = calculate_std_deviations_from_dict(data_dict)
    
    real_x = [1800, 1700, 1600, 1500, 1400, 1300, 1200, 1100]

    real_y = [1.348, 0.988, 0.635, 0.276, -0.063, -0.417, -0.756, -0.934]


    # ADC readings points
    ax.errorbar(x, y, yerr, color = "black", fmt="none", capsize=4, elinewidth=2)
    ax.plot(real_x, real_y)

    # Axes labels
    pyplot.xlabel("DAC value", fontsize=30)
    pyplot.ylabel("ADC readings (V)", fontsize=30)

    # Axes ticks
    ax.minorticks_on()
    ax.get_yaxis().set_major_locator(MultipleLocator(0.25))
    #ax.get_xaxis().set_major_locator(MultipleLocator(2))
    #ax.get_xaxis().set_minor_locator(MultipleLocator(0.2))
    ax.tick_params(axis='both', which='major', labelsize=20)
    # Grid
    ax.grid(visible=True, which='major', axis='both', linewidth=1)
    ax.grid(visible=True, which='minor', axis='both', linewidth=0.5)
    # Axes limit

    #ax.legend()
    pyplot.savefig(filename, dpi=400)
    pyplot.close()

def plot_two_dict_as_error_bars(data_dict_1 : dict[int, list], data_dict_2 : dict[int, list], filename : str):
    fig, ax = pyplot.subplots(figsize=(40,20))

    y_1 = calculate_means_from_dict(data_dict_1)
    x_1 = list(data_dict_1.keys())
    yerr_1 = calculate_std_deviations_from_dict(data_dict_1)
    
    y_2 = calculate_means_from_dict(data_dict_2)
    x_2 = list(data_dict_2.keys())
    yerr_2 = calculate_std_deviations_from_dict(data_dict_2)
    
    real_x = [1800, 1700, 1600, 1500, 1400, 1300, 1200, 1100]

    real_y = [1.348, 0.988, 0.635, 0.276, -0.063, -0.417, -0.756, -0.934]


    # ADC readings points
    ax.errorbar(x_1, y_1, yerr_1, fmt="none", capsize=4, elinewidth=2, color = "#1f77b4", label="Std. deviation PCB open")
    ax.errorbar(x_2, y_2, yerr_2, fmt="none", capsize=4, elinewidth=2, color = "#ff7f0e", label = "Std. deviation PCB wrapped in aluminum")
    ax.plot(real_x, real_y, '.-', color = "black", label = "Multimeter readings")

    # Axes labels
    pyplot.xlabel("DAC value (DEC)", fontsize=30)
    pyplot.ylabel("ADC readings (V)", fontsize=30)

    # Axes ticks
    ax.minorticks_on()
    ax.get_yaxis().set_major_locator(MultipleLocator(0.25))
    #ax.get_xaxis().set_major_locator(MultipleLocator(2))
    #ax.get_xaxis().set_minor_locator(MultipleLocator(0.2))
    ax.tick_params(axis='both', which='major', labelsize=20)
    # Grid
    ax.grid(visible=True, which='major', axis='both', linewidth=1)
    ax.grid(visible=True, which='minor', axis='both', linewidth=0.5)
    # Axes limit

    ax.legend(prop={'size': 30})
    pyplot.savefig(filename, dpi=400)
    pyplot.close()


def plot_two_dict_as_std_deviation(data_dict_1 : dict[int, list], data_dict_2 : dict[int, list], filename : str):
    fig, ax = pyplot.subplots(figsize=(40,20))

    x_1 = list(data_dict_1.keys())
    y_1 = list(map(lambda x : x * 1000, calculate_std_deviations_from_dict(data_dict_1)))
    
    x_2 = list(data_dict_2.keys())
    y_2 = list(map(lambda x : x * 1000, calculate_std_deviations_from_dict(data_dict_2)))
    
    # ADC readings points
    ax.plot(x_1, y_1, '.-', label="PCB open")
    ax.plot(x_2, y_2, '.-', label="PCB wrapped in aluminum foil")

    # Axes labels
    pyplot.xlabel("DAC value (DEC)", fontsize=30)
    pyplot.ylabel("Std. deviation (mV)", fontsize=30)

    # Axes ticks
    ax.minorticks_on()
    #ax.get_yaxis().set_major_locator(MultipleLocator(0.25))
    #ax.get_xaxis().set_major_locator(MultipleLocator(2))
    #ax.get_xaxis().set_minor_locator(MultipleLocator(0.2))
    ax.tick_params(axis='both', which='major', labelsize=20)
    # Grid
    ax.grid(visible=True, which='major', axis='both', linewidth=1)
    ax.grid(visible=True, which='minor', axis='both', linewidth=0.5)
    # Axes limit

    ax.legend(prop={'size': 30})
    pyplot.savefig(filename, dpi=400)
    pyplot.close()


def build_axes_from_dict(data_dict):
    x = []
    y = []

    for key in data_dict:
        # We repeat the same 'x' value as 'y' values there are
        x.extend([key for i in range(len(data_dict[key]))])
        # We simply join in the same list all the 'y' values
        y.extend(data_dict[key])
    return x, y

def calculate_means_from_dict(data_dict : dict[int, list]) -> list:
    means = []
    for key in data_dict:
        means.append(calculate_mean_from_array(data_dict[key]))
    return means

def calculate_std_deviations_from_dict(data_dict : dict[int, list]) -> list:
    deviations = []
    for key in data_dict:
        deviations.append(calculate_std_deviation_from_array(data_dict[key]))
    return deviations

def main():
    #generate_graph_test_1()
    #generate_graph_test_2()
    #generate_graph_test_3()
    #generate_graph_test_4(3)
    generate_graph_test_4_double(2, 3)

if __name__ == "__main__" :
    main()