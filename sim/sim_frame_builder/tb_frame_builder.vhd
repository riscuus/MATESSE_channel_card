----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06/09/2022
-- Module Name: tb_frame_builder.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the frame_builder module
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library concept;
use concept.utils.all;

entity tb_frame_builder is
end tb_frame_builder;

architecture behave of tb_frame_builder is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant ACQUISITION_START  : time := 10 us;
    constant ACQUISITION_END    : time := ACQUISITION_START + 100 us; 
    constant ACQUISITION_DLY    : time := 20 us;
    constant DATA_DLY           : time := 4 us;
    constant FRAME_ACTIVE_DLY   : time := 20 us;
    constant SIM_DURATION       : time := 100 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;


    -- Frame builder signals
    signal ret_data_setup   : t_param_array(0 to 1) := (0 => x"00000003", 1 => x"00000006"); -- 4 frames must be sent
    signal data_rate        : natural := 5; -- We send a frame every 5 internal frames
    signal num_rows         : natural := 5;
    signal num_cols         : natural := 1; -- num of channels reported
    signal row_len          : natural := 20;

    signal acquisition_on   : std_logic := '0';
    signal stop_received    : std_logic := '0';
    signal frame_active     : std_logic := '0';
                            
    signal channels_data    : t_channel_record_array := (
        0 => (
            value    => (others => '0'),
            row_num => 0,
            valid   => '0'
        ),
        1 => (
            value    => (others => '0'),
            row_num => 0,
            valid   => '0'
        )
    );

    signal sender_ready     : std_logic := '1'; -- Make it always ready


    -- Testbench signals
    signal data_counter : natural := 0;

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

    data_gen : process
    begin
        if (data_counter = 0) then
            wait for RST_START + RST_PULSE_LENGTH + 2 us;
        end if;

        channels_data(0).value  <= std_logic_vector(to_unsigned(data_counter, t_word'length));
        channels_data(0).row_num   <= data_counter;
        channels_data(0).valid <= '1';

        channels_data(1).value  <= std_logic_vector(to_unsigned(data_counter, t_word'length));
        channels_data(1).row_num   <= data_counter;
        channels_data(1).valid <= '1';

        wait for 2 * T_HALF_CLK;

        channels_data(0).valid <= '0';
        channels_data(1).valid <= '0';
        if (data_counter = num_rows - 1) then
            data_counter <= 0;
        else
            data_counter <= data_counter + 1;
        end if;

        wait for data_dly;
    end process;

    acquisition_gen : process
    begin
        wait for RST_START + RST_PULSE_LENGTH + 2 us;
        wait for ACQUISITION_START;
        acquisition_on <= '1';
        frame_active <= '1';
        wait for ACQUISITION_END;
        -- stop_received <= '1'; -- Test case for when stop is sent
        -- acquisition_on <= '0'; -- In theory it should stop when # frames already sent
        wait for FRAME_ACTIVE_DLY;
        -- frame_active <= 0; -- Test case for when stop is sent
        wait for SIM_DURATION;
    end process;

    stop_received_gen : process
    begin
        wait for 200 us;
        stop_received <= '1';
        wait for 2 * T_HALF_CLK;
        stop_received <= '0';
        wait for SIM_DURATION;
    end process;

    -- Module
    frame_builder_module : entity concept.frame_builder
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,

            ret_data_setup      => ret_data_setup,
            data_rate           => data_rate,
            num_rows            => num_rows,
            num_cols            => num_cols,
            row_len             => row_len,

            acquisition_on      => acquisition_on,
            stop_received       => stop_received,
            frame_active        => frame_active,
            last_frame_sent     => open,

            channels_data       => channels_data,

            sender_ready        => sender_ready,
            send_data_packet    => open,
            payload_size        => open,
            frame_payload       => open
        );

end behave;
