----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07/08/2022
-- Module Name: tb_butterworth_filter_cascade.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the biquad module
--              The idea is to generate a waveform and check that the resulting wayform 
--              coincides with the one generated in matlab
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all; -- Allows to open and read a file
--use ieee.std_logic_textio.all; -- Adding this package also allows to read std_logic_vectors from the file

library concept;
use concept.utils.all;

entity tb_butterworth_filter_cascade is
end tb_butterworth_filter_cascade;

architecture behave of tb_butterworth_filter_cascade is

    constant COEFF_WIDTH    : natural := 32;
    constant TRUNC_WIDTH    : natural := 5;
    constant DATA_WIDTH     : natural := 32;
    constant ROW_WIDTH      : natural := 4;
    constant RAM_ADDR_WIDTH : natural := 9;

    constant NUM_ROWS   : natural := 1; -- 12
    constant ROW_LEN    : natural := 10; -- 100
    constant ADC_FREQ   : natural := 5000000;
    constant F_S        : natural := ADC_FREQ / (100 * 12);

    constant NUM_SIGNAL_SAMPLES : natural := 1000;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal filtr_coeff : t_param_array(0 to PARAM_ID_TO_SIZE(FILTR_COEFF_ID) - 1) := (others => (others => '0'));

    -- -1.540944328506029359360240960086230188608 * 2^14 = -25246
    signal b11       : signed(WORD_WIDTH - 1 downto 0) := to_signed(-25246, WORD_WIDTH);
    -- 0.713352849634565577829903304518666118383 * 2^14 = 11687
    signal b12       : signed(WORD_WIDTH - 1 downto 0) := to_signed(11687, WORD_WIDTH);
    -- log2(0.043102130282134040739627778293652227148) = 4.53 -> k = 4
    signal k1        : unsigned(WORD_WIDTH - 1 downto 0) := to_unsigned(4, WORD_WIDTH);
    -- -1.281247989276201870723070896929129958153 * 2^14 = -20991
    signal b21       : signed(WORD_WIDTH - 1 downto 0) := to_signed(-20991, WORD_WIDTH);
    -- 0.424600391399765186850601139667560346425 * 2^14 = 6956
    signal b22       : signed(WORD_WIDTH - 1 downto 0) := to_signed(6956, WORD_WIDTH);
    -- log2(0.03583810053089082209298865677737921942)= 4.8 -> k = 4
    signal k2        : unsigned(WORD_WIDTH - 1 downto 0) := to_unsigned(4, WORD_WIDTH);

    signal x        : signed(DATA_WIDTH - 1 downto 0)  := (others => '0');
    signal x_row    : unsigned(ROW_WIDTH - 1 downto 0) := (others => '0');
    signal x_valid  : std_logic := '0';

    signal y        : signed(DATA_WIDTH - 1 downto 0)  := (others => '0');
    signal y_valid  : std_logic := '0';

    signal clk_counter : natural := 0;
    signal samples_counter : natural := 0;

    -- File needed signals
    file input_file : text;
    file output_file : text;

begin

    filtr_coeff(0) <= std_logic_vector(b11);
    filtr_coeff(1) <= std_logic_vector(b12);
    filtr_coeff(2) <= std_logic_vector(b21);
    filtr_coeff(3) <= std_logic_vector(b22);
    filtr_coeff(4) <= std_logic_vector(k1);
    filtr_coeff(5) <= std_logic_vector(k2);

    -- 5 CLK generation
    clk_generation : process 
    begin
        clk <= '1';
        wait for 100 ns; 
        clk <= '0';
        wait for 100 ns;
    end process;

    -- Reset generation
    rst_generation : process
    begin
        rst <= '0';
        wait for 300 ns; 
        rst <= '1';
        wait for 500 ns;
        rst <= '0';
        wait;
    end process;

    read_data : process
        variable v_in_line : line;
        variable v_x : integer;
    begin
        wait for 1 us;
        file_open(input_file, "C:\dev\MATESSE_channel_card_repo\sim\sim_butterworth_filter_cascade\input_signal.txt", read_mode);

        while not endfile(input_file) loop
            readline(input_file, v_in_line);
            read(v_in_line, v_x);
            x <= to_signed(v_x, x'length);
            wait for (ROW_LEN * NUM_ROWS) * 200 ns; 
        end loop;
        file_close(input_file);
        wait;
    end process;

    set_valid_data : process(rst, clk)
    begin
        if(rst = '1') then
            x_valid <= '0';
        elsif(rising_edge(clk)) then
            if (clk_counter = ROW_LEN * NUM_ROWS - 1) then
                x_valid <= '1';
                clk_counter <= 0;
            else
                x_valid <= '0';
                clk_counter <= clk_counter + 1;
            end if;
        end if;
    end process;

    write_data : process
        variable v_out_line : line;
        variable y_int : integer;
    begin
        file_open(output_file, "C:\dev\MATESSE_channel_card_repo\sim\sim_butterworth_filter_cascade\output_signal.txt", write_mode);
        while samples_counter < NUM_SIGNAL_SAMPLES loop
            wait until y_valid = '1';
            wait for 200 ns; -- To allow y to be set corectly
            y_int := to_integer(y);
            write(v_out_line, y_int);
            writeline(output_file, v_out_line);
            samples_counter <= samples_counter + 1;
            wait for 1 ps;
        end loop;
        file_close(output_file);
        wait;
    end process;

    filter_module : entity concept.butterworth_filter_cascade
        generic map(
            COEFF_WIDTH => COEFF_WIDTH,
            TRUNC_WIDTH => TRUNC_WIDTH,
            DATA_WIDTH  => DATA_WIDTH,
            ROW_WIDTH   => ROW_WIDTH,
            RAM_ADDR_WIDTH  => RAM_ADDR_WIDTH
        )
        port map(
            clk             => clk,
            rst             => rst,

            filtr_coeff    => filtr_coeff,

            x               => x,
            x_row           => x_row,
            x_valid         => x_valid,

            y               => y,
            y_row           => open,
            y_valid         => y_valid
        );

end behave;