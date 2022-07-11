----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07/08/2022
-- Module Name: tb_biquad.vhd
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

entity tb_biquad is
end tb_biquad;

architecture behave of tb_biquad is

    constant COEFF_WIDTH : natural := 32;
    constant TRUNC_WIDTH : natural := 5;
    constant DATA_WIDTH  : natural := 32;
    constant ROW_WIDTH   : natural := 4;

    constant NUM_ROWS   : natural := 1; -- 12
    constant ROW_LEN    : natural :=    10; -- 100
    constant ADC_FREQ   : natural := 5000000;
    constant F_S        : natural := ADC_FREQ / (100 * 12);

    constant NUM_SIGNAL_SAMPLES : natural := 1000;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- -1.373998238738836752 * 2^14 = 22511
    signal b1       : signed(COEFF_WIDTH - 1 downto 0) := to_signed(-22511, COEFF_WIDTH);
    -- 0.5277280004128642731 * 2^14 = 8646
    signal b2       : signed(COEFF_WIDTH - 1 downto 0) := to_signed(8646, COEFF_WIDTH);

    signal k        : signed(TRUNC_WIDTH - 1 downto 0) := (others => '0');

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
        file_open(input_file, "C:\dev\MATESSE_channel_card_repo\sim\sim_biquad\input_signal.txt", read_mode);

        while not endfile(input_file) loop
            readline(input_file, v_in_line);
            read(v_in_line, v_x);
            x <= to_signed(v_x, x'length);
            x_valid <= '1';
            wait for 200 ns;
            x_valid <= '0';
            wait for (ROW_LEN * NUM_ROWS - 1) * 200 ns; 
        end loop;
        file_close(input_file);
        wait;
    end process;

    write_data : process
        variable v_out_line : line;
        variable y_int : integer;
    begin
        file_open(output_file, "C:\dev\MATESSE_channel_card_repo\sim\sim_biquad\output_signal.txt", write_mode);
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

    biquad_module : entity concept.biquad
        generic map(
            COEFF_WIDTH => COEFF_WIDTH,
            TRUNC_WIDTH => TRUNC_WIDTH,
            DATA_WIDTH  => DATA_WIDTH,
            ROW_WIDTH   => ROW_WIDTH
        )
        port map(
            clk     => clk,
            rst     => rst,
            b1      => b1,
            b2      => b2,
            k       => k,
            x       => x,
            x_row   => x_row,
            x_valid => x_valid,
            y       => y,
            y_row   => open,
            y_valid => y_valid
        );

end behave;