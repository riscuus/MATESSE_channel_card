----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/24/2022
-- Module Name: tb_cmd_handler.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench for testing the cmd_handler component. In charge of receiving a new packet and take the
--              corresponding action. Either :
--              - Write and update a param
--              - Read a param
--              - Start the acquisition
--              - Stop the acquisition
--              - Reset (not implemented yet)
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

library concept;
use concept.utils.all;

entity tb_cmd_handler is
end tb_cmd_handler;

architecture Behavioral of tb_cmd_handler is

    -- Constants
    constant T_HALF_CLK         : time := 5 ns;
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 100 ns;
    constant PARAMS_VALID_START : time := 300 ns; 
    constant DATA_SETUP         : time := 50 ns;
    constant PARAMS_VALID_HIGH  : time := 22 ns;
    constant PACKET_DELAY       : time := 202 ns; -- Time between trying a new packet
    constant SIM_DURATION       : time := 200 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- PC packet parameters
    --signal packet_type : t_packet_type := cmd_wb;
    --signal card_id : t_half_word := "1111111100000000";
    --signal param_id : t_half_word := "0000000011111111";
    --signal cmd_type : t_packet_type := cmd_rb;
    --signal err_ok : std_logic := '0';
    --signal payload_size : natural := 2;
    --signal packet_payload : t_packet_payload := (0 => "10101010101010101010101010101010", 
    --                                             1 => "11111111111111111111111111111111", 
    --                                             others => (others => '0'));

    --signal params_valid     : std_logic := '1';


    -- Builder PC -> uart_tx PC
    --signal byte_data_tx     : t_byte := (others => '0');
    --signal send_byte    : std_logic;
    --signal tx_busy      : std_logic;

    -- uart_tx PC -> uart_rx
    --signal uart_serial : std_logic := '0';

    -- uart_rx -> Parser
    --signal rx_busy          : std_logic := '0';
    --signal byte_data_rx     : t_byte := (others => '0');

    -- Parser -> cmd_handler
    signal parser_packet_type       : t_packet_type := cmd_wb;
    signal parser_card_id           : t_half_word := DAUGHTER_CARD_ID;
    signal parser_param_id          : t_half_word := "0000000011111111";
    signal parser_cmd_type          : t_packet_type := undefined;
    signal parser_err_ok            : std_logic := '0';
    signal parser_payload_size      : natural := 0;
    signal parser_packet_payload    : t_packet_payload := (others => (others => '0'));

    signal parser_params_valid      : std_logic := '0';

    -- command_handler -> RAM
    signal ram_read_data            : t_word := (others => '0');
    signal ram_write_data           : t_word := (others => '0');
    signal ram_address              : natural := 0;
    signal ram_write                : std_logic;

    -- command_handler -> packer_sender
    signal packet_sender_ready      : std_logic := '0';
    signal send_reply_pulse         : std_logic := '0';
    signal reply_cmd_type           : t_packet_type := undefined;
    signal reply_err_ok             : std_logic := '0';
    signal reply_payload_size       : natural := 0;
    signal param_data               : t_packet_payload := (others => (others => '0'));

    -- command_handler -> param_buffers
    signal update_param_pulse       : std_logic := '0';
    signal param_id_address         : natural := 0;

    -- frame_builder -> command_handler 
    signal last_data_frame_pulse    : std_logic := '0';


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


    -- Test cases
    packet_params_generation : process
    begin
        -- Wait for rst
        wait for RST_START + RST_PULSE_LENGTH + 100 ns;

        -- #1: wrong card_id
        parser_packet_type      <= cmd_wb;
        parser_card_id          <= x"0f0f"; -- wrong
        parser_param_id         <= x"00ff";
        parser_payload_size     <= 0;
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';

        wait for PACKET_DELAY; 

        -- #2: wrong packet_type
        parser_packet_type      <= reply; -- wrong
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"00ff";
        parser_payload_size     <= 0;
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #3: wrong param_id
        parser_packet_type      <= cmd_wb;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"00ff"; -- wrong
        parser_payload_size     <= 0;
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #4: Wrong payload size
        parser_packet_type      <= cmd_wb;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0002";
        parser_payload_size     <= 0; -- Wrong
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #5: Good write
        parser_packet_type      <= cmd_wb;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0002";
        parser_payload_size     <= 8; 
        parser_packet_payload   <= (0 => x"0f0f0f00", 
                                    1 => x"0f0f0f01",
                                    2 => x"0f0f0f02",
                                    3 => x"0f0f0f03",
                                    4 => x"0f0f0f04",
                                    5 => x"0f0f0f05",
                                    6 => x"0f0f0f06",
                                    7 => x"0f0f0f07",
                                    others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #6: Good read
        parser_packet_type      <= cmd_rb;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0002";
        parser_payload_size     <= 1; 
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #7: Wrong start acquisition (Wrong parameter)
        parser_packet_type      <= cmd_go;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0002";
        parser_payload_size     <= 1; 
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #8: Wrong start acquisition (Good address but no previous setup)
        parser_packet_type      <= cmd_go;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0016";
        parser_payload_size     <= 1; 
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #9: Wrong stop acquisition (acquisition_on = '0')
        parser_packet_type      <= cmd_st;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0016";
        parser_payload_size     <= 1; 
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #10: Set acquisition config 
        parser_packet_type      <= cmd_wb;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0053";
        parser_payload_size     <= 2; 
        parser_packet_payload   <= (0 => x"0f0f0f00", 
                                    1 => x"0f0f0f01",
                                    others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #11: Good start acquisition
        parser_packet_type      <= cmd_go;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0016";
        parser_payload_size     <= 1; 
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #12: Good write but has to be ignored because acquisition is on
        parser_packet_type      <= cmd_wb;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0002";
        parser_payload_size     <= 8; 
        parser_packet_payload   <= (0 => x"0f0f0f00", 
                                    1 => x"0f0f0f01",
                                    2 => x"0f0f0f02",
                                    3 => x"0f0f0f03",
                                    4 => x"0f0f0f04",
                                    5 => x"0f0f0f05",
                                    6 => x"0f0f0f06",
                                    7 => x"0f0f0f07",
                                    others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #13: Bad write but has to be ignored because acquisition is on (wrong param id)
        parser_packet_type      <= cmd_wb;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"00ff"; -- wrong
        parser_payload_size     <= 0;
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #14: Good stop
        parser_packet_type      <= cmd_st;
        parser_card_id          <= DAUGHTER_CARD_ID;
        parser_param_id         <= x"0016";
        parser_payload_size     <= 1; 
        parser_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        parser_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        parser_params_valid <= '0';
        wait for PACKET_DELAY;

        wait for 200 ns;
        last_data_frame_pulse <= '1';
        wait for 20 ns;
        last_data_frame_pulse <= '0';

        wait for PACKET_DELAY;

    end process;

    command_handler_module : entity concept.command_handler
        port map(
            clk                     => sys_clk,
            rst                     => sys_rst,

            -- Interface with the packet parser
            packet_type             => parser_packet_type,
            card_id                 => parser_card_id,
            param_id                => parser_param_id,
            payload_size            => parser_payload_size,
            packet_payload          => parser_packet_payload,
            params_valid            => parser_params_valid,

            -- Interface with the RAM
            ram_read_data           => ram_read_data,
            ram_write_data          => ram_write_data,
            ram_address             => ram_address,
            ram_write               => ram_write,

            -- Interface with the packet sender
            packet_sender_ready     => packet_sender_ready,
            send_reply_pulse        => send_reply_pulse,
            reply_cmd_type          => reply_cmd_type,
            reply_err_ok            => reply_err_ok,
            reply_payload_size      => reply_payload_size,
            param_data              => param_data,

            -- Interface with param buffers
            update_param_pulse      => open,
            param_id_address        => param_id_address,
            
            last_data_frame_pulse   => last_data_frame_pulse,
            acquisition_on          => open
        );


    packet_sender_module : entity concept.packet_sender
        port map(
            clk                    => sys_clk,
            rst                    => sys_rst,
                                
            -- Interface with command_handler
            send_reply_pulse       => send_reply_pulse,
            reply_param_id         => param_id_address,
            reply_cmd_type         => reply_cmd_type,
            reply_err_ok           => reply_err_ok,
            reply_payload_size     => reply_payload_size,
            reply_payload          => param_data,
                                
            -- Interface with frame_builder
            send_data_frame_pulse  => '0',
            data_frame_payload_size=> 0,
            data_frame_payload     => (others => (others => '0')),
                                
            -- Interface with packet_builder
            builder_ready          => '0',
            packet_type            => open,
            card_id                => open,
            param_id               => open,
            cmd_type               => open,
            err_ok                 => open,
            payload_size           => open,
            packet_payload         => open,
            params_valid           => open,

            ready                  => packet_sender_ready
        );

    bram_wrapper_module : entity concept.BRAM_single_wrapper
        port map(
            clk             => sys_clk,
            rst             => sys_rst,
                            
            address         => ram_address,
            write_data      => ram_write_data,
            write_pulse     => ram_write,
            read_data       => ram_read_data
        );

end Behavioral;
