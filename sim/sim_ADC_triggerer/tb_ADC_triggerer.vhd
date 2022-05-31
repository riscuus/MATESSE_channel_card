----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/31/2022
-- Module Name: tb_ADC_triggerer.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the ADC_triggerer module
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

entity tb_ADC_triggerer is
end tb_ADC_triggerer;

architecture behave of tb_ADC_triggerer is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant ACQUISITION_START  : time := 1050 ns; 
    constant ACQUISITION_END    : time := 530 us; 
    constant SYNC_FRAME_DLY     : time := 2 us;
    constant SIM_DURATION       : time := 100 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- Row selector signals
    signal acquisition_on   : std_logic := '0';
    signal sync_frame       : std_logic := '0';
    signal num_rows         : natural   := 12;
    signal row_len          : natural   := 200;
    
    -- row_selector -> ADC_triggerer
    signal new_row      : std_logic := '0';
    signal frame_active : std_logic := '0';
    
    -- 20 * 100 MHz = 5MHz
    signal trigg_clk_cycles : natural   := 20;

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

    acquisition_on_gen : process
    begin
        wait for ACQUISITION_START;
        acquisition_on <= '1';
        wait for ACQUISITION_END;
        acquisition_on <= '0';
        wait for SIM_DURATION;
    end process;

    sync_frame_gen : process
    begin
        wait for ACQUISITION_START + 300 ns;
        sync_frame <= '1';
        wait for 2 * T_HALF_CLK;
        sync_frame <= '0';
        wait for SYNC_FRAME_DLY;
    end process;

    -- Module

    row_selector_module : entity concept.row_selector
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            sync_frame      => sync_frame,
            acquisition_on  => acquisition_on,
            num_rows        => num_rows,
            row_len         => row_len,
            new_row         => new_row,
            row_num         => open,
            frame_active    => frame_active
        );

    ADC_triggerer_module : entity concept.ADC_triggerer
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,

            frame_active        => frame_active,
            trigg_clk_cycles    => trigg_clk_cycles,
            ADC_start_pulse     => open
        );
end behave;

