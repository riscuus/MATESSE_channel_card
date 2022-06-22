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
        ram_address             : out natural;
        ram_write               : out std_logic;

        -- Interface with the packet sender
        packet_sender_ready     : in std_logic; -- The packet sender module is ready to send a new packet
        send_reply_pulse        : out std_logic; -- Signal to indicate the packet sender to send a new reply
        reply_cmd_type          : out t_packet_type;
        reply_err_ok            : out std_logic; -- Signal that will be used by the packet_sender to define the err_ok param of the reply packets
        reply_payload_size      : out natural; -- The size that the reply packet payload will have
        param_data              : out t_packet_payload; -- Used for the reply and for updating the params buffers

        -- Interface with param buffers
        update_param_pulse      : out std_logic;
        param_id_to_update      : out natural;

        -- Interface with channels controller
        set_SF                  : out std_logic;
        set_SB                  : out std_logic;
        set_FF                  : out std_logic;
        set_FB                  : out std_logic;

        -- Interface with TES bias setter
        set_TES_bias            : out std_logic;

        -- Interface with row_activator
        update_off_value        : out std_logic;

        -- Interface with frame_builder
        last_data_frame_pulse   : in std_logic; -- The last data frame during an acquisition has been sent. Used when stop
        stop_received           : out std_logic := '0'; -- Pulse indicating that while an acquisition the stop cmd was received

        acquisition_on          : out std_logic -- Signal to indicate the loop controller module to start a new acquisition

    );

end command_handler;

architecture behave of command_handler is
    type stateType is (init, idle, check_card_id, check_type, check_param_id, check_payload_size, wait_read_data,
                       read_ram_data, write_ram_data, update_special_param, update_param_state, start_acquisition, stop_acquisition, 
                       wait_last_data_frame, setup_ok_reply, setup_err_reply, wait_packet_sender_ready, send_reply);
    signal state : stateType;

    -- Registers to store the packet data while it is valid
    signal packet_type_reg      : t_packet_type := undefined;
    signal card_id_reg          : t_half_word := (others => '0');
    signal param_id_reg         : t_half_word := (others => '0');
    signal payload_size_reg     : natural := 0;
    signal packet_payload_reg   : t_packet_payload := (others => (others => '0'));

    -- Internal registers to know current state
    signal acquisition_on_reg       : std_logic := '0'; -- Allows us to also read the current value
    signal acquisition_configured   : std_logic := '0'; -- Active when the user has setup the command ret_dat_s
    signal param_id_size            : natural := 0; -- # of words that the param occupies in the RAM
    signal ram_address_reg          : natural := 0;
    signal word_count               : natural := 0; -- Counter for reading the param words from the RAM
    signal correct_param_id         : std_logic := '0';

    signal reply_err_word   : t_word := (others => '0');

begin

    -- Param data

    main_state_process : process(clk, rst)
    begin
        if (rst = '1') then

            ram_write           <= '0';
            send_reply_pulse    <= '0';
            reply_err_ok        <= '0';
            reply_payload_size  <= 0;
            param_data          <= (others => (others =>'0'));
            update_param_pulse  <= '0';
            param_id_to_update  <= 0;
            set_SF              <= '0';
            set_SB              <= '0';
            set_FF              <= '0';
            set_FB              <= '0';
            set_TES_bias        <= '0';
            update_off_value    <= '0';
            stop_received       <= '0';

            state <= init;
        elsif (rising_edge(clk)) then
            case state is

                when init =>
                    -- Signals
                    acquisition_on_reg      <= '0';
                    acquisition_configured  <= '0';
                    ram_address_reg         <= 0;
                    reply_err_word          <= (others => '0');

                    packet_type_reg         <= undefined;
                    card_id_reg             <= (others => '0');
                    param_id_reg            <= (others => '0');
                    payload_size_reg        <= 0;
                    packet_payload_reg      <= (others => (others => '0'));

                    -- Outputs
                    reply_err_ok            <= '0';
                    reply_payload_size      <= 0;
                    param_id_to_update      <= 0;
                    set_SF                  <= '0';
                    set_SB                  <= '0';
                    set_FF                  <= '0';
                    set_FB                  <= '0';
                    set_TES_bias            <= '0';
                    update_off_value        <= '0';

                    state <= idle;

                when idle =>
                    reply_err_word <= (others => '0');
                    word_count     <= 0;

                    -- New packet received
                    if (params_valid = '1') then
                        -- Store parameters while they are valid
                        packet_type_reg <= packet_type;
                        card_id_reg <= card_id;
                        param_id_reg <= param_id;
                        payload_size_reg <= payload_size;
                        packet_payload_reg <= packet_payload;
                        
                        state <= check_card_id;
                    elsif (acquisition_on_reg = '1' and last_data_frame_pulse = '1') then
                        -- We were on an acquisition and the last data frame has already sent. We stop the acquisition logic
                        acquisition_on_reg <= '0';
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
                    if (acquisition_on_reg = '1') then
                        if ( packet_type_reg = cmd_st and to_integer(unsigned(param_id_reg)) = RET_DATA_ID) then -- Stop acquisition
                            stop_received <= '1';
                            state <= stop_acquisition;
                        else -- While in acquisition ignore all packets that are not stop
                            state <= idle;
                        end if;
                    else 
                        if (packet_type_reg = cmd_go) then
                            if (acquisition_configured = '1' and to_integer(unsigned(param_id_reg)) = RET_DATA_ID) then
                                state <= start_acquisition;
                            else
                                reply_err_word <= ERROR_GO_WITH_NO_SETUP;  -- ER_CODE = cmd_go without previous configuration
                                state <= setup_err_reply;
                            end if;
                        elsif (packet_type_reg = cmd_rb or packet_type_reg = cmd_wb) then 
                            state <= check_param_id; 
                        elsif (packet_type_reg = cmd_st) then
                            reply_err_word <= ERROR_ST_WITH_NO_ACQ;
                            state <= setup_err_reply; -- ER_CODE = cmd_st without acquisition starte
                        else -- Not a command, ignore
                            state <= idle;
                        end if;
                    end if;

                -- Param id
                when check_param_id =>
                    if (correct_param_id = '1') then
                        ram_address_reg <= to_integer(unsigned(param_id_reg(7 downto 0))); 
                        param_id_to_update <= to_integer(unsigned(param_id_reg(7 downto 0))); 
                        param_id_size <= PARAM_ID_TO_SIZE(to_integer(unsigned(param_id_reg(7 downto 0))));
                        
                        if (packet_type_reg = cmd_rb) then -- We either read the param or write it
                            state <= wait_read_data;
                        else
                            state <= check_payload_size;
                        end if;
                    else -- Incorrect param id
                        reply_err_word <= ERROR_INCORRECT_PARAM_ID; -- ER_CODE = Incorrect param_id
                        state <= setup_err_reply;
                    end if;
                
                when check_payload_size =>
                    if (param_id_size = payload_size_reg) then
                        ram_write <= '1';
                        state <= write_ram_data;
                    else
                        reply_err_word <= ERROR_INCORRECT_PARAM_SIZE; -- ER_CODE = Incorrect payload size
                        state <= setup_err_reply;
                    end if;

                when wait_read_data =>
                    -- We always must set the next address to be read before in order to have the correct data in the
                    -- correct word_count clock cycle
                    ram_address_reg <= ram_address_reg + 1;
                    state <= read_ram_data;

                when read_ram_data =>
                    param_data(word_count) <= ram_read_data;
                    if (word_count = param_id_size - 1) then
                        state <= setup_ok_reply;
                    else
                        ram_address_reg <= ram_address_reg + 1;
                        word_count <= word_count + 1;
                        state <= state;
                    end if;
                
                when write_ram_data =>
                    param_data(word_count) <= packet_payload_reg(word_count); -- We already set the param data for the later update

                    if (word_count = param_id_size - 1) then
                        ram_write <= '0';
                        update_param_pulse <= '1';
                        state <= update_param_state;
                    else
                        ram_address_reg <= ram_address_reg + 1;
                        word_count <= word_count + 1;
                        state <= state;
                    end if;

                when update_param_state =>

                    -- Check special cases
                    if (to_integer(unsigned(param_id_reg)) = RET_DATA_S_ID) then
                        acquisition_configured <= '1';
                        state <= setup_ok_reply;
                    elsif (to_integer(unsigned(param_id_reg)) = SA_FB_ID) then
                        set_SF <= '1';
                        state <= update_special_param;
                    elsif (to_integer(unsigned(param_id_reg)) = SA_BIAS_ID) then
                        set_SB <= '1';
                        state <= update_special_param;
                    elsif (to_integer(unsigned(param_id_reg)) = SQ1_FB_ID) then
                        set_FF <= '1';
                        state <= update_special_param;
                    elsif (to_integer(unsigned(param_id_reg)) = SQ1_BIAS_ID) then
                        set_FB <= '1';
                        state <= update_special_param;
                    elsif (to_integer(unsigned(param_id_reg)) = BIAS_ID) then
                        set_TES_bias <= '1';
                        state <= update_special_param;
                    elsif (to_integer(unsigned(param_id_reg)) = OFF_BIAS_ID) then
                        update_off_value <= '1';
                        state <= update_special_param;
                    else
                        state <= setup_ok_reply;
                    end if;

                    update_param_pulse <= '0';
                
                when update_special_param =>
                        set_SF              <= '0';
                        set_SB              <= '0';
                        set_FF              <= '0';
                        set_FB              <= '0';
                        set_TES_bias        <= '0';
                        update_off_value    <= '0';

                        state <= setup_ok_reply;

                -- Acquire data
                when start_acquisition =>
                    acquisition_on_reg <= '1';

                    state <= setup_ok_reply;

                -- Stop acquisition
                when stop_acquisition =>
                    stop_received <= '0';
                    acquisition_on_reg <= '0';

                    state <= wait_last_data_frame;

                -- Wait last data frame
                when wait_last_data_frame =>
                    if (last_data_frame_pulse = '1') then
                        state <= setup_ok_reply;
                    else
                        state <= state;
                    end if;

                when setup_ok_reply =>
                    if (packet_type_reg = cmd_rb) then
                        reply_payload_size <= param_id_size;
                    else -- For successful non-RB commands, this is always a single zero word
                        param_data <= (others => (others =>'0'));
                        reply_payload_size <= 1;
                    end if;
                    reply_err_ok <= '0';

                    state <= wait_packet_sender_ready;


                when setup_err_reply =>
                    reply_err_ok <= '1';
                    reply_payload_size <= 1;
                    param_data(0) <= reply_err_word;

                    state <= wait_packet_sender_ready;

                when wait_packet_sender_ready =>
                    if (packet_sender_ready = '1') then
                        send_reply_pulse <= '1';
                        state <= send_reply;
                    else
                        state <= state;
                    end if;

                when send_reply =>
                    send_reply_pulse <= '0';
                    state <= idle;

                when others =>
                    state <= init;
            end case;
        end if;
    end process;

    -- Combinational assignments
    acquisition_on      <= acquisition_on_reg;
    ram_address         <= ram_address_reg;
    reply_cmd_type      <= packet_type_reg;
    ram_write_data      <= packet_payload_reg(word_count);
    
    -- Conbinational conditional assigments
    correct_param_id    <= '1' when to_integer(unsigned(param_id_reg(7 downto 0))) = ROW_ORDER_ID    or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = ON_BIAS_ID      or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = OFF_BIAS_ID     or 
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = SA_BIAS_ID      or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = FLTR_RST_ID     or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = RET_DATA_ID     or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = DATA_MODE_ID    or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = FILTR_COEFF_ID  or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = SERVO_MODE_ID   or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = RAMP_DLY_ID     or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = RAMP_AMP_ID     or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = RAMP_STEP_ID    or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = BIAS_ID         or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = ROW_LEN_ID      or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = NUM_ROWS_ID     or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = SAMPLE_DLY_ID   or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = SAMPLE_NUM_ID   or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = FB_DLY_ID       or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = RET_DATA_S_ID   or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = ADC_OFFSET_0_ID or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = ADC_OFFSET_1_ID or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = GAIN_0_ID       or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = GAIN_1_ID       or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = DATA_RATE_ID    or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = NUM_COLS_REP_ID or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = SA_FB_ID        or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = SQ1_BIAS_ID     or
                                    to_integer(unsigned(param_id_reg(7 downto 0))) = SQ1_FB_ID       else
                           '0';

end behave;