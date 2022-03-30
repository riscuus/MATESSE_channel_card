from os import listdir
from os.path import isfile, join
import csv
import math
import matplotlib.pyplot as pyplot
from matplotlib.ticker import (MultipleLocator, FormatStrFormatter,
                               AutoMinorLocator)
# local files
import constants as cts


def plot_vio_parameter_sweep(parameter):
    files = get_files_of_directory(cts.VIO_PARAMETER_TO_RELATIVE_DIRECTORY[parameter])
    data = build_data_dictionary(files, parameter)
    std_deviations = calculate_std_deviations(data)
    #print(data)
    plot_data(parameter, data)
    plot_std_deviation(parameter, std_deviations)

def get_files_of_directory(directory):
    return map(lambda s: "" + directory + "/" + s, [f for f in listdir(directory) if isfile(join(directory, f))])

def build_data_dictionary(files, parameter):
    data = {}
    for file in files:
        csv_length = file[file.find(parameter.name + "_") + len(parameter.name + "_")]
        data[csv_length] = extract_data_from_file(file)
    return data

def calculate_std_deviations(data):
    std_deviations = {}
    for key in data:
        mean = calculate_mean(data[key])
        sum = 0
        for value in data[key]:
            squared_diff = pow(mean - value, 2)
            sum = sum + squared_diff
        std_deviations[key] = math.sqrt(sum/len(data[key]))
    return std_deviations

def calculate_mean(values):
    sum = 0
    for x in values:
        sum = sum + x
    return sum/len(values)


def plot_data(parameter, data):
    parameter_values, adc_readings = build_sweep_axes(data)

    fig, ax = pyplot.subplots()

    # ADC readings points
    ax.scatter(parameter_values, adc_readings, label = "ADC readings", color = "black", marker = ".", s = 10)

    # Axes labels
    pyplot.xlabel(parameter.name + " (clock cycles)")
    pyplot.ylabel("ADC readings")

    ax.legend()
    pyplot.savefig(f"results/{parameter.name}.png")

def plot_std_deviation(parameter, std_deviations):
    fig, ax = pyplot.subplots()

    # std deviation
    ax.plot(list(std_deviations.keys()), list(std_deviations.values()))

    # Axes labels
    pyplot.xlabel(parameter.name + " (clock cycles)")
    pyplot.ylabel("Std deviation")
    pyplot.savefig(f"results/std_deviation_{parameter.name}.png")


def build_sweep_axes(data):
    x = []
    y = []
    for key in data:
        # We repeat the same 'x' value as 'y' values there are
        x.extend([key for i in range(len(data[key]))])
        # We simply join in the same list all the 'y' values
        y.extend(data[key])
    return x, y

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
    return adc_value * 1.17 / (2**15 - 1)


def main():
    plot_vio_parameter_sweep(cts.Vio_parameter.SCK_DELAY)
    plot_vio_parameter_sweep(cts.Vio_parameter.CNV_LENGTH)
    plot_vio_parameter_sweep(cts.Vio_parameter.HALF_PERIOD)

if __name__ == "__main__" :
    main()