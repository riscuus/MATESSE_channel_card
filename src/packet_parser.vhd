----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 04.25.2022
-- Module Name: packet_parser.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of reading each of the bytes exported by the UART_RX_CTRL component and
--              Extract the necessary information from it

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

entity packet_parser is
    port(
        clk                     : in std_logic; -- 100mhz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        packet_type             : out t_packet_type; -- 5 types of command + 1 reply + 1 data
        card_id                 : out t_half_word; 
        param_id                : out t_half_word;
        cmd_type                : out t_packet_type; -- Only used in reply packets
        err_ok                  : out std_logic; -- 0 to indicate OK, 1 to indicate error. Only used in reply packets
        payload_size            : out unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0); -- Indicates how many words are in the payload data. MCE "n" param
        packet_payload          : out t_packet_payload; -- Packet payload. Up to col_num x row_num + 43 header words

        rx_busy                 : in std_logic; -- In order to know if the the TX is available
        byte_data               : in t_byte;
        params_valid            : out std_logic -- Indicates that the params are already valid and that they can be read
    );

end packet_parser;

architecture behave of packet_parser is

    -- General packet parser signals
    type packet_parser_stateType is (init, check_preamble, check_type);
    signal packet_parser_state : packet_parser_stateType;


    signal parse_preamble   : std_logic := '0';
    signal parse_type       : std_logic := '0';
    signal parse_cmd        : std_logic := '0';
    signal parse_reply      : std_logic := '0';
    signal parse_data       : std_logic := '0';

    -- Cmd packet parser
    type cmd_stateType is (init, wait_id, wait_size, wait_payload, wait_checksum);
    signal cmd_state : cmd_stateType;

    signal parse_id_cmd         : std_logic := '0';
    signal parse_size_cmd       : std_logic := '0';
    signal parse_payload_cmd    : std_logic := '0';
    signal parse_checksum_cmd   : std_logic := '0';
    signal params_valid_cmd     : std_logic := '0';

    -- Reply packet parser
    type reply_stateType is (init, wait_size, wait_err, wait_id, wait_payload, wait_checksum);
    signal reply_state : reply_stateType;

    signal parse_size_reply      : std_logic := '0';
    signal parse_err_reply       : std_logic := '0';
    signal parse_id_reply        : std_logic := '0';
    signal parse_payload_reply   : std_logic := '0';
    signal parse_checksum_reply  : std_logic := '0';
    signal params_valid_reply    : std_logic := '0';

    -- Data packet parser
    type data_stateType is (init, wait_size, wait_payload, wait_checksum);
    signal data_state : data_stateType;

    signal parse_size_data      : std_logic := '0';
    signal parse_payload_data   : std_logic := '0';
    signal parse_checksum_data  : std_logic := '0';
    signal params_valid_data    : std_logic := '0';

    -- Preamble parser signals
    type preamble_stateType is (init, check_preamble);
    signal preamble_state : preamble_stateType;

    signal good_preamble    : std_logic := '0';
    signal bad_preamble     : std_logic := '0';
    signal preamble_count   : std_logic := '0';

    -- Type parser
    type type_stateType is (init, check_type);
    signal type_state : type_stateType;

    signal packet_type_reg  : t_packet_type := undefined;
    signal bad_type         : std_logic := '0';
    signal good_type        : std_logic := '0';

    -- Id parser
    type id_stateType is (init, wait_word);
    signal id_state : id_stateType;

    signal parse_id     : std_logic := '0';
    signal id_received  : std_logic := '0';

    -- Size parser 
    type size_stateType is (init, wait_word);
    signal size_state : size_stateType;

    signal payload_size_reg     : unsigned(payload_size'range) := (others => '0'); -- Register used to set default values
    signal good_size            : std_logic := '0';
    signal bad_size             : std_logic := '0';
    signal parse_size           : std_logic := '0';

    -- Error/OK parser 
    type err_stateType is (init, wait_word);
    signal err_state : err_stateType;

    signal err_received    : std_logic := '0';
    signal parse_err       : std_logic := '0';

    -- Payload parser
    type payload_stateType is (init, wait_word);
    signal payload_state : payload_stateType;

    signal parse_payload        : std_logic := '0';
    signal payload_word_count   : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal payload_received     : std_logic := '0';
    signal packet_payload_reg   : t_packet_payload := (others => (others => '0')); -- Reg used to set default values

    -- Checksum parser
    type checksum_stateType is (init, wait_for_packet_type, wait_for_err_param, wait_for_id_param, 
                                wait_for_payload_param, wait_payload_word, wait_parse_checksum, wait_word);
    signal checksum_state : checksum_stateType;

    signal calculated_checksum  : t_word := (others => '0');
    signal good_checksum        : std_logic := '0';
    signal bad_checksum         : std_logic := '0';
    signal parse_checksum       : std_logic := '0';

    -- New data detector signals
    type new_data_stateType is (init, wait_byte_received);
    signal new_data_state : new_data_stateType;

    signal new_data     : std_logic := '0';
    signal byte_buffer  : t_byte := (others => '0');

    -- Word parser signals
    type word_stateType is (init, wait_new_data, save_byte, store_word);
    signal word_state : word_stateType;

    signal word_buffer      : t_word := (others => '0');
    signal received_word    : t_word := (others => '0');
    signal byte_counter     : unsigned(bits_req(t_word'length/8) - 1 downto 0) := (others => '0');
    signal word_available   : std_logic := '0';

    -- Debug parameters
    attribute keep : string;
    attribute keep of good_preamble     : signal is "true";
    attribute keep of bad_preamble      : signal is "true";
    attribute keep of good_type         : signal is "true";
    attribute keep of bad_type          : signal is "true";
    attribute keep of id_received       : signal is "true";
    attribute keep of good_size         : signal is "true";
    attribute keep of payload_received  : signal is "true";
    attribute keep of good_checksum     : signal is "true";
    attribute keep of bad_checksum      : signal is "true";
    attribute keep of received_word     : signal is "true";

begin

-- General packet parser. Once we know which type the packet is, the cmd, reply or data parsers are started
params_valid <= params_valid_cmd or params_valid_reply or params_valid_data;

packet_parser : process(clk, rst)
begin
    if (rst = '1') then
        packet_parser_state <= init;
    elsif (rising_edge(clk)) then
        case packet_parser_state is
            when init =>
                parse_preamble  <= '0';
                parse_type      <= '0';
                parse_cmd       <= '0';
                parse_reply     <= '0';
                parse_data      <= '0';

                if (new_data = '1') then
                    parse_preamble <= '1';
                    packet_parser_state <= check_preamble;
                else 
                    packet_parser_state <= packet_parser_state;
                end if;

            when check_preamble =>
                parse_preamble <= '0';
                if (good_preamble = '1') then
                    parse_type <= '1';
                    packet_parser_state <= check_type;
                elsif (bad_preamble = '1') then
                    packet_parser_state <= init;
                else
                    packet_parser_state <= packet_parser_state;
                end if;
            
            when check_type =>
                parse_type <= '0';
                if (good_type = '1') then
                    if (packet_type_reg = cmd_rb or packet_type_reg = cmd_wb or packet_type_reg = cmd_go or 
                        packet_type_reg = cmd_st or packet_type_reg = cmd_rs) then
                        parse_cmd <= '1';
                    elsif (packet_type_reg = reply) then  
                        parse_reply <= '1';
                    elsif (packet_type_reg = data) then
                        parse_data <= '1';
                    end if;
                    packet_parser_state <= init;
                elsif (bad_type = '1') then
                    packet_parser_state <= init;
                else
                    packet_parser_state <= packet_parser_state;
                end if;
                
            when others =>
                packet_parser_state <= init;
        end case;
    end if;
end process;

-- Cmd parser
cmd_parser : process(clk, rst)
begin
    if (rst = '1') then
        cmd_state <= init;
    elsif (rising_edge(clk)) then
        case cmd_state is
            when init =>
                parse_id_cmd        <= '0';
                parse_size_cmd      <= '0';
                parse_payload_cmd   <= '0';
                parse_checksum_cmd  <= '0';
                params_valid_cmd    <= '0';


                if (parse_cmd = '1') then
                    parse_id_cmd <= '1';
                    cmd_state <= wait_id;
                else
                    cmd_state <= cmd_state;
                end if;

            when wait_id =>
                parse_id_cmd <= '0';
                if (id_received = '1') then
                    parse_size_cmd <= '1';
                    cmd_state <= wait_size;
                else
                    cmd_state <= cmd_state;
                end if;
            
            when wait_size =>
                parse_size_cmd <= '0';
                if (good_size = '1') then
                    parse_payload_cmd <= '1';
                    cmd_state <= wait_payload;
                elsif (bad_size = '1') then
                    cmd_state <= init;
                else
                    cmd_state <= cmd_state;
                end if;
            
            when wait_payload =>
                parse_payload_cmd <= '0';
                if (payload_received = '1') then
                    parse_checksum_cmd <= '1';
                    cmd_state <= wait_checksum;
                else
                    cmd_state <= cmd_state;
                end if;
            
            when wait_checksum =>
                parse_checksum_cmd <= '0';
                if (good_checksum = '1') then
                    params_valid_cmd <= '1';
                    cmd_state <= init; 
                elsif (bad_checksum = '1') then
                    cmd_state <= init;
                else
                    cmd_state <= cmd_state;
                end if;

            when others =>
                cmd_state <= init;
        end case;
    end if;
end process;

-- Reply parser
reply_parser : process(clk, rst)
begin
    if (rst = '1') then
        reply_state <= init;
    elsif (rising_edge(clk)) then
        case reply_state is
            when init =>
                parse_size_reply        <= '0';
                parse_err_reply         <= '0';
                parse_id_reply          <= '0';
                parse_payload_reply     <= '0';
                parse_checksum_reply    <= '0';
                params_valid_reply      <= '0';

                if (parse_reply = '1') then
                    parse_size_reply <= '1';
                    reply_state <= wait_size;
                else
                    reply_state <= reply_state;
                end if;

            when wait_size =>
                parse_size_reply <= '0';
                if (good_size = '1') then
                    parse_err_reply <= '1';
                    reply_state <= wait_err;
                elsif (bad_size = '1') then
                    reply_state <= init;
                else
                    reply_state <= reply_state;
                end if;
            
            when wait_err =>
                parse_err_reply <= '0';
                if (err_received = '1') then
                    parse_id_reply <= '1';
                    reply_state <= wait_id;
                else
                    reply_state <= reply_state;
                end if;
            
            when wait_id =>
                parse_id_reply <= '0';
                if (id_received = '1') then
                    parse_payload_reply <= '1';
                    reply_state <= wait_payload;
                else
                    reply_state <= reply_state;
                end if;
            
            when wait_payload =>
                parse_payload_reply <= '0';
                if (payload_received = '1') then
                    parse_checksum_reply <= '1';
                    reply_state <= wait_checksum;
                else
                    reply_state <= reply_state;
                end if;
            
            when wait_checksum  =>
                parse_checksum_reply <= '0';
                if (good_checksum = '1') then
                    params_valid_reply <= '1';
                    reply_state <= init;
                elsif (bad_checksum = '1') then
                    reply_state <= init;
                else
                    reply_state <= reply_state;
                end if;
            
            when others =>
                reply_state <= init;
        end case;
    end if;
end process;

-- Data parser
data_parser : process(clk, rst)
begin
    if (rst = '1') then
        data_state <= init;
    elsif (rising_edge(clk)) then
        case data_state is
            when init =>
                parse_size_data         <= '0';
                parse_payload_data      <= '0';
                parse_checksum_data     <= '0';
                params_valid_data       <= '0';

                if (parse_data = '1') then
                    parse_size_data <= '1';
                    data_state <= wait_size;
                else
                    data_state <= data_state;
                end if;

            when wait_size =>
                parse_size_data <= '0';
                if (good_size = '1') then
                    parse_payload_data <= '1';
                    data_state <= wait_payload;
                elsif (bad_size = '1') then
                    data_state <= init;
                else
                    data_state <= data_state;
                end if;
            
            when wait_payload =>
                parse_payload_data <= '0';
                if (payload_received = '1') then
                    parse_checksum_data <= '1';
                    data_state <= wait_checksum;
                else
                    data_state <= data_state;
                end if;
            
            when wait_checksum =>
                parse_checksum_data <= '0';
                if (good_checksum = '1') then
                    params_valid_data <= '1';
                    data_state <= init;
                elsif (bad_checksum = '1') then
                    data_state <= init;
                else
                    data_state <= data_state;
                end if;

            when others =>
                data_state <= init;
        end case;
    end if;
end process;

-- Preamble parser
preamble_parser : process(clk, rst)
begin
    if (rst = '1') then
        preamble_state <= init;
    elsif (rising_edge(clk)) then
        case preamble_state is
            when init =>
                good_preamble   <= '0';
                bad_preamble    <= '0';
                preamble_count  <= '0';
                
                if (parse_preamble = '1') then
                    preamble_state <= check_preamble;
                else
                    preamble_state <= preamble_state;
                end if;
            when check_preamble =>
                if (word_available = '1') then
                    if (preamble_count = '0') then
                        if (received_word = PREAMBLE_1) then
                            preamble_count <= '1';
                            preamble_state <= check_preamble;
                        else 
                            bad_preamble <= '1';
                            preamble_state <= init;
                        end if;
                    else
                        if (received_word = PREAMBLE_2) then
                            good_preamble <= '1';
                        else 
                            bad_preamble <= '1';
                        end if;

                        preamble_state <= init;
                    end if;
                        
                end if;
            when others =>
                preamble_state <= init;
        end case;
    end if;
end process;

-- Type parser
packet_type <= packet_type_reg;

type_parser : process(clk, rst)
begin
    if (rst = '1') then
        type_state <= init;
        packet_type_reg <= undefined;

    elsif (rising_edge(clk)) then
        case type_state is
            when init =>
                bad_type <= '0';
                good_type <= '0';

            if (parse_type = '1') then
                type_state <= check_type;
            else 
                type_state <= type_state;
            end if;

            when check_type =>
                if (word_available = '1') then
                    case received_word is
                        when CMD_RB_TYPE =>
                            packet_type_reg <= cmd_rb;
                            good_type <= '1';
                        when CMD_WB_TYPE =>
                            packet_type_reg <= cmd_wb;
                            good_type <= '1';
                        when CMD_GO_TYPE =>
                            packet_type_reg <= cmd_go;
                            good_type <= '1';
                        when CMD_ST_TYPE =>
                            packet_type_reg <= cmd_st;
                            good_type <= '1';
                        when CMD_RS_TYPE =>
                            packet_type_reg <= cmd_rs;
                            good_type <= '1';
                        when REPLY_TYPE  =>
                            packet_type_reg <= reply;
                            good_type <= '1';
                        when DATA_TYPE   =>
                            packet_type_reg <= data;
                            good_type <= '1';
                        when others =>
                            bad_type <= '1';
                    end case;
                    
                    type_state <= init;
                else 
                    type_state <= type_state;
                end if;
            when others =>
                type_state <= init;
        end case;
    end if;
end process;

-- Id parser
parse_id <= parse_id_cmd or parse_id_reply;

id_parser_state : process(clk, rst)
begin
    if (rst = '1') then
        id_state <= init;
        card_id <= (others => '0');
        param_id <= (others => '0');

    elsif (rising_edge(clk)) then
        case id_state is
            when init =>
                id_received <= '0';

                if (parse_id = '1') then
                    id_state <= wait_word;
                else
                    id_state <= id_state;
                end if;
            when wait_word =>
                if (word_available = '1') then
                    card_id <= received_word(31 downto 16);
                    param_id <= received_word(15 downto 0);
                    id_received <= '1';
                    id_state <= init;
                else
                    id_state <= id_state;
                end if;

            when others =>
                id_state <= init;
        end case;
    end if;
end process;

-- Size parser
parse_size <= parse_size_cmd or parse_size_reply or parse_size_data;
payload_size <= payload_size_reg;

size_parser : process(clk, rst)
begin
    if (rst = '1') then
        size_state <= init;
        good_size <= '0';
        bad_size <= '0';
        payload_size_reg <= (others => '0');

    elsif (rising_edge(clk)) then
        case size_state is
            when init =>
                good_size <= '0';
                bad_size <= '0';

                if (parse_size = '1') then
                    size_state <= wait_word;
                else
                    size_state <= size_state;
                end if;

            when wait_word =>
                if (word_available = '1') then
                    -- Basic check. Here we just check that the size is a feasible size. cmd handler will decide if the size is actually the
                    -- correct for that packet
                    if (to_integer(unsigned(received_word)) > 0 and to_integer(unsigned(received_word)) < t_packet_payload'length) then
                        if (packet_type_reg = cmd_rb or packet_type_reg = cmd_wb or packet_type_reg = cmd_go or
                            packet_type_reg = cmd_st or packet_type_reg = cmd_rs) then

                            payload_size_reg <= resize(unsigned(received_word), payload_size_reg'length);
                            good_size <= '1';

                        elsif (packet_type_reg = reply) then
                            if (to_integer(unsigned(received_word)) > 3) then
                                payload_size_reg <= resize(unsigned(received_word) - 3, payload_size_reg'length);
                                good_size <= '1';
                            else
                                bad_size <= '1';
                            end if;

                        else
                            if (to_integer(unsigned(received_word)) > 1) then
                                payload_size_reg <= resize(unsigned(received_word) - 1, payload_size_reg'length);
                                good_size <= '1';
                                size_state <= init;
                            else
                                bad_size <= '1';
                            end if;
                        end if;

                    else
                        bad_size <= '1';
                    end if;

                    size_state <= init;
                else
                    size_state <= size_state;
                end if;

            when others =>
                size_state <= init;
        end case;
    end if;
end process;

-- Error/OK parser
parse_err <= parse_err_reply;

err_parser : process(clk, rst)
begin
    if (rst = '1') then
        err_state <= init;
        cmd_type <= undefined;
        err_ok <= '0';

    elsif (rising_edge(clk)) then
        case err_state is
            when init =>
                err_received <= '0';

                if (parse_err = '1') then
                    err_state <= wait_word;
                else
                    err_state <= err_state;
                end if;
            
            when wait_word =>
                if (word_available = '1') then
                    case received_word(31 downto 16) is
                        when RB_ASCII =>
                            cmd_type <= cmd_rb;

                        when WB_ASCII =>
                            cmd_type <= cmd_wb;

                        when GO_ASCII =>
                            cmd_type <= cmd_go;

                        when ST_ASCII =>
                            cmd_type <= cmd_st;

                        when RS_ASCII =>
                            cmd_type <= cmd_rs;
                        
                        when others =>
                            cmd_type <= undefined;
                    end case;

                    case received_word(15 downto 0) is
                        when OK_ASCII =>
                            err_ok <= '0';
                        when ER_ASCII =>
                            err_ok <= '1';
                        when others =>
                            err_ok <= '1';
                    end case;

                    err_received <= '1';
                    err_state <= init;
                else
                    err_state <= err_state;
                end if;

            when others =>
                err_state <= init;
        end case;
    end if;
end process;

-- Payload parser
parse_payload <= parse_payload_cmd or parse_payload_reply or parse_payload_data;
packet_payload <= packet_payload_reg;
payload_parser : process(clk, rst)
begin
    if (rst = '1') then
        payload_state <= init;
    elsif (rising_edge(clk)) then
        case payload_state is
            when init =>
                payload_word_count  <= (others => '0');
                payload_received    <= '0';

                if (parse_payload = '1') then
                    payload_state <= wait_word;
                else
                    payload_state <= payload_state;
                end if;

            when wait_word =>
                if (word_available = '1') then
                    packet_payload_reg(to_integer(payload_word_count)) <= received_word;
                    
                    if (packet_type_reg = reply or packet_type_reg = data) then
                        -- If payload 0 we already know is not a valid packet, but it will be discarded by cmd_handler
                        if (payload_size_reg = 0 or payload_word_count = payload_size_reg - 1) then
                            payload_received <= '1';
                            payload_state <= init;
                        else 
                            payload_word_count <= payload_word_count + 1;
                            payload_state <= payload_state;
                        end if;
                    else 
                        if (payload_word_count = MAX_REPLY_PAYLOAD - 1) then
                            payload_received <= '1';
                            payload_state <= init;
                        else 
                            payload_word_count <= payload_word_count + 1;
                            payload_state <= payload_state;
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

-- Checksum parser
parse_checksum <= parse_checksum_cmd or parse_checksum_reply or parse_checksum_data;

checksum_parser : process(clk, rst)
begin
    if (rst = '1') then
        checksum_state <= init;
    elsif (rising_edge(clk)) then
        case checksum_state is
            when init =>
                calculated_checksum     <= (others => '0');
                good_checksum           <= '0';
                bad_checksum            <= '0';

                checksum_state <= wait_for_packet_type;

            when wait_for_packet_type =>
                if (good_type = '1') then
                    if (packet_type_reg = cmd_rb or packet_type_reg = cmd_wb or
                        packet_type_reg = cmd_go or packet_type_reg = cmd_st or
                        packet_type_reg = cmd_rs or packet_type_reg = data) then

                        checksum_state <= wait_for_payload_param;
                    else
                        checksum_state <= wait_for_err_param;
                    end if;
                else 
                    checksum_state <= checksum_state;
                end if;
            
            when wait_for_err_param => 
                if (err_received = '1') then
                    calculated_checksum <= calculated_checksum xor received_word;
                    checksum_state <= wait_for_id_param;
                else
                    checksum_state <= checksum_state;
                end if;
            
            when wait_for_id_param =>
                if (id_received = '1') then
                    calculated_checksum <= calculated_checksum xor received_word;
                    checksum_state <= wait_for_payload_param;
                else
                    checksum_state <= checksum_state;
                end if;
            
            when wait_for_payload_param =>
                if (parse_payload = '1') then
                    checksum_state <= wait_payload_word;
                elsif (bad_size = '1') then
                    checksum_state <= init;
                else
                    checksum_state <= checksum_state;
                end if;
            
            when wait_payload_word =>
                if (word_available = '1') then
                    calculated_checksum <= calculated_checksum xor received_word;
                    checksum_state <= wait_payload_word;
                    
                elsif (payload_received = '1') then
                    checksum_state <= wait_parse_checksum;
                else
                    checksum_state <= checksum_state;
                end if;
            
            when wait_parse_checksum =>
                if (parse_checksum = '1') then
                    checksum_state <= wait_word;
                else
                    checksum_state <= checksum_state;
                end if;
            
            when wait_word =>
                if (word_available = '1') then
                    if (received_word = calculated_checksum) then
                        good_checksum <= '1';
                    else
                        bad_checksum <= '1';
                    end if;
                    checksum_state <= init;
                end if;
            
            when others =>
                checksum_state <= init;
        end case;
    end if;
end process;

-- SM logic to detect when a new byte has been received through the RX UART controller
new_data_detector : process(clk, rst)
begin
    if (rst = '1') then
        new_data_state <= init;
    elsif (rising_edge(clk)) then
        case new_data_state is
            when init =>
                new_data <= '0';

                if (rx_busy = '1') then
                    new_data_state <= wait_byte_received;
                else
                    new_data_state <= new_data_state;
                end if;

            when wait_byte_received =>
                if (rx_busy = '0') then
                    byte_buffer <= byte_data;
                    new_data <= '1';
                    new_data_state <= init;
                else 
                    new_data_state <= wait_byte_received;
                end if;

            when others => -- We should never reach this point
                new_data_state <= init;
        end case;
    end if;
end process;

-- Creates a new word each 4 bytes
word_parser : process(clk, rst)
begin
    if (rst = '1') then
        word_state <= init;
    elsif (rising_edge(clk)) then
        case word_state is
            when init =>
                word_buffer     <= (others => '0');
                received_word   <= (others => '0');
                byte_counter    <= (others => '0');
                word_available  <= '0';

                word_state <= wait_new_data;

            when wait_new_data =>
                word_available <= '0';

                if (new_data = '1') then
                    word_state <= save_byte;
                else
                    word_state <= word_state;
                end if;

            when save_byte =>
                word_buffer( (8 * (to_integer(byte_counter) + 1) - 1) downto (8 * to_integer(byte_counter))) <= byte_buffer;
                if (byte_counter = t_word'length / 8 - 1) then
                    byte_counter <= (others => '0');
                    word_state <= store_word;
                else
                    byte_counter <= byte_counter + 1;
                    word_state <= wait_new_data;
                end if;

            when store_word =>
                received_word <= word_buffer;
                word_available <= '1';
                word_state <= wait_new_data;

            when others =>
                word_state <= init;
        end case;
    end if;
end process;

end behave;