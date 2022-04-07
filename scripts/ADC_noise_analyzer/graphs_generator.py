from os import listdir
from os.path import isfile, join
import csv
import math
from numpy.fft import fft, ifft
import numpy as np
import matplotlib.pyplot as pyplot
from matplotlib.ticker import (MultipleLocator, FormatStrFormatter,
                               AutoMinorLocator)
# local files
import constants as cts

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
# Generic
#######################################################

def get_files_of_directory(directory):
    return list(map(lambda s: "" + directory + "/" + s, [f for f in listdir(directory) if isfile(join(directory, f))]))

def extract_data_from_file(filename):
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


def main():
    #generate_graph_test_1()
    #generate_graph_test_2()
    generate_graph_test_3()

if __name__ == "__main__" :
    main()