----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/29/2022
-- Module Name: tb_sample_accumulator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the sample_accumulator module
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library concept;
use concept.utils.all;

entity tb_sample_accumulator is
end tb_sample_accumulator;

architecture Behavioral of tb_sample_accumulator is

    -- Constants
    constant T_HALF_CLK         : time := 5 ns;
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 100 ns;
    constant FIVE_MHZ_PERIOD    : time := 200 ns;
    constant NEW_ROW_DLY        : time := 20 * FIVE_MHZ_PERIOD;
    constant SIM_DURATION       : time := 200 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- Sample selector signals
    signal sample_dly       : unsigned(bits_req(MAX_SAMPLE_DLY) - 1 downto 0) := to_unsigned(3, bits_req(MAX_SAMPLE_DLY));
    signal sample_num       : unsigned(bits_req(MAX_SAMPLE_NUM) - 1 downto 0) := to_unsigned(5, bits_req(MAX_SAMPLE_NUM));
    signal new_row          : std_logic := '0';
    signal valid_word       : std_logic := '0';
    signal parallel_data    : t_adc_sample := (others => '0');

    -- sample_selector -> sample_accumulator
    signal valid_sample     : std_logic := '0';
    signal sample_data      : t_adc_sample := (others => '0');

begin

    -- CLK generation
    clk_generation : process 
    begin
        sys_clk <= '1';
        wait for T_HALF_CLK; 
        sys_clk <= '0';
        wait for T_HALF_CLK;
    end process;

    -- Reset generation
    rst_generation : process
    begin
        sys_rst <= '0';
        wait for RST_START; 
        sys_rst <= '1';
        wait for RST_PULSE_LENGTH;
        sys_rst <= '0';
        wait for SIM_DURATION;
    end process;

    -- new_row generation
    new_row_gen : process
    begin
        new_row <= '1';
        wait for FIVE_MHZ_PERIOD;
        new_row <= '0';
        wait for NEW_ROW_DLY;
    end process;

    -- Test cases generation
    words_generation : process
    begin
        wait for RST_START + RST_PULSE_LENGTH + 120 ns;
        -- Sample #1
        valid_word <= '1';
        parallel_data <= x"0001";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #2
        valid_word <= '1';
        parallel_data <= x"0002";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #3
        valid_word <= '1';
        parallel_data <= x"0003";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #4
        valid_word <= '1';
        parallel_data <= x"0004";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #5
        valid_word <= '1';
        parallel_data <= x"0005";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #6
        valid_word <= '1';
        parallel_data <= x"0006";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #7
        valid_word <= '1';
        parallel_data <= x"0007";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #8
        valid_word <= '1';
        parallel_data <= x"0008";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #9
        valid_word <= '1';
        parallel_data <= x"0009";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
        -- Sample #10
        valid_word <= '1';
        parallel_data <= x"0010";
        wait for 2 * T_HALF_CLK;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK;
    end process;

    -- Sample selector module, we include it to test sample_accumulator
    sample_selector_module : entity concept.sample_selector
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            sample_dly      => sample_dly,
            sample_num      => sample_num,
            new_row         => new_row,
            valid_word      => valid_word,
            parallel_data   => parallel_data,
            valid_sample    => valid_sample,
            sample_data     => sample_data
        );

    -- Module
    sample_accumulator_module : entity concept.sample_accumulator
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            sample_num      => sample_num,
            valid_sample    => valid_sample,
            sample          => sample_data,
            row_num         => to_unsigned(3, bits_req(MAX_ROWS)),
            acc_sample      => open
        );

end Behavioral;
