----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 04/25/2022
-- Module Name: tb_test_packet_builder.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench for testing the packet_builder component 

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

entity tb_packet_builder is
end tb_packet_builder;

architecture Behavioral of tb_packet_builder is

    -- Constants
    constant T_HALF_CLK         : time := 5 ns;
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 100 ns;
    constant SIM_DURATION       : time := 100 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- Param packet_type
    signal packet_type : t_packet_type := data;

    -- Param id
    signal card_id : t_half_word := "1111111100000000";
    signal param_id : t_half_word := "0000000011111111";

    -- Param err
    signal cmd_type : t_packet_type := cmd_rb;
    signal err_ok : std_logic := '0';

    -- Param payload
    signal payload_size : natural := 2;
    signal packet_payload : t_packet_payload := (0 => "10101010101010101010101010101010", 
                                                 1 => "11111111111111111111111111111111", 
                                                 others => (others => '0'));

    signal params_valid : std_logic := '1';
    signal TX_ready     : std_logic;
    signal send_byte    : std_logic;
    signal byte_data    : t_byte := (others => '0');

    -- UART line
    signal uart_serial : std_logic := '0';

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

    uart_tx_module : entity concept.UART_TX_CTRL
        port map(
            SEND        => send_byte,
            DATA        => byte_data,
            CLK         => sys_clk,
            READY       => TX_ready,
            UART_TX     => uart_serial
        );

    packet_builder_module : entity concept.packet_builder
        port map(
            clk         => sys_clk,
            rst         => sys_rst,

            packet_type     => packet_type,
            card_id         => card_id,
            param_id        => param_id,
            cmd_type        => cmd_type,
            err_ok          => err_ok,
            payload_size    => payload_size,
            packet_payload  => packet_payload,
                       
            params_valid    => params_valid,
            TX_ready        => TX_ready,
            send_byte       => send_byte,
            byte_data       => byte_data
        );

end Behavioral;
