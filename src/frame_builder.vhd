----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.08.2022
-- Module Name: frame_builder.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of receiving the data from the different channels and building the data
--              frame packets. It is flexible enough to be able to adapt to different channels and rows. 
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

entity frame_builder is
    port(
        clk                     : in std_logic; -- 5MHz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        -- Param buffers
        ret_data_setup          : in t_param_array(0 to PARAM_ID_TO_SIZE(to_integer(RET_DATA_S_ID)) - 1);
        data_rate               : in unsigned(bits_req(MAX_DATA_RATE) - 1 downto 0); -- Refers to the ratio between the number of frames discarted and the ones thrown
        num_rows                : in unsigned(bits_req(MAX_ROWS) - 1 downto 0);
        num_cols                : in unsigned(bits_req(MAX_CHANNELS) - 1 downto 0);
        row_len                 : in unsigned(bits_req(MAX_ROW_LEN) - 1 downto 0);

        -- Interface with cmd handler and row selector
        acquisition_on          : in std_logic;
        stop_received           : in std_logic;
        frame_active            : in std_logic;
        last_frame_sent         : out std_logic;

        -- Interface with channels
        channels_data           : in t_channel_record_array;

        -- Interface with packet sender
        sender_ready            : in std_logic;
        send_data_packet        : out std_logic;
        payload_size            : out unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0);
        frame_payload           : out t_packet_payload -- Composed by the header_payload + data_payload
    );

end frame_builder;

architecture behave of frame_builder is

    constant HEADER_VERSION : natural := 7;

    type stateType is (idle, wait_valid_data, update_payload_state, wait_sender_ready, send_data, wait_acq_off);
    signal state : stateType;

    type t_header_payload is array (0 to (DATA_PKT_HEADER_SIZE - 1)) of t_word;
    type t_data_payload is array (0 to (MAX_CHANNELS * MAX_ROWS - 1)) of t_word;

    signal header_payload   : t_header_payload := (others => (others => '0'));
    signal data_payload     : t_data_payload := (others => (others => '0'));

    signal channels_data_reg : t_channel_record_array := (others => (value => (others => '0'), row_num => (others => '0'), valid => '0'));
    signal valid_data           : std_logic := '0';
    signal valid_data_reg       : std_logic := '0';
    signal last_frame           : std_logic := '0';
    signal row_counter          : unsigned(bits_req(MAX_ROWS - 1) - 1 downto 0) := (others => '0');
    signal initial_id           : unsigned(FRAME_ID_WIDTH - 1 downto 0) := (others => '0'); -- The first frame will have this id
    signal final_id             : unsigned(FRAME_ID_WIDTH - 1 downto 0) := (others => '0'); -- The last frame will have this id
    signal frame_id             : unsigned(FRAME_ID_WIDTH - 1 downto 0) := (others => '0'); -- The current frame_id (starts at initial_id)
    signal frame_counter        : unsigned(data_rate'range)   := (others => '0'); -- Counter for the current sent frames (starts at 0 ends at data rate)
    signal total_frame_counter  : unsigned(FRAME_ID_WIDTH - 1 downto 0)   := (others => '0'); -- Counter for the current total sent frames (starts at 0 ends when acquisition is over)
    signal valid_row            : std_logic := '0'; -- Signal that indicates that the row_counter is sync whith the current row,
                                                    -- if not we discard the current frame that has already started and wait until the next one starts
    signal update_payload       : std_logic := '0';
    signal update_status_bits   : std_logic := '0';


    -- Header needed signals
    signal stop_bit         : std_logic := '0';

begin

-- Simple assigments
initial_id <= resize(unsigned(ret_data_setup(0)), initial_id'length);
final_id <= resize(unsigned(ret_data_setup(1)), final_id'length);
last_frame <= '1' when frame_id = final_id or stop_bit = '1' else '0';
payload_size <= to_unsigned(t_header_payload'length + to_integer(num_cols) * to_integer(num_rows), payload_size'length);

-- State machine logic
main_logic : process(clk, rst)
begin
    if (rst = '1') then
        send_data_packet <= '0';
        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                last_frame_sent <= '0';
                if (acquisition_on = '1') then
                    frame_id <= initial_id;
                    state <= wait_valid_data;
                else
                    state <= state;
                end if;

            when wait_valid_data =>
                    update_payload <= '0';
                    -- Sync with the actual row, to send only complete frames
                    if (valid_data_reg = '1' and valid_row = '1') then
                            update_payload <= '1';
                            state <= update_payload_state;
                    end if;

            when update_payload_state =>
                update_payload <= '0';
                -- Valid frame
                if (row_counter = num_rows - 1) then
                    row_counter <= (others => '0');
                    total_frame_counter <= total_frame_counter + 1;
                    -- We only send #data_rate valid frames
                    if (frame_counter = data_rate - 1) then
                        frame_counter <= (others => '0');
                        if (sender_ready = '1') then
                            send_data_packet <= '1';
                            state <= send_data;
                        else
                            state <= wait_sender_ready;
                        end if;
                    else
                        frame_counter <= frame_counter + 1;
                        state <= wait_valid_data;
                    end if;
                else
                    row_counter <= row_counter + 1;
                    state <= wait_valid_data;
                end if;

            when wait_sender_ready =>
                if (sender_ready = '1') then
                    send_data_packet <= '1';
                    state <= send_data;
                else
                    state <= wait_sender_ready;
                end if;

            when send_data =>
                send_data_packet <= '0';
                if (last_frame = '1') then
                    last_frame_sent <= '1';
                    total_frame_counter <= (others => '0');
                    frame_id <= initial_id;
                    state <= wait_acq_off;
                else
                    frame_id <= frame_id + 1;
                    state <= wait_valid_data;
                end if;
            
            when wait_acq_off =>
                if (acquisition_on = '0') then
                    last_frame_sent <= '0';
                    state <= idle;
                end if;

            when others =>
                state <= idle;
        end case;
    end if;
end process;

-- Store channels data in internal register
process(clk, rst)
begin
    if (rst = '1') then
        channels_data_reg <= (others => (value => (others => '0'), row_num => (others => '0'), valid => '0'));
    elsif (rising_edge(clk)) then
        valid_data_reg <= valid_data;

        if (valid_data = '1') then
            channels_data_reg <= channels_data;
        end if;
    end if;
end process;

-- Valid data signal generation
process(channels_data)
begin
    valid_data <= '0';
    -- We determine that the data is valid when all channels report valid data. This should always occur as they
    -- are parallel, if not something is wrong
    if (num_cols = 0) then
        valid_data <= '0';
    elsif (num_cols = 1) then
        valid_data <= channels_data(0).valid;
    elsif (num_cols >= 2) then
        for i in 0 to (MAX_CHANNELS - 2) loop
            if (i = 0) then
                valid_data <= channels_data(i).valid and channels_data(i+1).valid;
            elsif (i <= num_cols - 2) then
                valid_data <= valid_data and channels_data(i+1).valid;
            end if;
        end loop;
    end if;
end process;

-- Stop bit signal generation
process(clk, rst)
begin
    if (rst = '1') then
        stop_bit <= '0';
    elsif (rising_edge(clk)) then
        update_status_bits <= '0';

        if (stop_received = '1') then
            stop_bit <= '1';
            update_status_bits <= '1';
        end if;
        -- We start a new acquisition, restart stop bit
        if (state = idle) then
            stop_bit <= '0';
        end if;
    end if;
end process;

-- Valid row generation
process(row_counter, channels_data_reg)
begin
    valid_row <= '0';
    for i in 0 to (MAX_CHANNELS - 1) loop
        if (i < num_cols) then
            if (i = 0) then
                if (row_counter = channels_data_reg(i).row_num) then
                    valid_row <= '1';
                else
                    valid_row <= '0';
                end if;
            else
                if (row_counter /= channels_data_reg(i).row_num) then
                    valid_row <= '0';
                end if;
            end if;
        end if;
    end loop;
end process;

-- Frame payload assigment = header_payload + data_payload
process(header_payload, data_payload)
begin
    for i in 0 to frame_payload'length - 1 loop
        if (i < t_header_payload'length) then
            frame_payload(i) <= header_payload(i);
        else
            frame_payload(i) <= data_payload(i-t_header_payload'length);
        end if;
    end loop;
end process;

-- Data payload assignment from each channel data
process(clk, rst)
begin
    if (rst = '1') then
        data_payload <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
        if (update_payload = '1') then
            -- We assign all channels even if they do not report their data. Is later through the size of the frame where 
            -- we decide which data to report
            for i in 0 to (MAX_CHANNELS - 1) loop
                data_payload((i * to_integer(num_rows)) + to_integer(channels_data_reg(i).row_num)) <= std_logic_vector(channels_data_reg(i).value);
            end loop;
        end if;
    end if;
end process;

-- Header payload assigment
process(clk, rst)
begin
    if (rst = '1') then
        header_payload <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
        -- Special case, as the stop can be received any time, we must be able to trigger the update at any time
        if (update_status_bits = '1') then
            -- (0) Status bits
            header_payload(0)(1 downto 0) <= stop_bit & last_frame;
        end if;

        -- General update triggered for each valid data
        if (update_payload = '1') then
            -- (0) Status bits
            header_payload(0)(1 downto 0) <= stop_bit & last_frame;
            -- (1) Frame id
            header_payload(1) <= std_logic_vector(resize(frame_id, t_word'length));
            -- (2) row_len
            header_payload(2) <= std_logic_vector(resize(row_len, t_word'length));
            -- (3) num_rows reported
            header_payload(3) <= std_logic_vector(resize(num_rows, t_word'length));
            -- (4) data_rate
            header_payload(4) <= std_logic_vector(resize(data_rate, t_word'length));
            -- (5) total_frame_counter
            header_payload(5) <= std_logic_vector(resize(total_frame_counter, t_word'length));
            -- (6) Header version
            header_payload(6) <= std_logic_vector(to_unsigned(header_version, t_word'length));
            -- (7) ramp value (current value if ramp mode is active) (TODO)
            header_payload(7) <= (others => '0');
            -- (8) ramp card addr and param id (TODO)
            header_payload(8) <= (others => '0');
            -- (9) num_rows
            header_payload(9) <= std_logic_vector(to_unsigned(MAX_ROWS, t_word'length));
            -- (10) sync box number (doesn't apply)
            -- (11) run_id (don't implemented)
            -- (12) user_word (don't implemented)
            -- (13) errno (doesn't apply)
            -- (14) temperature AC (doesn't apply)
            -- (15) FPGA Temperature, BC1 (doesn't apply)
            -- (16) FPGA Temperature, BC2 (doesn't apply)
            -- (17) FPGA Temperature, BC3 (doesn't apply)
            -- (18) FPGA Temperature, RC1 (doesn't apply)
            -- (19) FPGA Temperature, RC2 (doesn't apply)
            -- (20) FPGA Temperature, RC3 (doesn't apply)
            -- (21) FPGA Temperature, RC4 (doesn't apply)
            -- (22) FPGA Temperature, CC (doesn't apply)
            -- (23) errno (doesn't apply)
            -- (24) Card Temperature, AC (doesn't apply)
            -- (25) Card Temperature, BC1 (doesn't apply)
            -- (26) Card Temperature, BC2 (doesn't apply)
            -- (27) Card Temperature, BC3 (doesn't apply)
            -- (28) Card Temperature, RC1 (doesn't apply)
            -- (29) Card Temperature, RC2 (doesn't apply)
            -- (30) Card Temperature, RC3 (doesn't apply)
            -- (31) Card Temperature, RC4 (doesn't apply)
            -- (32) Card Temperature, CC (doesn't apply)
            -- (33) errno (doesn't apply)
            -- (34)(35)(36)(37)(38)(39)(40)(41) Reserved
            -- (41) errno (doesn't apply)
            -- (42) box_temp (doesn't apply)
        end if;
    end if;
end process;

end behave;