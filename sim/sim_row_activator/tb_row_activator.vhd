----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/30/2022
-- Module Name: tb_row_activator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the row_activator module
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

entity tb_row_activator is
end tb_row_activator;

architecture behave of tb_row_activator is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant ACQUISITION_START  : time := 1050 ns; 
    constant ACQUISITION_END    : time := 530 us; 
    constant SYNC_FRAME_DLY     : time := 5 us;
    constant SIM_DURATION       : time := 100 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- row_selector signals
    signal acquisition_on   : std_logic := '0';
    signal sync_frame       : std_logic := '0';
    signal num_rows         : natural   := 10;
    signal row_len          : natural   := 40;

    -- row_selector -> row_activator
    signal new_row  : std_logic := '0';
    signal row_num  : natural := 0;

    -- row_activator signals
    signal on_bias      : std_logic_vector(15 downto 0) := x"FFFF";
    signal off_bias     : std_logic_vector(15 downto 0) := x"0F0F";
    signal update_off   : std_logic := '0';

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

    update_off_bias_gen : process
    begin
        wait for ACQUISITION_START + ACQUISITION_END + 100 us;
        update_off <= '1';
        wait for 300 ns;
        update_off <= '0';
        wait for SIM_DURATION;
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
            row_num         => row_num
        );

    row_activator_module : entity concept.row_activator
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,

            new_row             => new_row,
            row_num             => row_num,
            acquisition_on      => acquisition_on,
            on_bias             => on_bias,
            off_bias            => off_bias,
            num_rows            => num_rows,
            update_off          => update_off,
            DAC_start_pulse     => open,
            DAC_sel             => open,
            DAC_data            => open
        );

end behave;

