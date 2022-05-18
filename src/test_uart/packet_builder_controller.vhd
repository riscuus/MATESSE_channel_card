----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 04.28.2022
-- Module Name: packet_builder_controller.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module in charge of passing the corresponding data and signals to the packet builder to send a packet
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

entity packet_builder_controller is
    port(
        clk                 : in std_logic; -- 100mhz clock                                                                           
        rst                 : in std_logic; -- asynchronous reset
        
        packet_type_sel     : in std_logic_vector(2 downto 0); -- "000" = cmd_rb, "001" = cmd_wb, "010" = cmd_go, "011" = cmd_st, "100" = cmd_rs, "101" = reply, "110" = data
        cmd_type_sel        : in std_logic_vector(2 downto 0); -- "000" = cmd_rb, "001" = cmd_wb, "010" = cmd_go, "011" = cmd_st, "100" = cmd_rs
        payload_sel         : in std_logic_vector(2 downto 0); -- Indicates which of the 8 predefined payloads to send

        send                : in std_logic; -- Signal used to send a new packet. Packet will only be sent once the last
                                            -- has been sent. And the user can only send one at a time.
        builder_ready       : in std_logic; -- Signal that indicates that the builder is ready to send another packet

        packet_type         : out t_packet_type;
        cmd_type            : out t_packet_type;
        packet_payload      : out t_packet_payload; -- Data that is sent to the UART_TX
        payload_size        : out natural;
        params_valid        : out std_logic
    );

end packet_builder_controller;

architecture behave of packet_builder_controller is
    signal payload_size_0 : natural := 2;
    signal packet_payload_0 : t_packet_payload := (0 => "10101010101010101010101010101010", 
                                                   1 => "11111111111111111111111111111111", 
                                                   others => (others => '0'));

    signal payload_size_1 : natural := 3;
    signal packet_payload_1 : t_packet_payload := (0 => "11111111111111111111111111111111", 
                                                   1 => "11111111111111111111111111111111", 
                                                   2 => "11111111111111111111111111111111", 
                                                   others => (others => '0'));
    
    type stateType is (init, wait_builder_ready, wait_send_signal_low, wait_send_signal_high, set_params_valid);
    signal state : stateType;


    -- Signals to keep for debugging
    attribute keep : string;
    attribute keep of state       : signal is "true";


begin


with packet_type_sel select packet_type <=
    data    when "000",
    reply   when "001",
    cmd_rb  when "010",
    cmd_wb  when "011",
    cmd_go  when "100",
    cmd_st  when "101",
    cmd_rs  when "110",
    data    when others;

with cmd_type_sel select cmd_type <=
    cmd_rb  when "000",
    cmd_wb  when "001",
    cmd_go  when "010",
    cmd_st  when "011",
    cmd_rs  when "100",
    cmd_rb    when others;

with payload_sel select packet_payload <=
    packet_payload_0    when "000",
    packet_payload_1    when "001",
    packet_payload_0    when others;

with payload_sel select payload_size <=
    payload_size_0    when "000",
    payload_size_1    when "001",
    payload_size_0    when others;


main_logic : process(clk, rst)
begin
    if (rst = '1') then
        state <= init;
    elsif (rising_edge(clk)) then
        case state is
            when init =>
                state <= wait_builder_ready;

            when wait_builder_ready =>
                params_valid <= '0';
                if (builder_ready = '1') then
                    state <= wait_send_signal_low;
                else
                    state <= state;
                end if;

            when wait_send_signal_low =>
                if (send = '0') then
                    state <= wait_send_signal_high;
                else
                    state <= state;
                end if;
            
            when wait_send_signal_high =>
                if (send = '1') then
                    state <= set_params_valid;
                else 
                    state <= state;
                end if;
            
            when set_params_valid =>
                params_valid <= '1';
                state <= wait_builder_ready;

            when others =>
                state <= init;
            end case;
    end if;
end process;

end behave;