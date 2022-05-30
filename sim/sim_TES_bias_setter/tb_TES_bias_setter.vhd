----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/30/2022
-- Module Name: tb_TES_bias_setter.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the row_selector module
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

entity tb_TES_bias_setter is
end tb_TES_bias_setter;

architecture behave of tb_TES_bias_setter is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant SET_BIAS_START     : time := 2 us;
    constant SET_BIAS_LENGTH    : time := 400 ns;
    constant SIM_DURATION       : time := 100 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- Module signals

    signal set_bias : std_logic := '0';
    signal TES_bias : param_array(3 downto 0) := (0 => x"00000000",
                                                  1 => x"00000001",
                                                  2 => x"00000002",
                                                  3 => x"00000003"
                                                 );
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
    
    -- Test cases generation

    set_bias_gen : process
    begin
        wait for SET_BIAS_START;
        set_bias <= '1';
        wait for SET_BIAS_LENGTH;
        set_bias <= '0';
        wait for 1 us;
    end process;

    -- Module

    TES_bias_setter : entity concept.TES_bias_setter
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            set_bias        => set_bias,
            TES_bias        => TES_bias,
            DAC_start_pulse => open,
            DAC_data        => open
        );

end behave;

