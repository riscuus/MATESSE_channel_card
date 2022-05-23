----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.18.2022
-- Module Name: command_handler.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of controlling all the submodules of the system. It communicates with the
--              exterior through the "packet handlers", and translates that into the necessary signals to the rest of
--              the modules

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

entity command_handler is
    port(
        clk                     : in std_logic; -- 5MHz clock                                                                           
        rst                     : in std_logic; -- Asynchronous reset

        -- Interface with the packet parser
        packet_type             : in t_packet_type; -- We will only store commands
        card_id                 : in t_half_word; -- We will only store commands that are sent to this card
        param_id                : in t_half_word; -- The param of the command
        payload_size            : in natural; -- Received payload size
        packet_payload          : in t_packet_payload; -- The data (if any) of the param to be stored
        params_valid            : in std_logic;

        -- Interface with the RAM
        ram_read_data           : in t_word;
        ram_write_data          : out t_word;
        ram_address             : out t_param_id_address;
        ram_write               : out std_logic;

        -- Interface with the packet sender
        packet_sender_ready     : in std_logic; -- The packet sender module is ready to send a new packet
        send_reply_pulse        : out std_logic; -- Signal to indicate the packet sender to send a new reply
        reply_cmd_type          : out t_packet_type;
        reply_err_ok            : out std_logic -- Signal that will be used by the packet_sender to define the err_ok param of the reply packets
        reply_payload_size      : out natural; -- The size that the reply packet payload will have
        param_data              : out t_max_reply_payload; -- Used for the reply and for updating the params buffers

        -- Interface with param buffers
        update_param            : out std_logic;
        param_id_address        : out t_param_id_address;


        last_data_frame_pulse   : in std_logic; -- The last data frame during an acquisition has been sent. Used when stop
        acquisition_on          : out std_logic; -- Signal to indicate the loop controller module to start a new acquisition

    );

end command_handler;

architecture behave of command_handler is
    type stateType is (init, idle, check_card_id, check_type, check_param_id, read_ram_data, write_ram_data, 
                       update_param, start_acquisition, stop_acquisition, wait_last_data_frame, send_ok_reply, 
                       send_err_reply);
    signal state : stateType;

    -- Registers to store the packet data while it is valid
    signal packet_type_reg      : packet_type := undefined;
    signal card_id_reg          : t_half_word := (others => '0');
    signal param_id_reg         : t_half_word := (others => '0');
    signal payload_size_reg     : natural := 0;
    signal packet_payload_reg   : t_packet_payload := (others => (others => '0'))

    -- Internal registers to know current state
    signal acquisition_on_reg       : std_logic := '0'; -- Allows us to also read the current value
    signal acquisition_configured   : std_logic := '0'; -- Active when the user has setup the command ret_dat_s
    signal param_id_size    : natural := 0; -- # of words that the param occupies in the RAM
    signal word_count       : natural := 0; -- Counter for reading the param words from the RAM

    signal reply_err_word   : t_word := (others => '0');

begin

    acquisition_on <= acquisition_on_reg;

    main_state_process : process(clk, rst)
    begin
        if (rst = '1') then
            state <= reset;
        elsif (rising_edge(clk)) then
            case state is

                when reset =>
                    acquisition_on_reg     <= '0';
                    acquisition_configured <= '0';

                    state <= idle;

                when idle =>
                    send_reply_pulse <= '0';
                    param_data       <= (others => (others => '0'));
                    reply_cmd_type   <= undefined;
                    reply_err_word   <= (others => '0');

                    -- New packet received
                    if (params_valid = '1') then
                        -- Store parameters while they are valid
                        packet_type_reg <= packet_type;
                        card_id_reg <= card_id;
                        param_id_reg <= param_id;
                        payload_size_reg <= payload_size;
                        packet_payload_reg <= packet_payload;
                        
                        state <= check_card_id;
                    else
                        state <= state;
                    end if;

                -- Card id
                when check_card_id =>
                    if (card_id_reg = DAUGHTER_CARD_ID) then
                        state <= check_type;
                    else -- Not for this card, ignore
                        state <= idle;
                    end if;

                -- Type
                when check_type =>
                    if (acquisition_on = '1') then
                        if (packet_type_reg = cmd_st and param_id_reg = RET_DAT_ADDR) then -- Stop acquisition
                            state <= stop_acquisition;
                        else -- While in acquisition ignore all packets that are not stop
                            state <= idle;
                        end if;
                    else 
                        if (packet_type_reg = cmd_go) then
                            if (acquisition_configured = '1' and param_id_reg = RET_DAT_ADDR) then
                                state <= start_acquisition;
                            else
                                reply_err_word(0) <= '1';
                                state <= send_err_reply;
                            end if;
                        elsif (packet_type_reg = cmd_rb or packet_type_reg = cmd_wb) then 
                            state <= check_param_id; 
                        else -- Not a command, send ER
                            reply_err_word(1) <= '1';
                            state <= send_err_reply;
                        end if;
                    end if;

                -- Param id
                when check_param_id =>
                    if (to_integer(unsigned(param_id_reg(7 downto 0))) = ROW_LEN_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = NUM_ROWS_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = RET_DATA_S_ADDR or -- Special case
                        to_integer(unsigned(param_id_reg(7 downto 0))) = SA_BIAS_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = RET_DAT_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = SERVO_MODE_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = RAMP_DLY_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = RAMP_AMP_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = RAMP_STEP_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = FB_CONST_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = SAMPLE_DLY_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = SAMPLE_NUM_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = FB_DLY_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = FLTR_RST_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = FILTR_COEFF_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = FLUX_FB_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = BIAS_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = ROW_ORDER_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = ON_BIAS_ADDR or
                        to_integer(unsigned(param_id_reg(7 downto 0))) = OFF_BIAS_ADDR) then -- Param id is valid

                        param_id_address <= to_integer(unsigned(param_id_reg(7 downto 0))); 
                        param_id_size <= PARAM_ID_TO_SIZE(to_integer(unsigned(param_id_reg(7 downto 0))));

                        if (packet_type_reg = cmd_rb) then -- We either read the param or write it
                            reply_cmd_type <= cmd_rb;
                            state <= read_ram_data;
                        else
                            reply_cmd_type <= cmd_wb;
                            state <= write_ram_data;
                        end if;
                    else -- Incorrect param id
                        reply_err_word(2) <= '1';
                        state <= send_err_reply
                    end if;
                
                when read_ram_data =>
                    param_data(word_count) <= ram_read_data;
                    if (word_count = param_id_size - 1) then
                        state <= send_reply;
                    else
                        word_count <= word_count + 1;
                        param_id_address <= param_id_address + 1;
                        state <= state;
                    end if;
                
                when write_ram_data =>
                    ram_write_data <= packet_payload(word_count);
                    ram_write <= '1';
                    
                    if (word_count = payload_size - 1) then
                        state <= update_param;
                    else
                        param_id_address <= param_id_address + 1;
                        state <= state;
                    end if;

                when update_param =>
                    ram_write <= '0';
                    param_id_address <= to_integer(unsigned(param_id_reg(7 downto 0)));
                    param_data <= packet_payload(word_count);
                    update_param <= '1';

                    -- Check special case
                    if (param_id_reg = RET_DATA_S) then
                        acquisition_configured <= '1';
                    end if;

                    state <= send_reply;

                -- Acquire data
                when start_acquisition =>
                    acquisition_on_reg <= '1';
                    param_data(0)(0) <= '1';

                    state <= send_ok_reply;

                -- Stop acquisition
                when stop_acquisition =>
                    acquisition_on_reg <= '0';

                    state <= wait_last_data_frame;

                -- Wait last data frame
                when wait_last_data_frame =>
                    if (last_data_frame_pulse = '1') then
                        state <= send_ok_reply;
                    else
                        state <= state;
                    end if;

                when send_ok_reply =>
                    update_param <= '0';

                    if (packet_sender_ready = '1') then
                        reply_err_ok <= '0';
                        reply_payload_size <= param_id_size;
                        send_reply_pulse <= '1';

                        state <= idle;
                    else
                        state <= state;
                    end if;

                when send_err_reply =>
                    if (packet_sender_ready = '1') then
                        reply_err_ok <= '1';
                        reply_payload_size <= 1;
                        param_data(0) <= reply_err_word;
                        send_reply_pulse <= '1';

                        state <= idle;
                    else
                        state <= state;
                    end if;

                when others =>
                    state <= init;
            end case;
        end if;

    end process;

end behave;