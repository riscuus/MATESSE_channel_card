----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/29/2022
-- Module Name: tb_sample_selector.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the sample_selector module
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library concept;
use concept.utils.all;

entity tb_sample_selector is
end tb_sample_selector;

architecture Behavioral of tb_sample_selector is

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

    -- test signals
    signal sample_dly       : natural := 3;
    signal sample_num       : natural := 5;
    signal new_row          : std_logic := '0';
    signal valid_word       : std_logic := '0';
    signal parallel_data    : t_adc_sample := (others => '0');

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

    -- Module
    sample_selector_module : entity concept.sample_selector
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            sample_dly      => sample_dly,
            sample_num      => sample_num,
            new_row         => new_row,
            valid_word      => valid_word,
            parallel_data   => parallel_data,
            valid_sample    => open,
            sample_data     => open
        );

end Behavioral;
