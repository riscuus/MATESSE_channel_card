% -----------------------------------------------------------------------------------
% This script generates the input signal and a pre-implemented 4 pole butterworth filter
% Allows to plot the input signal in time and frequency as well as the filtered signals. 
% -----------------------------------------------------------------------------------
%%
% PART 1 : Generate input signal
adc_freq = 5e6;
row_len = 100;
num_rows = 12;

Fs = adc_freq / (row_len * num_rows);   % Sampling frequency
T = 1/Fs;                               % Sampling period
L = 1000;                               % Number of samples
t = (0:L-1)*T;                          % Time vector

freq = 1/20 * Fs;                       % Frequency of the signal
x = (16000 / 1.7) * (sin(2*pi*freq*t) + 0.7*sin(2*pi*6*freq*t)); % Signal to filter

input_signal_file = fopen("input_signal.txt", "w");
fprintf(input_signal_file, '%f\n', x);
fclose(input_signal_file);
%%
% PART 2: plot the results

% plot signal to be filtered
subplot(3, 2, 1);
plot(t(1:100), x(1:100));
title("Input signal");
xlabel("time (s)");
ylabel("x");

% Calculate and plot input signal
fft_x = fft(x);
P2_x = abs(fft_x/L);
P1_x = P2_x(1:L/2+1);
P1_x(2:end-1) = 2*P1_x(2:end-1);
f = Fs*(0:(L/2))/L;

subplot(3, 2, 2);
plot(f, P1_x);
title("FFT(Input signal)");
xlabel("frequency (Hz)");
ylabel("FFT(x)");

% Filter signal in matlab
y = filter(Hd_4,x);

subplot(3, 2, 3);
plot(t(1:100), y(1:100));
title("Matlab Filtered signal");
xlabel("time (s)");
ylabel("y");

% Calculate and plot fft of filtered signal in matlab
fft_y = fft(y);
P2_y = abs(fft_y/L);
P1_y = P2_y(1:L/2+1);

subplot(3, 2, 4)
plot(f, P1_y);
title("FFT(Matlab filtered signal)");
xlabel("frequency (Hz)");
ylabel("FFT(y)");

% Read filtered signal from vhdl
vhdl_file = fopen("output_signal.txt", "r");
vhdl_y = fscanf(vhdl_file, '%d');
fclose(vhdl_file);
vhdl_y = vhdl_y';

% Plot vhdl filtered signal in time
subplot(3, 2, 5);
plot(t(1:100), vhdl_y(1:100));
title("VHDL output signal");
xlabel("time (s)");
ylabel("vhdl_y");

% Plot vhdl filtered signal in frequency 
fft_vhdl_y = fft(vhdl_y);
P2_vhdl_y = abs(fft_vhdl_y/L);
P1_vhdl_y = P2_vhdl_y(1:L/2+1);

subplot(3, 2, 6);
plot(f, P1_vhdl_y);
title("FFT(VHDL filtered signal)");
xlabel("frequency (Hz)");
ylabel("FFT(y)");

diff = y./vhdl_y;