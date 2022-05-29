----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.22.2022
-- Module Name: packet_sender.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This module just acts as an intermediate module between the packet_builder and the modules that need
--              to send packets (command_handler -> replies, frame_builder -> data packets). 

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

entity packet_sender is
    port(
        clk                         : in std_logic; -- 5MHz clock                                                                           
        rst                         : in std_logic; -- Asynchronous reset

        -- Interface with command handler
        send_reply_pulse            : in std_logic; -- Pulse to send a new reply packet
        reply_param_id              : in natural; -- The param id
        reply_cmd_type              : in t_packet_type; -- The cmd type
        reply_err_ok                : in std_logic; -- If err = 1 else 0
        reply_payload_size          : in natural; -- The size of the payload (in # of words)
        reply_payload               : in t_packet_payload; -- The reply packet payload data

        -- Interface with frame builder
        send_data_frame_pulse       : in std_logic; -- Pulse to send a new data packet
        data_frame_payload_size     : in natural; -- The size of the data packet payload (in # of words)
        data_frame_payload          : in t_packet_payload; -- The payload of the data packet

        -- Interface with packet builder
        builder_ready               : in std_logic; -- Signal comming from packet builder, indicates that a new packet can be sent
        packet_type                 : out t_packet_type; -- The packet type 
        card_id                     : out t_half_word; -- This card id, only used in reply packets
        param_id                    : out t_half_word; -- Used in reply packets
        cmd_type                    : out t_packet_type; -- Used in reply packets
        err_ok                      : out std_logic; -- Used in reply packets
        payload_size                : out natural; -- Size of the payload data (n in MCE)
        packet_payload              : out t_packet_payload; -- The payload of the packet
        params_valid                : out std_logic; -- Indicates that the output data is already valid and that the packet can be sent

        ready                       : out std_logic -- Cmd handler and frame builder are informed that a new packet can be sent
    );

end packet_sender;

architecture behave of packet_sender is
    type stateType is (idle, send_data_packet, send_reply_packet, wait_packet_builder_busy, wait_packet_builder_ready);
    signal state : stateType;


begin

    main_process : process(clk, rst)
    begin
        if (rst = '1') then
            state <= idle;
        elsif (rising_edge(clk)) then
            case state is
                when idle =>
                    packet_type     <= undefined;
                    card_id         <= (others => '0');
                    param_id        <= (others => '0');
                    cmd_type        <= undefined;
                    err_ok          <= '0';
                    payload_size    <= 0;
                    packet_payload  <= (others => (others => '0'));
                    params_valid    <= '0';

                    ready           <= '1';

                    -- Command handler and frame builder will not collide when sending packets, but in case we give priority to the data packets
                    if (send_data_frame_pulse = '1') then
                        state <= send_data_packet;
                    elsif (send_reply_pulse = '1') then
                        state <= send_reply_packet;
                    else
                        state <= state;
                    end if;

                when send_data_packet =>
                    -- Set corresponding data
                    packet_type <= data;
                    payload_size <= data_frame_payload_size;
                    packet_payload <= data_frame_payload;

                    state <= wait_packet_builder_ready;
                
                when send_reply_packet =>
                    -- Set corresponding data
                    packet_type <= reply;
                    card_id <= DAUGHTER_CARD_ID;
                    param_id <= std_logic_vector(to_unsigned(reply_param_id, param_id'length));
                    cmd_type <= reply_cmd_type;
                    err_ok <= reply_err_ok;
                    payload_size <= reply_payload_size;
                    packet_payload <= reply_payload;
                    params_valid <= '1';

                    state <= wait_packet_builder_ready;

                when wait_packet_builder_busy =>
                    if (builder_ready = '0') then
                        state <= wait_packet_builder_ready;
                    else
                        state <= state;
                    end if;
                
                when wait_packet_builder_ready =>
                    if (builder_ready = '1') then
                        state <= idle;
                    else
                        state <= state;
                    end if;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;
end behave;