% Read the raw data file 
f = fopen("../data/raw_data_1.txt", "r");
x_hex = textscan(f, "%s");
fclose(f);

L = length(x_hex{1, 1});
x = zeros(1, L);
for i = 1:L
    x(1, i) = hex2dec(strcat('0x',x_hex{1, 1}{i, 1}, 's32'));
end

%x = x./15;

plot(x)