----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 04/27/2022
-- Module Name: tb_packet_chain.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench for testing the chain composed by the packet_builder -> UART_TX -> UART_RX -> packet_parser 
--              components 

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

entity tb_packet_chain is
end tb_packet_chain;

architecture Behavioral of tb_packet_chain is

    -- Constants
    constant T_HALF_CLK         : time := 5 ns;
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 100 ns;
    constant SIM_DURATION       : time := 200 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    ----- Packet builder input parameters -----
    -- Param packet_type
    signal packet_type : t_packet_type := cmd_wb;

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

    signal params_valid     : std_logic := '1';
    signal byte_data_tx     : t_byte := (others => '0');


    -- Builder -> uart_tx
    signal send_byte    : std_logic;
    signal tx_busy      : std_logic;

    -- uart_tx -> uart_rx
    signal uart_serial : std_logic := '0';

    -- uart_rx -> Parser
    signal rx_busy          : std_logic := '0';
    signal byte_data_rx     : t_byte := (others => '0');

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
            tx_busy         => tx_busy,
            send_byte       => send_byte,
            byte_data       => byte_data_tx
        );

    uart_tx_module : entity concept.uart_controller
        port map(
            clk          => sys_clk,
            rst          => sys_rst,

            tx_ena       => send_byte,
            tx_data      => byte_data_tx,
            rx           => '0',
            rx_busy      => open,
            rx_error     => open,
            rx_data      => open,
            tx_busy      => tx_busy,
            tx           => uart_serial
        );

    uart_rx_module : entity concept.uart_controller
        port map(
            clk          => sys_clk,
            rst          => sys_rst,

            tx_ena       => '0',
            tx_data      => (others => '0'),
            rx           => uart_serial,
            rx_busy      => rx_busy,
            rx_error     => open,
            rx_data      => byte_data_rx,
            tx_busy      => open,
            tx           => open
        );
    
    packet_parser_module : entity concept.packet_parser
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            packet_type     => open,
            card_id         => open,
            param_id        => open,
            cmd_type        => open,
            err_ok          => open,
            payload_size    => open,
            packet_payload  => open,

            rx_busy         => rx_busy,
            byte_data       => byte_data_rx,
            params_valid    => open
        );

end Behavioral;
