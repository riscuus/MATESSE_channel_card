----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07/08/2022
-- Module Name: tb_signal_generator.vhd
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
use std.textio.all;

library concept;
use concept.utils.all;

entity tb_signal_generator is
end tb_signal_generator;

architecture behave of tb_signal_generator is

    -- We want a fast freq of around 200 Hz -> freq = 1 / (n_cycles * (2*2^M - 2) * T_sample )
    constant NUM_CYCLES_WIDTH        : natural := 6; -- We want the fast signal around 
    constant CYCLES_MULTPLR_WIDTH    : natural := 4; -- We can make the slow signal around 11 times slower
    constant K_GAIN_WIDTH            : natural := 4; -- We can amplify from 1 to 11. This covers the whole range
    constant DATA_WIDTH              : natural := 16; -- 16 DAC bits
    constant M                       : natural := 8; -- For going from 0 to 1 we will take 256 samples

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal n_cycles : unsigned(NUM_CYCLES_WIDTH - 1 downto 0) := to_unsigned(50, NUM_CYCLES_WIDTH); -- This will provide us around 200 Hz for the slow sgnal
    signal cycles_multplr : unsigned(CYCLES_MULTPLR_WIDTH - 1 downto 0) := to_unsigned(6, CYCLES_MULTPLR_WIDTH);
    signal k_gain : unsigned(K_GAIN_WIDTH - 1 downto 0) := to_unsigned(9, K_GAIN_WIDTH);
    signal offset : unsigned(DATA_WIDTH - 1 downto 0) := to_unsigned(1400, DATA_WIDTH);

    signal num_samples : natural := 10000;

    signal data         : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal data_valid   : std_logic := '0';

    file gen_signal_file : text;

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


    signal_generator_module : entity concept.signal_generator
        generic map(
            NUM_CYCLES_WIDTH        => NUM_CYCLES_WIDTH,
            CYCLES_MULTPLR_WIDTH    => CYCLES_MULTPLR_WIDTH,
            K_GAIN_WIDTH            => K_GAIN_WIDTH,
            DATA_WIDTH              => DATA_WIDTH,
            M                       => M
        )
        port map(
            clk                 => clk,
            rst                 => rst,

            enable_slow         => '1',
            enable_fast         => '1',
            n_cycles            => n_cycles,
            cycles_multplr      => cycles_multplr,

            k_gain              => k_gain,
            offset              => offset,

            data                => data,
            data_valid          => data_valid
        );
    
    data_exporter : process
        variable i : natural := 0;

        variable v_out_line : line;
        variable data_int : integer;
    begin
        file_open(gen_signal_file, "C:\dev\MATESSE_channel_card_repo\sim\sim_signal_generator\gen_signal.txt", write_mode);
        while i < num_samples loop
            wait until data_valid = '1'; 

            data_int := to_integer(unsigned(data));
            write(v_out_line, data_int);
            writeline(gen_signal_file, v_out_line);
            i := i + 1;

        end loop;

        file_close(gen_signal_file);

        wait;

    end process;

end behave;