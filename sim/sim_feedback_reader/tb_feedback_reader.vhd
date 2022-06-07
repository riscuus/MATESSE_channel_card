----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06/06/2022
-- Module Name: tb_feedback_reader.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the feedback_reader module
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

entity tb_feedback_reader is
end tb_feedback_reader;

architecture behave of tb_feedback_reader is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant ACQUISITION_START  : time := 30 us; 
    constant ACQUISITION_END    : time := ACQUISITION_START + 500 us; 
    constant SYNC_FRAME_DLY     : time := 2 us;
    constant DATA_DLY           : time := 2 us;
    constant SIM_DURATION       : time := 100 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- row_selector signals
    signal acquisition_on   : std_logic := '0';
    signal sync_frame       : std_logic := '0';
    signal row_len          : natural   := 20;
    
    -- row_selector -> feedback_reader
    signal num_rows     : natural   := 10;
    signal new_row      : std_logic := '0';
    signal row_num      : natural := 0;    

    -- feedback_reader <-> ram
    signal read_address : natural := 0;
    signal read_data    : t_word := (others => '0');
    
    -- ram signals
    signal write_address    : natural := 0;
    signal write_data       : t_word := (others => '0');
    signal write_pulse      : std_logic := '0';


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

    data_creation_gen : process
    begin
        wait for RST_START + RST_PULSE_LENGTH + 4 * T_HALF_CLK;
        write_data <= x"FFFFFFF0";
        write_address <= 0;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF1";
        write_address <= 1;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF2";
        write_address <= 2;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF3";
        write_address <= 3;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF4";
        write_address <= 4;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF5";
        write_address <= 5;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF6";
        write_address <= 6;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF7";
        write_address <= 7;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF8";
        write_address <= 8;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFFF9";
        write_address <= 9;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFF10";
        write_address <= 10;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFF11";
        write_address <= 11;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
        wait for DATA_DLY;
        write_data <= x"FFFFFF12";
        write_address <= 12;
        write_pulse <= '1';
        wait for 3 * T_HALF_CLK;
        write_pulse <= '0';
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
    
    feedback_reader_module : entity concept.feedback_reader
        port map(
        
            clk             => sys_clk,
            rst             => sys_rst,
            new_row         => new_row,
            row_num         => row_num,
            num_rows        => num_rows,
            read_address    => read_address,
            read_data       => read_data,
            sa_fb_data      => open
        );

    dual_bram_module : entity concept.BRAM_dual_wrapper
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            write_address   => write_address,
            write_data      => write_data,
            write_pulse     => write_pulse,
            read_address    => read_address,
            read_data       => read_data
        );

end behave;
