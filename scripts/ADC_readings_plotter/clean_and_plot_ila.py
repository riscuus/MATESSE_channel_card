from cProfile import label
import csv
from distutils.command.build import build
import math
import matplotlib.pyplot as pyplot
from os import listdir
from os.path import isfile, join
from matplotlib.ticker import (MultipleLocator, FormatStrFormatter,
                               AutoMinorLocator)

def get_files():
    # Gets all files in the data/output folder
    return map(lambda s: "data/output/" + s, [f for f in listdir("data/output") if isfile(join("data/output", f))])


def extract_values(filename):
    # Export the data from the outputs .csv
    DAC_value = ""
    ADC_values = []
    counter = 0
    csvfile = open(filename, newline='')
    reader = csv.reader(csvfile, delimiter=' ', quotechar='|')
    ADC_buffer = []
    for row in reader:
        row_list = row[0].split(",")
        if(len(row_list) > 1):
            # We store the DAC value once
            if(counter == 3):
                DAC_value = row_list[3]
            current = row_list[4]
            if(len(ADC_buffer) == 0):
                ADC_buffer.append(current)
            elif(ADC_buffer[0] != current):
                ADC_buffer.clear()
                ADC_buffer.append(current)
            else:
                ADC_buffer.append(current)
                if(len(ADC_buffer) == 11):
                    ADC_values.append(current)
        counter = counter + 1
    return DAC_value, ADC_values

def extract_input_values(filename):
    # Extracts all data from the input .csv
    csvfile = open(filename, newline='')
    reader = csv.reader(csvfile, delimiter=' ', quotechar='|')
    dac_values = []
    vin = []
    vout = []
    for row in reader:
        row_list = row[0].split(",")
        dac_values.append(row_list[0])
        vin.append(float(row_list[1])/1000)
        vout.append(float(row_list[2])/1000)
    return interpolate_list(dac_values), interpolate_list(vin), interpolate_list(vout)

def interpolate_list(input):
    # Interpolates with 2 new values the input data
    output_list = []
    for i in range(len(input) - 1):
        current = float(input[i])
        nxt = float(input[i + 1]) 
        diff = nxt - current
        inc = diff / 3
        output_list.append(current)
        output_list.append(current + inc)
        output_list.append(current + 2 * inc)
    output_list.append(float(input[len(input) - 1]))
    return output_list

def hex_to_dec(hex_value):
    # Converts the hexadecimal value to the decimal representation
    return int(hex_value, 16)

def ADC_value_to_voltage(value):
    # Converts the ADC value to its theoretical voltage meaning. The 1.098 comes determined by the reference voltage
    return (int(value) * 1.098 / 32767 * 2)

def plot_input_vs_output_and_ADC(data):
    # Plots the input vs output graph

    # Put into 'x', 'y' arrays the data to be plotted
    extended_vin, ADC_readings = build_vin_vs_ADC_axes(data)
    vin, vout = build_vin_vs_vout_axes(data)

    fig, ax = pyplot.subplots()

    # ADC input values line
    ax.plot(vin, vout, label = "Expected value", color = "blue")

    # ADC readings points
    ax.scatter(extended_vin, ADC_readings, label = "ADC readings", color = "black", marker = ".", s = 10)

    # Axes ticks
    ax.minorticks_on()
    ax.get_yaxis().set_major_locator(MultipleLocator(0.25))
    ax.get_xaxis().set_major_locator(MultipleLocator(2))
    ax.get_xaxis().set_minor_locator(MultipleLocator(0.2))

    # Grid
    ax.grid(visible=True, which='major', axis='both', linewidth=1)
    ax.grid(visible=True, which='minor', axis='both', linewidth=0.5)

    # Axes labels
    pyplot.xlabel("Amplifiers input voltage (mV)")
    pyplot.ylabel("ADC input voltage (V)")

    ax.legend()

    pyplot.show()


def build_vin_vs_ADC_axes(data):
    x = []
    y = []
    for key in data:
        # We repeat the same 'x' value as 'y' values there are
        x.extend([data[key][1] for i in range(len(data[key][0]))])
        # We simply join in the same list all the 'y' values
        y.extend(data[key][0])
    return x, y

def build_vin_vs_vout_axes(data):
    x = []
    y = []
    for key in data:
        x.append(data[key][1])
        y.append(data[key][2])
    return x, y

def calculate_standard_deviation(data):
    std_deviations = {}
    for key in data:
        mean = calculate_mean(data[key][0])
        sum = 0
        for value in data[key][0]:
            squared_diff = pow(mean - value, 2)
            sum = sum + squared_diff
        std_deviations[data[key][2]] = math.sqrt(sum/len(data[key][0]))
    return std_deviations

def calculate_mean(values):
    sum = 0
    for x in values:
        sum = sum + x
    return sum/len(values)

def calculate_average_standard_deviation(std_deviations):
    count = 0
    sum = 0
    for key in std_deviations:
        #print(std_deviations[key])
        if(count > 20 and count < 40):
            sum = sum + std_deviations[key]
        count = count + 1
    return sum/20


def main():
    # Each key (the DAC value) contains a list. This list contains 3 elements. The first one is a list of all the ADC
    # readings for that DAC value, the second is the voltage before the amplifier, the third is the voltage after the
    # amplifier 
    data = {}
    files = get_files()
    for filename in files:
        DAC_value, ADC_values = extract_values(filename)
        data[hex_to_dec(DAC_value)] = [list(map(ADC_value_to_voltage, ADC_values[15 : len(ADC_values) - 1]))]
    
    dac_values, vin, vout = extract_input_values("data/input/inputs.csv")
    for i in range(len(dac_values)):
        data[dac_values[i]].append(round(vin[i] * 1000, 1))
        data[dac_values[i]].append(vout[i])

    std_deviations = calculate_standard_deviation(data)
    print("Average of the standard deviations: ", calculate_average_standard_deviation(std_deviations))

    plot_input_vs_output_and_ADC(data)


if __name__ == "__main__" :
    main()