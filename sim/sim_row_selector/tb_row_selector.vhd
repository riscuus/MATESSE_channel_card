----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/29/2022
-- Module Name: tb_row_selector.vhd
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
use ieee.numeric_std.all;

library concept;
use concept.utils.all;

entity tb_row_selector is
end tb_row_selector;

architecture behave of tb_row_selector is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant ACQUISITION_START  : time := 1050 ns; 
    constant ACQUISITION_END    : time := 530 us; 
    constant SYNC_FRAME_DLY     : time := 2 us;
    constant SIM_DURATION       : time := 100 ms;


    constant MAX_NUM_ROWS : natural := 12;
    constant MAX_ROW_LEN  : natural := 30;


    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    signal acquisition_on   : std_logic := '0';
    signal sync_frame       : std_logic := '0';
    signal num_rows         : unsigned(bits_req(MAX_NUM_ROWS) - 1 downto 0)  := to_unsigned(5, bits_req(MAX_NUM_ROWS));
    signal row_len          : unsigned(bits_req(MAX_ROW_LEN) - 1 downto 0)   := to_unsigned(20, bits_req(MAX_ROW_LEN));

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
        generic map(
            MAX_NUM_ROWS    => MAX_NUM_ROWS,
            MAX_ROW_LEN     => MAX_ROW_LEN
        )
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            sync_frame      => sync_frame,
            acquisition_on  => acquisition_on,
            num_rows        => num_rows,
            row_len         => row_len,
            new_row         => open,
            row_num         => open
        );

end behave;

