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
f = Fs*(0:(L/2))/L;                     % Frequency vector

freq = 1/20 * Fs;                       % Frequency of the signal
x = (16000 / 1.7) * (sin(2*pi*freq*t) + 0.7*sin(2*pi*6*freq*t)); % Signal to filter

input_signal_file = fopen("input_signal.txt", "w");
fprintf(input_signal_file, '%f\n', x);
fclose(input_signal_file);
%%
% PART 2: plot the results

% plot signal to be filtered
subplot_time(t, x, 1, "Input signal");
subplot_freq(f, calc_fft(x, L), 2, "FFT(Input signal)");

% Filter signal in matlab
y = filter(Hd_4,x);

subplot_time(t, y, 3, "Matlab filtered signal");
subplot_freq(f, calc_fft(y, L), 4, "FFT(Matlab filtered signal)");


% Read filtered signals from vhdl
N = 2;
for i = 0:N-1
    vhdl_file = fopen("output_signal_"+i+".txt", "r");
    vhdl_y = fscanf(vhdl_file, '%d');
    fclose(vhdl_file);
    vhdl_y = vhdl_y';

    % Plot vhdl filtered signal in time
    subplot_time(t, vhdl_y, 5+2*i, "VHDL output signal");
    subplot_freq(f, calc_fft(vhdl_y, L), 6+2*i, "FFT(VHDL filtered signal)");

    diff(i+1, 1:L) = y./vhdl_y;
end



function subplot_time(t, x, i, title_str)
    subplot(4, 2, i);
    plot(t(1:100), x(1:100));
    title(title_str);
    xlabel("time (s)");
    %ylabel("vhdl_y");
end

function subplot_freq(f, x, i, title_str)
    subplot(4, 2, i);
    plot(f, x);
    title(title_str);
    xlabel("frequency (Hz)");
    %ylabel("vhdl_y");
end

function P1_x = calc_fft(x, L)
    fft_x = fft(x);
    P2_x = abs(fft_x/L);
    P1_x = P2_x(1:L/2+1);
    P1_x(2:end-1) = 2*P1_x(2:end-1);
end