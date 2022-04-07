# ADC noise analyzer

The steps to generate the different tests for the ADC are the following:

1. Run the **tcl_tests_generator.py** script
2. This will generate the **output.txt** file. Copy-paste the contents of this file to the tcl console in Vivado and execute it. This will generate some *.csv* files under the **data/** folder.
4. Run the **graphs_generator.py** script to analyze the data. This will generate some outputs under the **results/** folder.

Right now 3 different tests are defined:

* test_1 : Changes different timming parameters of the ADC to see how do they affect the noise
* test_2 : Triggers a large ammount of times the **ila** to save a large amount of samples of one voltage level. This allow us to better analyze the noise by for example generating the FFT of the data.
* test_3 : Triggers for different scenarios a large ammount of time the **ila**. Later we analyze the noise in each scenario.