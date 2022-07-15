% -----------------------------------------------------------------------------------
% This script plots the generated signal in the testbench of the signal
% generator module
% -----------------------------------------------------------------------------------

gen_signal_file = fopen("gen_signal.txt", "r");
x = fscanf(gen_signal_file, '%d');
fclose(gen_signal_file);
x = x';
plot(1:length(x), x);