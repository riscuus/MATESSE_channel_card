----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 04.28.2022
-- Module Name: test_uart.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Top module to be able to test the correct functionality of the uart communication. The idea is to be
--              able to send custom packets (parameters defined through VIO). Also it should be able to receive packets
--              sent by a custom script running on windows which is connected to the serial port.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library concept;
use concept.utils.all;


entity test_uart is
    port ( 
        sys_clk              : in std_logic;
        sys_rst              : in std_logic;

        --send                 : in std_logic;
        uart_tx              : out std_logic;
        uart_rx              : in std_logic
    );

end test_uart;

architecture Behavioral of test_uart is

-- Packet builder controller <-> packet builder
signal builder_ready    : std_logic := '0';
signal packet_type      : t_packet_type := undefined;
signal cmd_type         : t_packet_type := undefined;
signal packet_payload   : t_packet_payload := (others => (others => '0'));
signal payload_size     : natural := 0;
signal params_valid     : std_logic := '0';

-- Packet builder <-> uart tx

signal send_byte        : std_logic := '0';
signal byte_data_tx     : t_byte := (others => '0');
signal tx_busy          : std_logic := '0';

-- uart tx <-> uart rx
signal uart_serial : std_logic := '0';

-- uart rx <-> Packet parser
signal rx_busy          : std_logic := '0';
signal byte_data_rx     : t_byte := (others => '0');

signal packet_type_rx      : t_packet_type := undefined;
signal card_id_rx          : t_half_word := (others => '0');
signal param_id_rx         : t_half_word := (others => '0');
signal cmd_type_rx         : t_packet_type := undefined;
signal err_ok_rx           : std_logic := '0';
signal payload_size_rx     : natural := 0;
signal packet_payload_rx   : t_packet_payload := (others => (others => '0'));
signal params_valid_rx     : std_logic := '0';

-- Signals to keep for debugging
attribute keep : string;
attribute keep of packet_type_rx       : signal is "true";
attribute keep of card_id_rx           : signal is "true";
attribute keep of param_id_rx          : signal is "true";
attribute keep of cmd_type_rx          : signal is "true"; 
attribute keep of err_ok_rx            : signal is "true"; 
attribute keep of payload_size_rx      : signal is "true";
attribute keep of packet_payload_rx    : signal is "true";
attribute keep of params_valid         : signal is "true";
attribute keep of params_valid_rx      : signal is "true";

-- VIO signals
signal packet_type_sel  : std_logic_vector(2 downto 0) := "000";
signal cmd_type_sel     : std_logic_vector(2 downto 0) := (others => '0');
signal payload_sel      : std_logic_vector(2 downto 0) := (others => '0');
signal card_id          : std_logic_vector(15 downto 0) := (others => '0');
signal param_id         : std_logic_vector(15 downto 0) := (others => '0');
signal err_ok           : std_logic := '0';
signal send             : std_logic := '0';

-- VIO Component
component vio_test_uart
  port (
    clk : in std_logic;
    probe_out0 : out std_logic_vector(2 downto 0);
    probe_out1 : out std_logic_vector(2 downto 0);
    probe_out2 : out std_logic_vector(2 downto 0);
    probe_out3 : out std_logic_vector(15 downto 0);
    probe_out4 : out std_logic_vector(15 downto 0);
    probe_out5 : out std_logic_vector(0 downto 0);
    probe_out6 : out std_logic_vector(0 downto 0)
  );
end component;

begin
    uart_tx <= uart_serial;

    packet_builder_controller : entity concept.packet_builder_controller
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,

            packet_type_sel     => packet_type_sel,
            cmd_type_sel        => cmd_type_sel,
            payload_sel         => payload_sel,

            send                => send,
            builder_ready       => builder_ready,

            packet_type         => packet_type,
            cmd_type            => cmd_type,
            packet_payload      => packet_payload,
            payload_size        => payload_size,
            params_valid        => params_valid
        );

    packet_builder_module : entity concept.packet_builder
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

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
            byte_data       => byte_data_tx,
            builder_ready   => builder_ready
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
            rx           => uart_rx,
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

            packet_type     => packet_type_rx,
            card_id         => card_id_rx,
            param_id        => param_id_rx,
            cmd_type        => cmd_type_rx,
            err_ok          => err_ok_rx,
            payload_size    => payload_size_rx,
            packet_payload  => packet_payload_rx,

            rx_busy         => rx_busy,
            byte_data       => byte_data_rx,
            params_valid    => params_valid_rx
        );


    vio : vio_test_uart
        port map(
            clk             => sys_clk,
            probe_out0      => packet_type_sel,
            probe_out1      => cmd_type_sel,
            probe_out2      => payload_sel,
            probe_out3      => card_id,
            probe_out4      => param_id,
            probe_out5(0)   => err_ok,
            probe_out6(0)   => send
        );

end Behavioral;
