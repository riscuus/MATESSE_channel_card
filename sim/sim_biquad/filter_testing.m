adc_freq = 5e6;
row_len = 100;
num_rows = 12;

Fs = adc_freq / (row_len * num_rows);   % Sampling frequency
T = 1/Fs;                               % Sampling period
L = 1000;                               % Number of samples
t = (0:L-1)*T;                          % Time vector

freq = 1/20 * Fs;                          % Frequency of the signal
x = (16000 / 1.7) * (sin(2*pi*freq*t) + 0.7*sin(2*pi*6*freq*t)); % Signal to filter

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

% Filter signal
y = filter(Hd,x);

subplot(3, 2, 3);
plot(t(1:100), y(1:100));
title("Matlab Filtered signal");
xlabel("time (s)");
ylabel("y");

% Calculate and plot fft of filtered signal
fft_y = fft(y);
P2_y = abs(fft_y/L);
P1_y = P2_y(1:L/2+1);

subplot(3, 2, 4)
plot(f, P1_y);
title("FFT(Matlab filtered signal)");
xlabel("frequency (Hz)");
ylabel("FFT(y)");

% Read output from biquad simulation and plot it
vhdl_file = fopen("output_signal.txt", "r");
vhdl_y = fscanf(vhdl_file, '%d');
fclose(vhdl_file);
vhdl_y = vhdl_y';

subplot(3, 2, 5);
plot(t(1:100), vhdl_y(1:100));
title("VHDL output signal");
xlabel("time (s)");
ylabel("vhdl_y");

fft_vhdl_y = fft(vhdl_y);
P2_vhdl_y = abs(fft_vhdl_y/L);
P1_vhdl_y = P2_vhdl_y(1:L/2+1);

subplot(3, 2, 6);
plot(f, P1_vhdl_y);
title("FFT(VHDL filtered signal)");
xlabel("frequency (Hz)");
ylabel("FFT(y)");