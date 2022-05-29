----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 04.21.2022
-- Module Name: packet_builder.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of generating each of the bytes of the different packets in the communicationA
--              between the MATESSE board and the external PC. It is able to produce 3 different types of packets:
--              commands, replies and data packets.

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

entity packet_builder is
    port(
        clk                     : in std_logic; -- 100mhz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset
        
        packet_type             : in t_packet_type; -- 5 types of command + 1 reply + 1 data
        card_id                 : in t_half_word;
        param_id                : in t_half_word;
        cmd_type                : in t_packet_type; -- Only used in reply packets
        err_ok                  : in std_logic; -- 0 to indicate OK, 1 to indicate error. Only used in reply packets
        payload_size            : in natural; -- Indicates how many words are in the payload data. MCE "n" param
        packet_payload          : in t_packet_payload; -- Packet payload. Up to col_num x row_num + 43 header words

        params_valid            : in std_logic; -- Indicates that the params are already valid and that the 
                                                -- communication can start
        tx_busy                 : in std_logic; -- In order to know if the the TX is available
        send_byte               : out std_logic; -- Active high when byte data is valid
        byte_data               : out t_byte; -- Data that is sent to the UART_TX
        builder_ready           : out std_logic -- Signal that indicates that a new packet can be sent

    );

end packet_builder;


architecture behave of packet_builder is

    -- cmd_packet SM signals
    type cmd_stateType is (init, wait_packet_params, wait_preamble_sent, wait_param_packet_type_sent, 
                           wait_param_id_sent, wait_param_size_sent, wait_payload_sent, wait_checksum_sent);
    signal cmd_state : cmd_stateType;

    signal packet_type_cmd              : std_logic := '0';
    signal start_preamble_cmd           : std_logic := '0';
    signal start_param_packet_type_cmd  : std_logic := '0';
    signal start_param_id_cmd           : std_logic := '0';
    signal start_param_size_cmd         : std_logic := '0';
    signal start_payload_cmd            : std_logic := '0';
    signal start_checksum_cmd           : std_logic := '0';
    signal builder_ready_cmd            : std_logic := '0';

    -- reply_packet SM signals
    type reply_stateType is (init, wait_packet_params, wait_preamble_sent, wait_param_packet_type_sent, 
                             wait_param_size_sent, wait_param_err_sent, wait_param_id_sent, wait_payload_sent, 
                             wait_checksum_sent);
    signal reply_state : reply_stateType;

    signal start_preamble_reply             : std_logic := '0';
    signal start_param_packet_type_reply    : std_logic := '0';
    signal start_param_size_reply           : std_logic := '0';
    signal start_param_err_reply            : std_logic := '0';
    signal start_param_id_reply             : std_logic := '0';
    signal start_payload_reply              : std_logic := '0';
    signal start_checksum_reply             : std_logic := '0';
    signal builder_ready_reply              : std_logic := '0';

    -- data_packet SM signals
    type data_stateType is (init, wait_packet_params, wait_preamble_sent, wait_param_packet_type_sent, 
                            wait_param_size_sent, wait_payload_sent, wait_checksum_sent);
    signal data_state : data_stateType;

    signal start_preamble_data              : std_logic := '0';
    signal start_param_packet_type_data     : std_logic := '0';
    signal start_param_size_data            : std_logic := '0';
    signal start_payload_data               : std_logic := '0';
    signal start_checksum_data              : std_logic := '0';
    signal builder_ready_data               : std_logic := '0';


    -- Parameter "preamble" SM signals
    type preamble_stateType is (init, wait_start_preamble, set_preamble, wait_preamble_word_sent);
    signal preamble_state : preamble_stateType;

    signal preamble_word_buffer     : t_word := (others => '0');
    signal start_preamble           : std_logic := '0';
    signal preamble_count           : std_logic := '0';
    signal preamble_sent            : std_logic := '0';
    signal send_preamble_word       : std_logic := '0';

    -- Paramenter "packet type" SM signals
    type packet_type_stateType is (init, wait_start_packet_type, wait_packet_type_sent);
    signal packet_type_state : packet_type_stateType;

    signal packet_type_word_buffer      : t_word := (others => '0');
    signal start_param_packet_type      : std_logic := '0';
    signal param_packet_type_sent       : std_logic := '0';
    signal send_param_packet_type_word  : std_logic := '0';

    -- Parameter "id" SM signals
    type id_stateType is (init, wait_start_id, wait_id_sent);
    signal id_state : id_stateType;

    signal id_word_buffer       : t_word := (others => '0');
    signal start_param_id       : std_logic := '0';
    signal param_id_sent        : std_logic := '0';
    signal send_param_id_word   : std_logic := '0';

    -- Parameter "size" SM signals
    type size_stateType is (init, wait_start_size, wait_size_sent);
    signal size_state : size_stateType;

    signal size_word_buffer         : t_word := (others => '0');
    signal param_size_sent          : std_logic := '0';
    signal send_param_size_word     : std_logic := '0';

    -- Parameter "Error/OK" SM signals
    type err_stateType is (init, wait_start_err, wait_err_sent);
    signal err_state : err_stateType;

    signal err_word_buffer         : t_word := (others => '0');
    signal param_err_sent          : std_logic := '0';
    signal send_param_err_word     : std_logic := '0';

    -- Parameter "Payload" SM signals
    type payload_stateType is (init, wait_start_payload, set_payload_word, wait_payload_word_sent);
    signal payload_state : payload_stateType;

    signal payload_word_buffer      : t_word := (others => '0');
    signal payload_word_counter     : natural := 0;
    signal payload_sent             : std_logic := '0';
    signal send_payload_word        : std_logic := '0';
    signal start_payload            : std_logic := '0';

    -- Parameter "Checksum" SM signals
    type checksum_stateType is (init, wait_for_err_param, wait_for_id_param, wait_for_payload_param, 
                                wait_start_checksum, wait_checksum_sent);
    signal checksum_state : checksum_stateType;

    signal checksum_word_buffer         : t_word := (others => '0');
    signal checksum_sent                : std_logic := '0';
    signal send_param_checksum_word     : std_logic := '0';
    signal start_checksum               : std_logic := '0';

    -- Send word SM signals
    type word_stateType is (init, wait_send_word, set_byte, wait_tx_and_send_byte);
    signal word_state : word_stateType;

    signal word_buffer      : t_word := (others => '0');
    signal word_byte_count  : natural := 0;
    signal word_sent        : std_logic := '0';

begin

-- Builder ready output
builder_ready <= builder_ready_cmd and builder_ready_reply and builder_ready_data;

-- Command packet
packet_type_cmd <= '1' when packet_type = cmd_rb or
                            packet_type = cmd_wb or
                            packet_type = cmd_go or
                            packet_type = cmd_st or
                            packet_type = cmd_rs else
                   '0';

cmd_packet_logic : process(clk, rst)
begin
    if (rst = '1') then
        cmd_state <= init;
    elsif (rising_edge(clk)) then
        case cmd_state is
            when init =>
                start_preamble_cmd          <= '0';
                start_param_packet_type_cmd <= '0';
                start_param_id_cmd          <= '0';
                start_param_size_cmd        <= '0';
                start_payload_cmd           <= '0';
                start_checksum_cmd          <= '0';
                builder_ready_cmd           <= '0';

                cmd_state <= wait_packet_params;

            when wait_packet_params =>
                builder_ready_cmd <= '1';
                if (params_valid = '1') then
                    if (packet_type_cmd = '1') then
                        start_preamble_cmd <= '1';
                        cmd_state <= wait_preamble_sent;
                    else
                        cmd_state <= cmd_state;
                    end if;
                else
                    cmd_state <= cmd_state;
                end if;

            -- Preamble
            when wait_preamble_sent => 
                builder_ready_cmd <= '0';
                start_preamble_cmd <= '0';
                if (preamble_sent = '1') then
                    start_param_packet_type_cmd <= '1';
                    cmd_state <= wait_param_packet_type_sent;
                else 
                    cmd_state <= cmd_state;
                end if;

            -- Packet type
            when wait_param_packet_type_sent =>
                start_param_packet_type_cmd <= '0';
                if (param_packet_type_sent = '1') then
                    start_param_id_cmd <= '1';
                    cmd_state <= wait_param_id_sent;
                else
                    cmd_state <= cmd_state;
                end if;

            -- Card ID / Param ID
            when wait_param_id_sent =>
                start_param_id_cmd <= '0';
                if(param_id_sent = '1') then
                    start_param_size_cmd <= '1';
                    cmd_state <= wait_param_size_sent;
                else 
                    cmd_state <= cmd_state;
                end if;

            -- Data payload size
            when wait_param_size_sent =>
                start_param_size_cmd <= '0';
                if (param_size_sent = '1') then
                    start_payload_cmd <= '1';
                    cmd_state <= wait_payload_sent;
                else 
                    cmd_state <= cmd_state;
                end if;
            -- Payload data
            when wait_payload_sent =>
                start_payload_cmd <= '0';
                if (payload_sent = '1') then
                    start_checksum_cmd <= '1';
                    cmd_state <= wait_checksum_sent;
                else
                    cmd_state <= cmd_state;
                end if;
            -- Checksum
            when wait_checksum_sent =>
                start_checksum_cmd <= '0';
                if (checksum_sent = '1') then
                    cmd_state <= init;
                else
                    cmd_state <= cmd_state;
                end if;

            when others =>
                cmd_state <= init; -- We should never enter here
        end case;
    end if;
end process;

-- Reply packet
reply_packet_logic : process(clk, rst)
begin
    if (rst = '1') then
        reply_state <= init;

    elsif (rising_edge(clk)) then
        case reply_state is
            when init =>
                start_preamble_reply            <= '0';
                start_param_packet_type_reply   <= '0';
                start_param_size_reply          <= '0';
                start_param_err_reply           <= '0';
                start_param_id_reply            <= '0';
                start_payload_reply             <= '0';
                start_checksum_reply            <= '0';
                builder_ready_reply             <= '0';

                reply_state <= wait_packet_params;

            when wait_packet_params =>
                builder_ready_reply <= '1';
                if (params_valid = '1') then
                    if (packet_type = reply) then
                        start_preamble_reply <= '1';
                        reply_state <= wait_preamble_sent;
                    else
                        reply_state <= reply_state;
                    end if;
                else
                    reply_state <= reply_state;
                end if;

            -- Preamble
            when wait_preamble_sent => 
                builder_ready_reply <= '0';
                start_preamble_reply <= '0';
                if (preamble_sent = '1') then
                    start_param_packet_type_reply <= '1';
                    reply_state <= wait_param_packet_type_sent;
                else 
                    reply_state <= reply_state;
                end if;

            -- Packet type
            when wait_param_packet_type_sent =>
                start_param_packet_type_reply <= '0';
                if (param_packet_type_sent = '1') then
                    start_param_size_reply <= '1';
                    reply_state <= wait_param_size_sent;
                else
                    reply_state <= reply_state;
                end if;

            -- Packet size
            when wait_param_size_sent =>
                start_param_size_reply <= '0';
                if (param_size_sent = '1') then
                    start_param_err_reply <= '1';
                    reply_state <= wait_param_err_sent;
                else 
                    reply_state <= reply_state;
                end if;
            
            -- Error/OK
            when wait_param_err_sent =>
                start_param_err_reply <= '0';
                if (param_err_sent = '1') then
                    start_param_id_reply <= '1';
                    reply_state <= wait_param_id_sent;
                else
                    reply_state <= reply_state;
                end if;

            -- Card ID / Param ID
            when wait_param_id_sent =>
                start_param_id_reply <= '0';
                if(param_id_sent = '1') then
                    start_payload_reply <= '1';
                    reply_state <= wait_payload_sent;
                else 
                    reply_state <= reply_state;
                end if;

            -- Data payload
            when wait_payload_sent =>
                start_payload_reply <= '0';
                if (payload_sent = '1') then
                    start_checksum_reply <= '1';
                    reply_state <= wait_checksum_sent;
                else
                    reply_state <= reply_state;
                end if;

            -- Checksum
            when wait_checksum_sent =>
                start_checksum_reply <= '0';
                if (checksum_sent = '1') then
                    reply_state <= init;
                else
                    reply_state <= reply_state;
                end if;

            when others =>
                reply_state <= init; -- We should never enter here
        end case;
    end if;
end process;

-- Data packet
data_packet_logic : process(clk, rst)
begin
    if (rst = '1') then
        data_state <= init;

    elsif (rising_edge(clk)) then
        case data_state is
            when init =>
                start_preamble_data             <= '0';
                start_param_packet_type_data    <= '0';
                start_param_size_data           <= '0';
                start_payload_data              <= '0';
                start_checksum_data             <= '0';
                builder_ready_data              <= '0';

                data_state <= wait_packet_params;

            when wait_packet_params =>
                builder_ready_data <= '1';
                if (params_valid = '1') then
                    if (packet_type = data) then
                        start_preamble_data <= '1';
                        data_state <= wait_preamble_sent;
                    else
                        data_state <= data_state;
                    end if;
                else
                    data_state <= data_state;
                end if;

            -- Preamble
            when wait_preamble_sent => 
                builder_ready_data <= '0';
                start_preamble_data <= '0';
                if (preamble_sent = '1') then
                    start_param_packet_type_data <= '1';
                    data_state <= wait_param_packet_type_sent;
                else 
                    data_state <= data_state;
                end if;

            -- Packet type
            when wait_param_packet_type_sent =>
                start_param_packet_type_data <= '0';
                if (param_packet_type_sent = '1') then
                    start_param_size_data <= '1';
                    data_state <= wait_param_size_sent;
                else
                    data_state <= data_state;
                end if;

            -- Packet size
            when wait_param_size_sent =>
                start_param_size_data <= '0';
                if (param_size_sent = '1') then
                    start_payload_data <= '1';
                    data_state <= wait_payload_sent;
                else 
                    data_state <= data_state;
                end if;
            
            -- Data payload
            when wait_payload_sent =>
                start_payload_data <= '0';
                if (payload_sent = '1') then
                    start_checksum_data <= '1';
                    data_state <= wait_checksum_sent;
                else
                    data_state <= data_state;
                end if;

            -- Checksum
            when wait_checksum_sent =>
                start_checksum_data <= '0';
                if (checksum_sent = '1') then
                    data_state <= init;
                else
                    data_state <= data_state;
                end if;

            when others =>
                data_state <= init; -- We should never enter here
        end case;
    end if;
end process;


-- Parameter preamble
start_preamble <= start_preamble_cmd or start_preamble_reply or start_preamble_data;

send_preamble_logic : process(clk, rst)
begin
    if (rst = '1') then
        preamble_state <= init;

    elsif (rising_edge(clk)) then
        case preamble_state is
            when init =>
                preamble_count          <= '0';
                preamble_sent           <= '0';
                send_preamble_word      <= '0';
                preamble_word_buffer    <= (others => '0');

                preamble_state <= wait_start_preamble;

            when wait_start_preamble =>
                if (start_preamble = '1') then 
                    preamble_state <= set_preamble;
                else 
                    preamble_state <= preamble_state;
                end if;

            when set_preamble =>
                if (preamble_count = '0') then
                    preamble_word_buffer <= PREAMBLE_1;
                else
                    preamble_word_buffer <= PREAMBLE_2;
                end if;

                send_preamble_word <= '1';
                preamble_state <= wait_preamble_word_sent;

            when wait_preamble_word_sent =>
                send_preamble_word <= '0';
                if (word_sent = '1') then
                    if(preamble_count = '0') then
                        preamble_count <= '1';
                        preamble_state <= set_preamble;
                    else
                        preamble_sent <= '1';
                        preamble_state <= init;
                    end if;
                else 
                    preamble_state <= preamble_state;
                end if;

            when others =>
                preamble_state <= init;
        end case;
    end if;
end process;


-- Parameter packet type
start_param_packet_type <= start_param_packet_type_cmd or start_param_packet_type_reply or start_param_packet_type_data;

send_packet_type_logic : process(clk, rst)
begin
    if (rst = '1') then
        packet_type_state <= init;

    elsif (rising_edge(clk)) then
        case packet_type_state is
            when init =>
                packet_type_word_buffer     <= (others => '0');
                send_param_packet_type_word <= '0';
                param_packet_type_sent            <= '0';

                packet_type_state <= wait_start_packet_type;

            when wait_start_packet_type =>
                if (start_param_packet_type = '1') then
                    case packet_type is
                        when cmd_rb =>
                            packet_type_word_buffer <= CMD_RB_TYPE;
                        when cmd_wb =>
                            packet_type_word_buffer <= CMD_WB_TYPE;
                        when cmd_go =>
                            packet_type_word_buffer <= CMD_GO_TYPE;
                        when cmd_st =>
                            packet_type_word_buffer <= CMD_ST_TYPE;
                        when cmd_rs =>
                            packet_type_word_buffer <= CMD_RS_TYPE;
                        when reply =>
                            packet_type_word_buffer <= REPLY_TYPE;
                        when data =>
                            packet_type_word_buffer <= DATA_TYPE;
                        when others =>
                            packet_type_state <= init;
                    end case;

                    send_param_packet_type_word <= '1';

                    packet_type_state <= wait_packet_type_sent;
                else
                    packet_type_state <= packet_type_state;
                end if;

            when wait_packet_type_sent =>
                send_param_packet_type_word <= '0';
                if (word_sent = '1') then 
                        param_packet_type_sent <= '1';
                        packet_type_state <= init;
                else
                    packet_type_state <= packet_type_state;
                end if;
                
            when others =>
                packet_type_state <= init;
        end case;
    end if;
end process;

-- Parameter ID
start_param_id <= start_param_id_cmd or start_param_id_reply;

send_id_logic : process(clk, rst)
begin
    if (rst = '1') then
        id_state <= init;

    elsif (rising_edge(clk)) then
        case id_state is
            when init =>
                id_word_buffer      <= (others => '0');
                send_param_id_word  <= '0';
                param_id_sent       <= '0';

                id_state <= wait_start_id;

            when wait_start_id =>
                if (start_param_id = '1') then
                    id_word_buffer(15 downto 0) <= param_id;
                    id_word_buffer(31 downto 16) <= card_id;
                    send_param_id_word <= '1';

                    id_state <= wait_id_sent;
                else
                    id_state <= id_state;
                end if;

            when wait_id_sent =>
                send_param_id_word <= '0';
                if (word_sent = '1') then 
                        param_id_sent <= '1';
                        id_state <= init;
                else
                    id_state <= id_state;
                end if;
                
            when others =>
                id_state <= init;
        end case;
    end if;
end process;

-- Parameter size
send_size_logic : process(clk, rst)
begin
    if (rst = '1') then
        size_state <= init;

    elsif (rising_edge(clk)) then
        case size_state is
            when init =>
                size_word_buffer        <= (others => '0');
                send_param_size_word    <= '0';
                param_size_sent         <= '0';

                size_state <= wait_start_size;

            when wait_start_size =>
                if(start_param_size_cmd = '1') then
                    -- When cmd packet we simply send the payload size "n"
                    size_word_buffer <= std_logic_vector(to_unsigned(payload_size, 32));
                    send_param_size_word <= '1';
                    size_state <= wait_size_sent;
                elsif (start_param_size_reply = '1') then
                    -- When reply packet we send the "packet size" instead of the payload size. This is the payload
                    -- plus 3 words
                    size_word_buffer <= std_logic_vector(to_unsigned(payload_size + 3, 32));
                    send_param_size_word <= '1';
                    size_state <= wait_size_sent;
                elsif (start_param_size_data = '1') then
                    -- When data packet we send the "packet size" instead of the payload size. This is the payload
                    -- plus 1 word
                    size_word_buffer <= std_logic_vector(to_unsigned(payload_size + 1, 32));
                    send_param_size_word <= '1';
                    size_state <= wait_size_sent;
                else
                    size_state <= size_state;
                end if;

            when wait_size_sent =>
                send_param_size_word <= '0';
                if (word_sent = '1') then 
                        param_size_sent <= '1';
                        size_state <= init;
                else
                    size_state <= size_state;
                end if;
                
            when others =>
                size_state <= init;
        end case;
    end if;
end process;

-- Parameter Error/OK
send_err_logic : process(clk, rst)
begin
    if (rst = '1') then
        err_state <= init;

    elsif (rising_edge(clk)) then
        case err_state is
            when init =>
                err_word_buffer         <= (others => '0');
                send_param_err_word     <= '0';
                param_err_sent          <= '0';

                err_state <= wait_start_err;

            when wait_start_err =>
                if (start_param_err_reply = '1') then
                    case cmd_type is
                        when cmd_rb =>
                            err_word_buffer(31 downto 16) <= RB_ASCII;
                        when cmd_wb =>
                            err_word_buffer(31 downto 16) <= WB_ASCII;
                        when cmd_go =>
                            err_word_buffer(31 downto 16) <= GO_ASCII;
                        when cmd_st =>
                            err_word_buffer(31 downto 16) <= ST_ASCII;
                        when cmd_rs =>
                            err_word_buffer(31 downto 16) <= RS_ASCII;
                        when others => -- We should never reach this point. Possible improvement: trigger error signal
                    end case;

                    if (err_ok = '1') then
                        err_word_buffer(15 downto 0) <= ER_ASCII; 
                    else
                        err_word_buffer(15 downto 0) <= OK_ASCII;
                    end if;

                    send_param_err_word <= '1';

                    err_state <= wait_err_sent;
                else
                    err_state <= err_state;
                end if;

            when wait_err_sent =>
                send_param_err_word <= '0';
                if (word_sent = '1') then 
                        param_err_sent <= '1';
                        err_state <= init;
                else
                    err_state <= err_state;
                end if;
                
            when others =>
                err_state <= init;
        end case;
    end if;
end process;

-- Parameter Payload
start_payload <= start_payload_cmd or start_payload_reply or start_payload_data;

send_payload_logic : process(clk, rst)
begin
    if (rst = '1') then
        payload_state <= init;

    elsif (rising_edge(clk)) then
        case payload_state is
            when init =>
                payload_word_buffer     <= (others => '0');
                payload_word_counter    <= 0;
                send_payload_word       <= '0';
                payload_sent            <= '0';

                payload_state <= wait_start_payload;

            when wait_start_payload =>
                if (start_payload = '1') then
                    payload_state <= set_payload_word;
                else
                    payload_state <= payload_state;
                end if;

            when set_payload_word =>
                payload_word_buffer <= packet_payload(payload_word_counter);
                send_payload_word <= '1';
                payload_state <= wait_payload_word_sent;

            when wait_payload_word_sent =>
                send_payload_word <= '0';
                if (word_sent = '1') then 
                    if(packet_type = reply or packet_type = data) then
                        -- For reply and data packets payload size is variable
                        if (payload_word_counter = payload_size - 1) then
                            payload_sent <= '1';
                            payload_state <= init;
                        else
                            payload_word_counter <= payload_word_counter + 1;
                            payload_state <= set_payload_word;
                        end if;
                    else
                        -- For cmd packets the payload size is fixed
                        if (payload_word_counter = CMD_REPLY_MAX_SIZE - 1) then
                            payload_sent <= '1';
                            payload_state <= init;
                        else
                            payload_word_counter <= payload_word_counter + 1;
                            payload_state <= set_payload_word;
                        end if;
                    end if;
                else
                    payload_state <= payload_state;
                end if;
                
            when others =>
                payload_state <= init;
        end case;
    end if;
end process;

-- Parameter checksum
start_checksum <= start_checksum_cmd or start_checksum_reply or start_checksum_data;

send_checksum_logic : process(clk, rst)
begin
    if (rst = '1') then
        checksum_state <= init;

    elsif (rising_edge(clk)) then
        case checksum_state is
            when init =>
                checksum_word_buffer      <= (others => '0');
                send_param_checksum_word <= '0';
                checksum_sent <= '0';
                
                if (packet_type = cmd_rb or packet_type = cmd_wb or
                    packet_type = cmd_go or packet_type = cmd_st or
                    packet_type = cmd_rs or packet_type = data) then

                    checksum_state <= wait_for_payload_param;

                elsif (packet_type = reply) then
                    checksum_state <= wait_for_err_param;
                else
                    checksum_state <= checksum_state;
                end if;
            
            when wait_for_err_param =>
                if (send_param_err_word = '1') then
                    checksum_word_buffer <= checksum_word_buffer xor err_word_buffer;
                    checksum_state <= wait_for_id_param;
                else
                    checksum_state <= checksum_state;
                end if;

            when wait_for_id_param =>
                if (send_param_id_word = '1') then
                    checksum_word_buffer <= checksum_word_buffer xor id_word_buffer;
                    checksum_state <= wait_for_payload_param;
                else
                    checksum_state <= checksum_state;
                end if;

            when wait_for_payload_param =>
                if (send_payload_word = '1') then
                    checksum_word_buffer <= checksum_word_buffer xor payload_word_buffer;
                    checksum_state <= wait_for_payload_param;
                elsif (payload_sent = '1') then
                    checksum_state <= wait_start_checksum;
                else
                    checksum_state <= checksum_state;
                end if;

            when wait_start_checksum =>
                if (start_checksum = '1') then
                    send_param_checksum_word <= '1';

                    checksum_state <= wait_checksum_sent;
                else
                    checksum_state <= checksum_state;
                end if;

            when wait_checksum_sent =>
                send_param_checksum_word <= '0';
                if (word_sent = '1') then 
                        checksum_sent <= '1';
                        checksum_state <= init;
                else
                    checksum_state <= checksum_state;
                end if;
                
            when others =>
                checksum_state <= init;
        end case;
    end if;
end process;

-- Send word
send_word_logic : process(clk, rst)
begin
    if (rst = '1') then
        word_state <= init;

    elsif (rising_edge(clk)) then
        case word_state is
            when init =>
                word_buffer <= (others => '0');
                word_byte_count <= 0;
                word_sent <= '0';
                send_byte <= '0';

                word_state <= wait_send_word;

            when wait_send_word =>
                if (send_preamble_word = '1') then 
                    word_buffer <= preamble_word_buffer;
                    word_state <= set_byte;
                elsif (send_param_packet_type_word = '1') then
                    word_buffer <= packet_type_word_buffer;
                    word_state <= set_byte;
                elsif (send_param_id_word = '1') then
                    word_buffer <= id_word_buffer;
                    word_state <= set_byte;
                elsif (send_param_size_word = '1') then
                    word_buffer <= size_word_buffer;
                    word_state <= set_byte;
                elsif (send_param_err_word = '1') then
                    word_buffer <= err_word_buffer;
                    word_state <= set_byte;
                elsif (send_payload_word = '1') then
                    word_buffer <= payload_word_buffer;
                    word_state <= set_byte;
                elsif (send_param_checksum_word = '1') then
                    word_buffer <= checksum_word_buffer;
                    word_state <= set_byte;
                else
                    word_state <= word_state;
                end if;

            when set_byte =>
                send_byte <= '0';
                byte_data <= word_buffer(((word_byte_count + 1) * 8 - 1) downto word_byte_count * 8);
                word_state <= wait_tx_and_send_byte;

            when wait_tx_and_send_byte =>
                if (tx_busy = '0') then
                    send_byte <= '1';
                    if(word_byte_count = 3) then
                        word_byte_count <= 0;
                        word_sent <= '1';
                        word_state <= init;
                    else
                        word_byte_count <= word_byte_count + 1;
                        word_state <= set_byte;
                    end if;
                else 
                    word_state <= word_state;
                end if;

            when others =>
                word_state <= init;
        end case;
    end if;
end process;

end behave;