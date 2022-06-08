----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06/06/2022
-- Module Name: tb_channels_controller.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the channels_controller module
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

entity tb_channels_controller is
end tb_channels_controller;

architecture behave of tb_channels_controller is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant ACQUISITION_START  : time := 30 us;
    constant ACQUISITION_END    : time := ACQUISITION_START + 100 us; 
    constant ACQUISITION_DLY    : time := 20 us;
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
    signal num_rows         : natural   := 4;
    signal row_num          : natural   := 0;

    -- row_selector -> channels_controller
    signal new_row      : std_logic := '0';
    signal frame_active : std_logic := '0';

    -- command_handler -> channels_controller
    signal data_mode    : natural := 0;
    signal servo_mode   : natural := 0;
    signal fb_dly       : natural := 3;

    signal set_SF       : std_logic := '0';
    signal set_SB       : std_logic := '0';
    signal set_FF       : std_logic := '0';
    signal set_FB       : std_logic := '0';

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

    set_v_gen : process
    begin
        wait for RST_START + RST_PULSE_LENGTH + 2 us;
        -- SF
        set_SF <= '1';
        wait for 3 * T_HALF_CLK;
        set_SF <= '0';
        wait for 1 us;
        -- SB
        set_SB <= '1';
        wait for 3 * T_HALF_CLK;
        set_SB <= '0';
        wait for 1 us;
        -- FF
        set_FF <= '1';
        wait for 3 * T_HALF_CLK;
        set_FF <= '0';
        wait for 1 us;
        -- FB
        set_FB <= '1';
        wait for 3 * T_HALF_CLK;
        set_FB <= '0';
        wait for 1 us;

        wait for SIM_DURATION;
    end process;


    acquisition_on_gen : process
    begin
        wait for ACQUISITION_START;
        -- data_mode = error & servo_mode = constant
        data_mode   <= DATA_MODE_ERROR;
        servo_mode  <= SERVO_MODE_CONST;
        acquisition_on <= '1';
        wait for ACQUISITION_END;
        acquisition_on <= '0';
        wait for ACQUISITION_DLY;
        -- data_mode = FB & servo_mode = constant
        data_mode   <= DATA_MODE_FB;
        servo_mode  <= SERVO_MODE_CONST;
        acquisition_on <= '1';
        wait for ACQUISITION_END;
        acquisition_on <= '0';
        wait for ACQUISITION_DLY;
        -- data_mode = filtered_db & servo_mode = ramp
        data_mode   <= DATA_MODE_FILT_FB;
        servo_mode  <= SERVO_MODE_RAMP;
        acquisition_on <= '1';
        wait for ACQUISITION_END;
        acquisition_on <= '0';
        wait for ACQUISITION_DLY;
        -- data_mode = raw & servo_mode = pid
        data_mode   <= DATA_MODE_RAW;
        servo_mode  <= SERVO_MODE_PID;
        acquisition_on <= '1';
        wait for ACQUISITION_END;
        acquisition_on <= '0';
        wait for ACQUISITION_DLY;
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
            frame_active    => frame_active,
            row_num         => row_num
        );
    
    channels_controller_module : entity concept.channels_controller
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            data_mode       => data_mode,
            servo_mode      => servo_mode,
            fb_dly          => fb_dly,
                               
            new_row         => new_row,
            acquisition_on  => acquisition_on,
            frame_active    => frame_active,
            set_SF          => set_SF,
            set_SB          => set_SB,
            set_FF          => set_FF,
            set_FB          => set_FB,
                               
            DAC_start_pulse => open,
            DAC_address     => open,
            line_sel        => open,
            data_sel        => open
        );


end behave;
