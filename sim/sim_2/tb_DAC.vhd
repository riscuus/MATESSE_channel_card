----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03/03/2022
-- Module Name: tb_DAC.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench for the DAC

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
use concept.all;

entity tb_test_DAC is
end tb_test_DAC;

architecture Behavioral of tb_test_DAC is

    -- Constants
    constant T_HALF_CLK         : time := 5 ns;
    constant RST_START          : time := 32 ns;
    constant START_TIME         : time := 403 ns;
    constant START_PULSE_LENGTH : time := 26 ns;
    constant SIM_DURATION       : time := 5 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- DAC signals
    signal start_pulse  : std_logic;


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
        sys_rst <= '1';
        wait for RST_START; 
        sys_rst <= '0';
        wait for SIM_DURATION;
    end process;

    -- start pulse

    start_pulse_generation : process
    begin
        start_pulse <= '0';
        wait for START_TIME;
        start_pulse <= '1';
        wait for START_PULSE_LENGTH;
        start_pulse <= '0';
        wait for SIM_DURATION;
    end process;


    -- test_DAC module

    test_DAC_module : entity concept.test_DAC
        port map(
            sys_clk              => sys_clk,
            sys_rst              => sys_rst,
            DAC_start_pulse      => start_pulse,
            SDI_IO28             => open,
            LD_IO13              => open,
            CS_IO26              => open,
            CK_IO27              => open,
            clk_5mhz             => open,
            clk_100mhz           => open
        );

end Behavioral;
