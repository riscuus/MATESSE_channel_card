----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/24/2022
-- Module Name: tb_integration.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench for testing the integration of the different modules in the architecture. The idea is to
--              analyze the good behaviour among the different interfaces. We don't include the uart modules
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

entity tb_integration is
end tb_integration;

architecture Behavioral of tb_integration is

    -- Constants
    constant T_HALF_CLK_100         : time := 5 ns;
    constant T_HALF_CLK_5           : time := 100 ns;
    constant RST_START              : time := 32 ns;
    constant RST_PULSE_LENGTH       : time := 300 ns;
    constant PARAMS_VALID_START     : time := 300 ns; 
    constant DATA_SETUP             : time := 200 ns;
    constant PARAMS_VALID_HIGH      : time := 200 ns;
    constant PACKET_DELAY           : time := 1500 us; -- Time between trying a new packet
    constant PARAMS_VALID_TIMEOUT   : time := 2000 us;
    constant SIM_DURATION           : time := 200 ms;

    -- Clock
    signal sys_clk_100  : std_logic;
    signal sys_clk_5    : std_logic;
    signal sys_rst      : std_logic;

    -- External
    signal sync_frame : std_logic := '0';
    
    -- PC packet builder
    signal PC_packet_type       : t_packet_type := undefined;
    signal PC_card_id           : t_half_word := (others => '0');
    signal PC_param_id          : t_half_word := (others => '0');
    signal PC_cmd_type          : t_packet_type := undefined;
    signal PC_err_ok            : std_logic := '0';
    signal PC_payload_size      : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal PC_packet_payload    : t_packet_payload := (others => (others => '0'));
    signal PC_params_valid      : std_logic := '0';
    signal PC_send_byte         : std_logic := '0';
    signal PC_builder_ready     : std_logic := '0';

    -- PC packet parser
    signal PC_parser_packet_type    : t_packet_type := undefined;
    signal PC_parser_card_id        : t_half_word := (others => '0');
    signal PC_parser_param_id       : t_half_word := (others => '0');
    signal PC_parser_cmd_type       : t_packet_type := undefined;
    signal PC_parser_err_ok         : std_logic := '0';
    signal PC_parser_payload_size   : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal PC_parser_packet_payload : t_packet_payload := (others => (others => '0'));
    signal PC_parser_params_valid   : std_logic := '0';

    -- PC uart module <-> FPGA RX uart module
    signal PC_to_FPGA_uart_serial   : std_logic := '0';
    signal FPGA_to_PC_uart_serial   : std_logic := '0';
    signal PC_rx_busy               : std_logic := '0';
    signal PC_rx_byte_data          : t_byte := (others => '0');
    signal PC_tx_busy               : std_logic := '0';
    signal PC_tx_byte_data          : t_byte := (others => '0');

    -- ADC signals
    type t_16_bit_data_array is array(0 to MAX_CHANNELS - 1) of std_logic_vector(ADC_DATA_SIZE - 1 downto 0);
    signal adc_sim_data     : t_16_bit_data_array := (others => (others => '0'));
    signal ADC_SDO_vector   : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');
    signal ADC_SCK          : std_logic := '0';
    signal ADC_CNV          : std_logic := '0';

    ---------------------------------------------------------------------------
    -- Internal signals to assert tests
    ---------------------------------------------------------------------------
    -- Types
    type t_sample_sum is array (0 to MAX_CHANNELS - 1) of t_word;

    type t_data_payload is array (0 to (MAX_CHANNELS * MAX_ROWS - 1)) of t_word;

    type t_packet_record is record
        num                 : integer;
        packet_type         : t_packet_type;
        card_id             : t_half_word;
        param_id            : unsigned(PARAM_ID_WIDTH - 1 downto 0);
        payload_size        : natural;
        packet_payload      : t_packet_payload;
    end record;

    -- packet_parser module
    signal parser_params_valid      : std_logic := '0';
    signal parser_packet_type       : t_packet_type := undefined;
    signal parser_card_id           : t_half_word := (others => '0');
    signal parser_param_id          : t_half_word := (others => '0');
    signal parser_payload_size      : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal parser_packet_payload    : t_packet_payload := (others => (others => '0'));
    -- cmd_handler module
    signal send_reply_pulse        : std_logic := '0';
    -- packet sender
    signal sender_params_valid  : std_logic := '0';
    -- packet builder module
    signal builder_packet_type  : t_packet_type := undefined;
    signal builder_card_id      : t_half_word := (others => '0');
    signal builder_param_id     : t_half_word := (others => '0');
    signal builder_cmd_type     : t_packet_type := undefined;
    signal builder_err_ok       : std_logic := '0';
    signal builder_payload_size : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal builder_payload      : t_packet_payload := (others => (others => '0'));
    -- row selector
    signal new_row              : std_logic := '0';
    signal row_num              : unsigned(bits_req(MAX_ROWS - 1) - 1 downto 0)   := (others => '0');

    -- buffers
    signal data_rate        : t_param_array(0 to PARAM_ID_TO_SIZE(DATA_RATE_ID) - 1) := (others => (others => '0'));
    signal num_rows         : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_ROWS_ID) - 1) := (others => (others => '0'));
    signal num_cols         : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_COLS_REP_ID) - 1) := (others => (others => '0'));
    signal sample_dly       : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_DLY_ID) - 1) := (others => (others => '0'));
    signal sample_num       : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_NUM_ID) - 1) := (others => (others => '0'));
    signal gain_0           : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_0_ID) - 1) := (others => (others => '0'));
    signal gain_1           : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_1_ID) - 1) := (others => (others => '0'));

    signal data_rate_int    : natural := 0;
    signal num_rows_int     : natural := 0;
    signal num_cols_int     : natural := 0;
    signal sample_num_int   : natural := 0;
    signal sample_dly_int   : natural := 0;

    type t_gain_array is array(0 to MAX_CHANNELS - 1) of natural;
    signal fb_gain : t_gain_array := (others => 0);

    -- send_packet_async signals
    signal send_packet_async_trigger    : std_logic := '0';
    signal async_packet                 : t_packet_record := (num => 0, packet_type => undefined, card_id => (others => '0'), param_id => (others => '0'), payload_size => 0, packet_payload => (others => (others => '0')));
    signal async_delay                  : time;

    -- check packet ignored async 
    signal check_packet_ignored_async_packet    : t_packet_record := (num => 0, packet_type => undefined, card_id => (others => '0'), param_id => (others => '0'), payload_size => 0, packet_payload => (others => (others => '0')));
    signal check_packet_ignored_async_trigger   : std_logic := '0';
    -- check_packet_data signals
    signal calc_data_packet : std_logic := '0';
    signal data_packet_calculated : std_logic := '0';

    signal frame_count      : natural := 0;
    signal row_count        : natural := 0;
    signal discard_count    : natural := 0;
    signal sample_count     : natural := 0;
    signal packets_checked  : natural := 0;

    signal sample_sum : t_sample_sum := (others => (others => '0'));

    signal calc_data_payload        : t_packet_payload := (others => (others => '0'));
    signal calc_data_payload_buffer : t_packet_payload := (others => (others => '0'));

    -- check_reply_ok_async signals
    signal reply_ok_async               : t_packet_record := (num => 0, packet_type => undefined, card_id => (others => '0'), param_id => (others => '0'), payload_size => 0, packet_payload => (others => (others => '0')));
    signal reply_ok_async_data_to_read  : t_packet_payload := (others => (others => '0'));
    signal reply_ok_async_data_length   : natural := 0;
    signal check_reply_ok_signal        : std_logic := '0';

    ---------------------------------------------------------------------------
    -- Check procedures
    ---------------------------------------------------------------------------
    procedure send_packet(
        packet                     : in t_packet_record;

        signal PC_packet_type      : out t_packet_type;
        signal PC_card_id          : out t_half_word;
        signal PC_param_id         : out t_half_word;
        signal PC_payload_size     : out unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0);
        signal PC_packet_payload   : out t_packet_payload;
        signal PC_params_valid     : out std_logic) is

    begin
        wait for PACKET_DELAY;
        --wait until rising_edge(sys_clk_5);

        PC_packet_type      <= packet.packet_type;
        PC_card_id          <= packet.card_id;
        PC_param_id         <= std_logic_vector(resize(packet.param_id, PC_param_id'length));
        PC_payload_size     <= to_unsigned(packet.payload_size, PC_payload_size'length);
        PC_packet_payload   <= packet.packet_payload;

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';

    end procedure;

    procedure send_packet_async(
        packet                              : in t_packet_record;
        delay                               : in time;

        signal async_packet                 : out t_packet_record;
        signal async_delay                  : out time;
        signal send_packet_async_trigger    : out std_logic
        ) is
    begin
        async_packet <= packet;
        async_delay <= delay;
        send_packet_async_trigger <= '1';
        wait for 1 ps;
        send_packet_async_trigger <= '0';
        wait for 1 ps;
    end procedure;

    procedure check_packet_received(
        packet  : in t_packet_record) is
    begin
        wait until parser_params_valid = '1';

        assert packet.packet_type = parser_packet_type report "[PACKET " & integer'image(packet.num) & "] Received wrong packet type";
        assert packet.card_id = parser_card_id report "[PACKET " & integer'image(packet.num) & "] Received wrong card id";
        assert std_logic_vector(resize(packet.param_id, PC_param_id'length)) = parser_param_id report "[PACKET " & integer'image(packet.num) & "] Wrong param id";
        assert to_unsigned(packet.payload_size, PC_payload_size'length) = parser_payload_size report "[PACKET " & integer'image(packet.num) & "] Wrong payload size";
        assert packet.packet_payload = parser_packet_payload report "[PACKET " & integer'image(packet.num) & "] Wrong packet payload";

    end procedure;

    procedure check_packet_ignored(
        packet  : in t_packet_record) is
    begin
        wait until send_reply_pulse = '1' for 100 us;
        assert send_reply_pulse = '0' report "Packet not ignored num: " & integer'image(packet.num);
    end procedure;

    procedure check_packet_ignored_async(packet : in t_packet_record; signal check_packet_ignored_async_packet : out t_packet_record; signal check_packet_ignored_async_trigger : out std_logic) is
    begin
        check_packet_ignored_async_packet <= packet;
        check_packet_ignored_async_trigger <= '1';
        wait for 1 ps;
        check_packet_ignored_async_trigger <= '0';
        wait for 1 ps;
    end procedure;


    procedure check_parser_ignored_packet(packet : in t_packet_record) is
    begin
        wait until parser_params_valid = '1' for 2 ms;
        assert parser_params_valid = '0' report "Packet not ignored";
    end procedure;

    procedure check_reply_error(packet : in t_packet_record) is
    begin
        wait until PC_parser_params_valid = '1';
        assert PC_parser_params_valid = '1' report "No reply received";

        assert PC_parser_packet_type = reply report "Wrong packet type";
        assert PC_parser_card_id = DAUGHTER_CARD_ID report "Wrong card id";
        assert PC_parser_param_id = std_logic_vector(resize(packet.param_id, builder_param_id'length)) report "Wrong param id (Expected: " & integer'image(to_integer(unsigned(builder_param_id))) & ", Received: " & integer'image(to_integer(unsigned(std_logic_vector(resize(packet.param_id, builder_param_id'length))))) & ")";
        assert PC_parser_cmd_type = packet.packet_type report "Wrong cmd_type";
        assert PC_parser_err_ok = '1' report "Reply error bit not set";
        assert PC_parser_payload_size = to_unsigned(1, builder_payload_size'length) report "Wrong payload size";
        --assert builder_payload CHECK ERROR CODES
    end procedure;

    procedure check_reply_ok(packet : in t_packet_record; data_to_read : in t_packet_payload := (others => (others => '0')); data_length : in natural := 0 ) is
        variable empty_word : t_word := (others => '0');
    begin
        wait until PC_parser_params_valid = '1';
        assert PC_parser_params_valid = '1' report "No reply received";

        assert PC_parser_packet_type = reply report "Wrong packet type";
        assert PC_parser_card_id = DAUGHTER_CARD_ID report "Wrong card id";
        assert PC_parser_param_id = std_logic_vector(resize(packet.param_id, PC_parser_param_id'length)) report "Wrong param id (Expected: " & integer'image(to_integer(unsigned(builder_param_id))) & ", Received: " & integer'image(to_integer(unsigned(std_logic_vector(resize(packet.param_id, builder_param_id'length))))) & ")";
        assert PC_parser_cmd_type = packet.packet_type report "Wrong cmd_type";
        assert PC_parser_err_ok = '0' report "Reply error bit set";
        if(packet.packet_type = cmd_wb or packet.packet_type = cmd_st) then
            assert PC_parser_payload_size = to_unsigned(1, builder_payload_size'length) report "Wrong payload size";
            assert PC_parser_packet_payload(0) = empty_word report "Reply payload is not empty";
        elsif (packet.packet_type = cmd_rb) then
            assert PC_parser_payload_size = to_unsigned(data_length, builder_payload_size'length) report "Wrong payload size";
            for i in 0 to data_length - 1 loop
                assert PC_parser_packet_payload(i) = data_to_read(i) report "Reply payload data is not correct (word " & integer'image(i) & ") (Expected: " & integer'image(to_integer(signed(data_to_read(i)))) & ", Received: " & integer'image(to_integer(signed(PC_parser_packet_payload(i))));
            end loop;
        end if;
    end procedure;

    procedure check_reply_ok_async(packet                               : in t_packet_record; 
                                   data_to_read                         : in t_packet_payload := (others => (others => '0')); 
                                   data_length                          : in natural := 0; 
                                   signal reply_ok_async                : out t_packet_record;
                                   signal reply_ok_async_data_to_read   : out t_packet_payload;
                                   signal reply_ok_async_data_length    : out natural;
                                   signal check_reply_ok_signal         : out std_logic
                                  ) is
    begin
        reply_ok_async <= packet;
        reply_ok_async_data_to_read <= data_to_read;
        reply_ok_async_data_length <= data_length;
        check_reply_ok_signal <= '1';
        wait for 1 ps;
        check_reply_ok_signal <= '0';
        wait for 1 ps;
    end procedure;


    procedure check_data_packets(num_packets                : in natural; 
                                 signal calc_data_packet    : out std_logic; 
                                 signal calc_data_payload   : out t_packet_payload
                                ) is
        variable packets_checked    : natural := 0;
        variable payload_size       : natural := 0;
    begin
        while packets_checked < num_packets loop

            if (packets_checked = 0) then -- special case for the 1st packets
                calc_data_packet <= '1';
                wait until data_packet_calculated = '1';
                calc_data_packet <= '0';
                wait for 1 ps;
            end if;

            calc_data_payload <= calc_data_payload_buffer;
            wait for 1 ps;

            if (packets_checked < num_packets - 1) then
                calc_data_packet <= '1';
                wait until data_packet_calculated = '1';
                calc_data_packet <= '0';
                wait for 1 ps;
            end if;

            wait until PC_parser_params_valid = '1' for 2 ms; 
            assert PC_parser_params_valid = '1' report "PC params valid timeout 1";
            if (PC_parser_packet_type = reply) then -- We must discard the reply packet in some situations
                wait until PC_parser_params_valid = '1' for 2 ms;
                assert PC_parser_params_valid = '1' report "PC params valid timeout 2";
            end if;


            payload_size := DATA_PKT_HEADER_SIZE + num_cols_int * num_rows_int;
            assert PC_parser_packet_type = data report "Wrong packet type (Expected: data, Received: " & t_packet_type'image(PC_parser_packet_type) & ")";
            assert PC_parser_card_id = DAUGHTER_CARD_ID report "Wrong card id";
            assert PC_parser_payload_size = to_unsigned(payload_size, PC_parser_payload_size'length) report "Wrong payload size (Expected: " & integer'image(payload_size) & ", Received: " & integer'image(to_integer(PC_parser_payload_size));
            for i in 0 to num_cols_int * num_rows_int - 1 loop
                assert PC_parser_packet_payload(DATA_PKT_HEADER_SIZE + i) = calc_data_payload(i) report "Wrong data payload (row " & integer'image(i) & ") (Expected: " & integer'image(to_integer(signed(calc_data_payload(i)))) & ", Received: " & integer'image(to_integer(signed(PC_parser_packet_payload(DATA_PKT_HEADER_SIZE + i))));
            end loop;
            report "Checked data packet: " & integer'image(packets_checked);
            packets_checked := packets_checked + 1;
        end loop;
    end procedure;

    procedure check_good_stop(packet : in t_packet_record; last_frame_id : in natural) is
        variable stop_loop : std_logic := '0';
    begin
        stop_loop := '0';
        while stop_loop = '0' loop
            wait until PC_parser_params_valid = '1';
            if (PC_parser_packet_type = data) then
                -- The last data frame must have the stop_bit and last_frame set. It needs also to have an id smaller than the real last one
                if (PC_parser_packet_payload(0)(1 downto 0) = "11" and to_integer(unsigned(PC_parser_packet_payload(1))) < last_frame_id) then
                    stop_loop := '1';
                end if;
            else
                report "Wrong stop" severity error;
                stop_loop := '1';
            end if;
            wait for 1 ps;
        end loop;
        -- After the last data frame we must receive a reply packet
        check_reply_ok(packet, (others => (others => '0')), 0);
    end procedure;

begin

    -- 100 CLK generation
    clk_100_generation : process 
    begin
        sys_clk_100 <= '1';
        wait for T_HALF_CLK_100; 
        sys_clk_100 <= '0';
        wait for T_HALF_CLK_100;
    end process;

    -- 5 CLK generation
    clk_5_generation : process 
    begin
        sys_clk_5 <= '1';
        wait for T_HALF_CLK_5; 
        sys_clk_5 <= '0';
        wait for T_HALF_CLK_5;
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

    -- Sync frame generation
    sync_frame_generaiton : process
    begin
        sync_frame <= '0';
        wait for 51 * 12 * 2 * T_HALF_CLK_5;
        sync_frame <= '1';
        wait for 2 * T_HALF_CLK_5;

    end process;

    -- ADC data generation
    adc_sim_data_gen : process
    begin
        adc_sim_data(0) <= std_logic_vector(unsigned(adc_sim_data(0)) + 1);
        adc_sim_data(1) <= std_logic_vector(unsigned(adc_sim_data(1)) + 2);
        if (unsigned(adc_sim_data(0)) = to_unsigned(20, adc_sim_data(0)'length)) then
            adc_sim_data <= (others => (others => '0'));
        end if;
        wait for 20 us;
    end process;

    ---------------------------------------------------------------------------
    -- Check processes
    ---------------------------------------------------------------------------
    
    check_packet_ignored_async_process : process
    begin
        wait until check_packet_ignored_async_trigger = '1';
        check_packet_ignored(check_packet_ignored_async_packet);
    end process;

    check_reply_ok_background_process : process
    begin
        wait until check_reply_ok_signal = '1';
        check_reply_ok(reply_ok_async, reply_ok_async_data_to_read, reply_ok_async_data_length);
    end process;

    calculate_data_packet : process
    begin
        wait until calc_data_packet = '1';
        data_packet_calculated <= '0';

        while frame_count < data_rate_int loop 
            -- sync with row 0
            if (row_num /= 0) then
                wait until row_num = 0;
            end if;
            while row_count < num_rows_int loop
                wait until new_row = '1';
                -- Discard sample_dly samples
                while discard_count < sample_dly_int loop
                    wait until ADC_CNV = '1';
                    discard_count <= discard_count + 1;
                    wait for 1 ps;
                end loop;
                discard_count <= 0;
                -- Sum sample_num samples
                while sample_count < sample_num_int loop
                    wait until ADC_CNV = '1';
                    sample_count <= sample_count + 1;
                    for i in 0 to MAX_CHANNELS - 1 loop
                        sample_sum(i) <= std_logic_vector(unsigned(sample_sum(i)) + resize(unsigned(adc_sim_data(i)), sample_sum(i)'length));
                    end loop;
                    wait for 1 ps;
                end loop;
                -- Calculate feedback
                for i in 0 to MAX_CHANNELS - 1 loop
                    calc_data_payload_buffer((i * num_rows_int) + row_count) <= std_logic_vector(to_signed(to_integer(signed(sample_sum(i))) * fb_gain(i), t_word'length));
                end loop;
                sample_sum <= (others => (others => '0'));
                sample_count <= 0;
                row_count <= row_count + 1;
                wait on row_count, frame_count;
            end loop;
            row_count <= 0;
            frame_count <= frame_count + 1;
            wait on row_count, frame_count;
        end loop;
        frame_count <= 0;
        data_packet_calculated <= '1';
        wait on data_packet_calculated;
    end process;

    -- (PC) TX packet builder
    PC_builder_module : entity concept.packet_builder
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,

            packet_type     => PC_packet_type,
            card_id         => PC_card_id,
            param_id        => PC_param_id,
            cmd_type        => PC_cmd_type,
            err_ok          => PC_err_ok,
            payload_size    => PC_payload_size,
            packet_payload  => PC_packet_payload,
                       
            params_valid    => PC_params_valid,
            tx_busy         => PC_tx_busy,
            send_byte       => PC_send_byte,
            byte_data       => PC_tx_byte_data,
            builder_ready   => PC_builder_ready
        );

    -- (PC) Packet parser
    PC_packet_parser : entity concept.packet_parser
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,

            packet_type     => PC_parser_packet_type,
            card_id         => PC_parser_card_id,
            param_id        => PC_parser_param_id,
            cmd_type        => PC_parser_cmd_type,
            err_ok          => PC_parser_err_ok,
            payload_size    => PC_parser_payload_size,
            packet_payload  => PC_parser_packet_payload,

            rx_busy         => PC_rx_busy,
            byte_data       => PC_rx_byte_data,
            params_valid    => PC_parser_params_valid
        );
    -- (PC) TX uart module
    PC_uart_module : entity concept.uart_controller
        port map(
            clk          => sys_clk_100,
            rst          => sys_rst,

            tx_ena       => PC_send_byte,
            tx_data      => PC_tx_byte_data,
            rx           => FPGA_to_PC_uart_serial,
            rx_busy      => PC_rx_busy,
            rx_error     => open,
            rx_data      => PC_rx_byte_data,
            tx_busy      => PC_tx_busy,
            tx           => PC_to_FPGA_uart_serial
        );

    ADC_simulators : for i in 0 to MAX_CHANNELS - 1 generate
        ADC_simulator : entity concept.ADC_simulator
            port map(
                clk     => sys_clk_100,
                rst     => sys_rst,

                nCNV    => ADC_CNV,
                SCK     => ADC_SCK,
                SDO     => ADC_SDO_vector(i),
                data    => adc_sim_data(i)
            );
    end generate;

    
    main_module : entity concept.main_module
        port map(
            sys_clk_5               => sys_clk_5,
            sys_clk_100             => sys_clk_100,
            sys_rst                 => sys_rst,

            -- UART interface
            rx_uart_serial          => PC_to_FPGA_uart_serial,
            tx_uart_serial          => FPGA_to_PC_uart_serial,

            -- row_activator DACS interface
            sync_frame              => sync_frame,
            row_activator_DAC_CS_0  => open, 
            row_activator_DAC_CS_1  => open,
            row_activator_DAC_CS_2  => open,
            row_activator_DAC_CLK   => open,
            row_activator_DAC_LDAC  => open,

            -- TES bias DAC interface
            TES_bias_DAC_CS         => open,
            TES_bias_DAC_CLK        => open,
            TES_bias_DAC_LDAC       => open,
            
            -- Channels DAC interface
            channels_DAC_CS         => open,
            channels_DAC_CLK        => open,
            channels_DAC_LDAC       => open,
            channels_DAC_SDI_0      => open,
            channels_DAC_SDI_1      => open,

            -- ADC interface
            ADC_CNV                 => ADC_CNV,
            ADC_SCK                 => ADC_SCK,
            ADC_CLKOUT              => ADC_SCK,
            ADC_SDO_0               => ADC_SDO_vector(0),
            ADC_SDO_1               => ADC_SDO_vector(1)
        );

    
    --PC_params_valid 
    --parser_params_valid <= <<signal main_module.parser_params_valid : std_logic>>;

    -- Packet parser
    parser_params_valid   <= <<signal main_module.parser_params_valid       : std_logic>>;
    parser_packet_type    <= <<signal main_module.parser_packet_type        : t_packet_type>>;
    parser_card_id        <= <<signal main_module.parser_card_id            : t_half_word>>;
    parser_param_id       <= <<signal main_module.parser_param_id           : t_half_word>>;
    parser_payload_size   <= <<signal main_module.parser_payload_size       : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0)>>;
    parser_packet_payload <= <<signal main_module.parser_packet_payload     : t_packet_payload>>;
    -- cmd_handler
    send_reply_pulse        <= <<signal main_module.send_reply_pulse        : std_logic>>;
    -- packet sender
    sender_params_valid     <= <<signal main_module.params_valid            : std_logic>>;
    -- packet_builder
    builder_packet_type     <= <<signal main_module.packet_type             : t_packet_type>>;
    builder_card_id         <= <<signal main_module.card_id                 : t_half_word>>;
    builder_param_id        <= <<signal main_module.param_id                : t_half_word>>;
    builder_cmd_type        <= <<signal main_module.cmd_type                : t_packet_type>>;
    builder_err_ok          <= <<signal main_module.err_ok                  : std_logic>>;
    builder_payload_size    <= <<signal main_module.payload_size            : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0)>>;
    builder_payload         <= <<signal main_module.packet_payload          : t_packet_payload>>;
    --row_selector
    new_row                 <= <<signal main_module.new_row                 : std_logic>>;
    row_num                 <= <<signal main_module.row_num                 : unsigned(bits_req(MAX_ROWS - 1) - 1 downto 0)>>;
    --buffers
    data_rate               <= <<signal main_module.data_rate    : t_param_array(0 to PARAM_ID_TO_SIZE(DATA_RATE_ID) - 1)>>;
    num_rows                <= <<signal main_module.num_rows     : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_ROWS_ID) - 1)>>;
    num_cols                <= <<signal main_module.num_cols     : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_COLS_REP_ID) - 1)>>;
    sample_num              <= <<signal main_module.sample_num   : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_NUM_ID) - 1)>>;
    sample_dly              <= <<signal main_module.sample_dly   : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_DLY_ID) - 1)>>;
    gain_0                  <= <<signal main_module.gain_0       : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_0_ID) - 1)>>;
    gain_1                  <= <<signal main_module.gain_1       : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_1_ID) - 1)>>;

    data_rate_int           <= to_integer(unsigned(data_rate(0)));
    num_rows_int            <= to_integer(unsigned(num_rows(0)));
    num_cols_int            <= to_integer(unsigned(num_cols(0)));
    sample_num_int          <= to_integer(unsigned(sample_num(0)));
    sample_dly_int          <= to_integer(unsigned(sample_dly(0)));
    fb_gain(0)              <= to_integer(unsigned(gain_0(0)));
    fb_gain(1)              <= to_integer(unsigned(gain_1(0)));

    -- Stimulus generation
    stimulus_generation: process
        -- #1: wrong card_id
        variable packet_1 : t_packet_record := (1, packet_type => cmd_wb, card_id => x"0f0f", param_id => x"ff", payload_size => 2, packet_payload => (others => (others => '0')));
        -- #2: wrong packet_type (we cmd_handler only accepts commands)
        variable packet_2 : t_packet_record := (2, packet_type => reply, card_id => DAUGHTER_CARD_ID, param_id => x"ff", payload_size => 2, packet_payload => (others => (others => '0')));
        -- #3: wrong param_id
        variable packet_3 : t_packet_record := (3, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => x"ff", payload_size => 2, packet_payload => (others => (others => '0')));
        -- #4: Wrong payload size (parser will not accept 0 length payload)
        variable packet_4 : t_packet_record := (4,packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(ON_BIAS_ID, PARAM_ID_WIDTH), payload_size => 0, packet_payload => (others => (others => '0')));
        -- #5: Wrong payload size (it does not  coincide with the specified size of this parameter, cmd handler should not accept it)
        variable packet_5 : t_packet_record := (5, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(ON_BIAS_ID, PARAM_ID_WIDTH), payload_size => 3, packet_payload => (others => (others => '0')));
        -- #6: Good write
        variable packet_6 : t_packet_record := (6, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(ON_BIAS_ID, PARAM_ID_WIDTH), payload_size => PARAM_ID_TO_SIZE(ON_BIAS_ID), packet_payload => (0  => x"0f0f0f00", 1  => x"0f0f0f01", 2  => x"0f0f0f02", 3  => x"0f0f0f03", 4  => x"0f0f0f04", 5  => x"0f0f0f05", 6  => x"0f0f0f06", 7  => x"0f0f0f07", 8  => x"0f0f0f08", 9  => x"0f0f0f09", 10 => x"0f0f0f10", 11 => x"0f0f0f11", others => (others => '0')));
        -- #7: Good read
        variable packet_7 : t_packet_record := (7, packet_type => cmd_rb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(ON_BIAS_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #8: Wrong start acquisition (Wrong parameter)
        variable packet_8 : t_packet_record := (8, packet_type => cmd_go, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(ON_BIAS_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #9: Wrong start acquisition (Good address but no previous setup)
        variable packet_9 : t_packet_record := (9, packet_type => cmd_go, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #10: Wrong stop acquisition (acquisition_on = '0')
        variable packet_10 : t_packet_record := (10, packet_type => cmd_st, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #11: Set acquisition config 
        variable packet_11 : t_packet_record := (11, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_S_ID, PARAM_ID_WIDTH), payload_size => 2, packet_payload => (0 => x"00000003", 1 => x"00000006", others => (others => '0')));
        -- #12: Good start acquisition
        variable packet_12 : t_packet_record := (12, packet_type => cmd_go, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #13: Good write but has to be ignored because acquisition is on
        variable packet_13 : t_packet_record := (13, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(ON_BIAS_ID, PARAM_ID_WIDTH), payload_size => PARAM_ID_TO_SIZE(ON_BIAS_ID), packet_payload => (0  => x"0f0f0f00", 1  => x"0f0f0f01", 2  => x"0f0f0f02", 3  => x"0f0f0f03", 4  => x"0f0f0f04", 5  => x"0f0f0f05", 6  => x"0f0f0f06", 7  => x"0f0f0f07", 8  => x"0f0f0f08", 9  => x"0f0f0f09", 10 => x"0f0f0f10", 11 => x"0f0f0f11", others => (others => '0')));
        -- #14: Bad write but has to be ignored because acquisition is on (wrong size)
        -- #15: bad start acquisition (acq already on)
        variable packet_15 : t_packet_record := (14, packet_type => cmd_go, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #16: Good start acquisition (But sender still busy)
        variable packet_16 : t_packet_record := (15, packet_type => cmd_go, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #17: Good stop (It should finish before last frame and set the corresponding bits)
        variable packet_17 : t_packet_record := (16, packet_type => cmd_st, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));
        -- #18: Good write sa fb cte 
        variable packet_18 : t_packet_record := (17, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(SA_FB_ID, PARAM_ID_WIDTH), payload_size => PARAM_ID_TO_SIZE(SA_FB_ID), packet_payload => (0 => x"01010100", 1 => x"01010101", others => (others => '0')));
        -- #19: Good write sa bias cte 
        variable packet_19 : t_packet_record := (18, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(SA_BIAS_ID, PARAM_ID_WIDTH), payload_size => PARAM_ID_TO_SIZE(SA_BIAS_ID), packet_payload => (0 => x"0000F1F0", 1 => x"0000F1F1", others => (others => '0')));
        -- #20: Good write (set ch0 -> servo_mode_const, ch1 -> servo_mode_PID)
        variable packet_20 : t_packet_record := (19, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(SERVO_MODE_ID, PARAM_ID_WIDTH), payload_size => PARAM_ID_TO_SIZE(SERVO_MODE_ID), packet_payload => (0 => std_logic_vector(to_unsigned(SERVO_MODE_CONST, t_word'length)), 1 => std_logic_vector(to_unsigned(SERVO_MODE_PID, t_word'length)), others => (others => '0')));
        -- #21: Good write TES bias 
        variable packet_21 : t_packet_record := (20, packet_type => cmd_wb, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(BIAS_ID, PARAM_ID_WIDTH), payload_size => PARAM_ID_TO_SIZE(BIAS_ID), packet_payload => (0 => x"FFFFFFF0", 1 => x"FFFFFFF1", 2 => x"FFFFFFF2", 3 => x"FFFFFFF3", others => (others => '0')));
        -- #22: Good start acquisition
        variable packet_22 : t_packet_record := (21, packet_type => cmd_go, card_id => DAUGHTER_CARD_ID, param_id => to_unsigned(RET_DATA_ID, PARAM_ID_WIDTH), payload_size => 1, packet_payload => (others => (others => '0')));


    begin
        -- Wait for rst
        wait for RST_START + RST_PULSE_LENGTH + 100 ns;

        -- #1: wrong card_id -> ignored by cmd_handler
        report "[TEST 1]";
        send_packet(packet_1, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_1);
        check_packet_ignored(packet_1);

        -- #2: wrong packet_type -> ignored by cmd_handler
        report "[TEST 2]";
        send_packet(packet_2, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_2);
        check_packet_ignored(packet_2);

        -- #3: wrong param_id -> reply error
        report "[TEST 3]";
        send_packet(packet_3, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_3);
        check_reply_error(packet_3);

        -- #4: Wrong payload size (size=0) -> ignored by parser
        report "[TEST 4]";
        send_packet(packet_4, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_parser_ignored_packet(packet_4);

        -- #5: Wrong payload size (size != param_size) -> reply error
        report "[TEST 5]";
        send_packet(packet_5, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_5);
        check_reply_error(packet_5);

        -- #6: Good write -> reply ok
        report "[TEST 6]";
        send_packet(packet_6, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_6);
        check_reply_ok(packet_6);

        -- #7: Good read -> reply ok
        report "[TEST 7]";
        send_packet(packet_7, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_7);
        check_reply_ok(packet_7, packet_6.packet_payload, packet_6.payload_size);

        -- #8: Wrong start acquisition (Wrong parameter)
        send_packet(packet_8, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        report "[TEST 8]";
        check_packet_received(packet_8);
        check_reply_error(packet_8);

        -- #9: Wrong start acquisition (Good address but no previous setup)
        send_packet(packet_9, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        report "[TEST 9]";
        check_packet_received(packet_9);
        check_reply_error(packet_9);

        -- #10: Wrong stop acquisition (acquisition_on = '0')
        send_packet(packet_10, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        report "[TEST 10]";
        check_packet_received(packet_10);
        check_reply_error(packet_10);

        -- #11: Set acquisition config 
        send_packet(packet_11, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        report "[TEST 11]";
        check_packet_received(packet_11);
        check_reply_ok(packet_11);

        -- #12: Good start acquisition (with current parameters it should last around 6000us until the last frame put in module, and 7500 until it is sent)
        send_packet(packet_12, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        report "[TEST 12]";
        check_packet_received(packet_12);
        check_reply_ok_async(packet_12, (others => (others => '0')), 0, reply_ok_async, reply_ok_async_data_to_read, reply_ok_async_data_length, check_reply_ok_signal);
        check_data_packets(to_integer(unsigned(packet_11.packet_payload(1))) - to_integer(unsigned(packet_11.packet_payload(0))) + 1, calc_data_packet, calc_data_payload);

        -- #13: Good write but has to be ignored because acquisition is on
        --report "[TEST 13]";
        -- Manual testing
        --send_packet(packet_13, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);

        -- #14: Bad write but has to be ignored because acquisition is on (wrong size)
        --send_packet(cmd_wb, DAUGHTER_CARD_ID, ON_BIAS_ID, 3, (others => (others => '0')), PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);

        -- #15: bad start acquisition (acq already on)
        -- send_packet(packet_15, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);

        -- #16 & 17: Good start acquisition and good stop 
        report "[TEST 13]";
        send_packet(packet_16, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        wait for PACKET_DELAY;
        send_packet(packet_17, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_good_stop(packet_17, to_integer(unsigned(packet_11.packet_payload(1))));

        -- #18: Good write sa fb cte 
        report "[TEST 14]";
        send_packet(packet_18, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_18);
        check_reply_ok(packet_18);

        -- #19: Good write sa bias cte 
        report "[TEST 15]";
        send_packet(packet_19, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_19);
        check_reply_ok(packet_19);
        
        -- #20: Good write (set ch0 -> servo_mode_const, ch1 -> servo_mode_PID)

        report "[TEST 16]";
        send_packet(packet_20, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_20);
        check_reply_ok(packet_20);


        -- #21: Good write TES bias 
        report "[TEST 17]";
        send_packet(packet_21, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        check_packet_received(packet_21);
        check_reply_ok(packet_21);
        -- Check that TES bias buffer are updated
        -- Check that TES setter does update the DAC voltages


        -- #22: Good start acquisition
        --report "[TEST 18]";
        send_packet(packet_22, PC_packet_type, PC_card_id, PC_param_id, PC_payload_size, PC_packet_payload, PC_params_valid);
        -- Check that channel mux on ch0 is outputing fb_cte
        -- Check that channel mux on ch1 is outputing calc_fb
        -- Check 

        wait for PACKET_DELAY;

        --wait for 200 ns;
        --wait for 20 ns;

        --wait for PACKET_DELAY;
        wait;

    end process;
    

end Behavioral;
