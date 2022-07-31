% Read the raw data file 
f = fopen("../data/raw_data_1.csv", "r");
x_hex = textscan(f, "%s");
fclose(f);

L = length(x_hex{1, 1});
x = zeros(1, L);
for i = 1:L
    x(1, i) = hex2dec(strcat('0x',x_hex{1, 1}{i, 1}, 's32'));
end

plot(x)

%% Read last data

M = readmatrix("../data/raw_data_1.csv", 'OutputType', 'string');
M = hex2dec(strcat('0x', M, 's32'));

%% Plot all columns and rows

num_cols = 2;
num_rows = length(M(1, :))/num_cols;

for i=1:length(M(1, :)) % for each col
    if (i <= num_rows)
        subplot(num_rows, num_cols, i * 2 - 1)
    else
        subplot(num_rows, num_cols, (i - num_rows) * 2)
    end 
    plot(M(:, i))
end

%% Plot only one pixel
figure
plot(M(:, 13))

%%
%M_15 = readmatrix("../data/2_raw_data_2x12_500_ch1_ch2.csv", 'OutputType', 'string');
M_70_1 = readmatrix("../data/2_raw_data_1x12_500_ch1_70.csv", 'OutputType', 'string');
M_70_1_filt = readmatrix("../data/2_raw_data_1x12_500_ch1_70_filtered_50.csv", 'OutputType', 'string');
M_70 = readmatrix("../data/2_raw_data_2x12_500_ch1_ch2_70.csv", 'OutputType', 'string');
M_70_filt = readmatrix("../data/2_raw_data_2x12_500_ch1_ch2_70_filtered_50.csv", 'OutputType', 'string');

%M_15 = M_15(:,1);
%M_15 = hex2dec(strcat('0x', M_15, 's32'));
M_70_1 = M_70_1(:,1);
M_70_1 = hex2dec(strcat('0x', M_70_1, 's32'));
M_70_1_filt = M_70_1_filt(:,1);
M_70_1_filt = hex2dec(strcat('0x', M_70_1_filt, 's32'));
M_70 = M_70(:,1);
M_70 = hex2dec(strcat('0x', M_70, 's32'));
M_70_filt = M_70_filt(:,1);
M_70_filt = hex2dec(strcat('0x', M_70_filt, 's32'));

data = [M_70_1, M_70_1_filt, M_70, M_70_filt];
titles = ["1 channel", "1 channel filtered (fc=50Hz)", "2 channels", "2 channels filtered (fc=50Hz)"];
num_tests = length(data(1, :));


for i = 1:num_tests
    subplot(num_tests, 1, i)
    plot(data(:, i))
    title(titles(i))
end

%%

f = fopen("../data/raw_data_500_2mbps_noise_filtered.txt", "r");
x_hex = textscan(f, "%s");
fclose(f);

L = length(x_hex{1, 1});
x = zeros(1, L);
for i = 1:L
    x(1, i) = hex2dec(strcat('0x',x_hex{1, 1}{i, 1}, 's32'));
end

figure
plot(x)

f = fopen("../data/raw_data_500_2mbps.txt", "r");
x_hex = textscan(f, "%s");
fclose(f);

L = length(x_hex{1, 1});
x = zeros(1, L);
for i = 1:L
    x(1, i) = hex2dec(strcat('0x',x_hex{1, 1}{i, 1}, 's32'));
end

figure
plot(x)