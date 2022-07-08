----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/24/2022
-- Module Name: main_module.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module that connects the different modules in the architecture. This is the top level of the design
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

entity main_module is
    port(
        sys_clk_5               : in std_logic; -- 5MHz clock
        sys_clk_100             : in std_logic; -- 100MHz clock
        sys_rst                 : in std_logic; -- asynchronous reset

        -- UART interface
        rx_uart_serial          : in std_logic;
        tx_uart_serial          : out std_logic;

        -- row_activator DACS interface
        sync_frame              : in std_logic;
        row_activator_DAC_CS_0  : out std_logic;
        row_activator_DAC_CS_1  : out std_logic;
        row_activator_DAC_CS_2  : out std_logic;
        row_activator_DAC_CLK   : out std_logic;
        row_activator_DAC_LDAC  : out std_logic;

        -- TES bias DAC interface
        TES_bias_DAC_CS         : out std_logic;
        TES_bias_DAC_CLK        : out std_logic;
        TES_bias_DAC_LDAC       : out std_logic;
        
        -- Channels DAC interface
        channels_DAC_CS         : out std_logic;
        channels_DAC_CLK        : out std_logic;
        channels_DAC_LDAC       : out std_logic;
        channels_DAC_SDI_0      : out std_logic;
        channels_DAC_SDI_1      : out std_logic;

        -- ADC interface
        ADC_CNV                 : out std_logic;
        ADC_SCK                 : out std_logic;
        ADC_CLKOUT              : in std_logic;
        ADC_SDO_0               : in std_logic;
        ADC_SDO_1               : in std_logic
    );
end main_module;

architecture Behavioral of main_module is

    -- FPGA RX uart module <-> packet parser
    signal rx_busy      : std_logic := '0';
    signal rx_byte_data : t_byte := (others => '0');

    -- packet parser -> cmd_handler
    signal parser_packet_type       : t_packet_type := cmd_wb;
    signal parser_card_id           : t_half_word := DAUGHTER_CARD_ID;
    signal parser_param_id          : t_half_word := "0000000011111111";
    signal parser_cmd_type          : t_packet_type := undefined;
    signal parser_err_ok            : std_logic := '0';
    signal parser_payload_size      : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal parser_packet_payload    : t_packet_payload := (others => (others => '0'));
    signal parser_params_valid      : std_logic := '0';

    -- command_handler <-> RAM
    signal ram_read_data            : t_word := (others => '0');
    signal ram_write_data           : t_word := (others => '0');
    signal ram_address              : unsigned(PARAM_RAM_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal ram_write                : std_logic;

    -- command_handler -> packet_sender
    signal packet_sender_ready      : std_logic := '0';
    signal send_reply_pulse         : std_logic := '0';
    signal reply_cmd_type           : t_packet_type := undefined;
    signal reply_err_ok             : std_logic := '0';
    signal reply_payload_size       : unsigned(bits_req(MAX_REPLY_PAYLOAD) - 1 downto 0) := (others => '0');
    signal param_data               : t_packet_payload := (others => (others => '0'));

    -- command_handler -> param_buffers
    signal update_param_pulse   : std_logic := '0';
    signal param_id_to_update   : unsigned(PARAM_ID_WIDTH - 1 downto 0) := (others => '0');

    -- command_handler -> channels_controller
    signal set_SF   : std_logic := '0';
    signal set_SB   : std_logic := '0';
    signal set_FF   : std_logic := '0';
    signal set_FB   : std_logic := '0';

    -- command_handler -> TES_bias_setter
    signal set_TES_bias     : std_logic := '0';

    -- command_handler -> row_activator
    signal update_off_value : std_logic := '0';

    -- command_handler -> frame_builder
    signal stop_received : std_logic := '0';

    -- command_handler -> general
    signal acquisition_on : std_logic := '0';

    -- packet_sender <-> packet_builder
    signal packet_type      : t_packet_type := undefined;
    signal card_id          : t_half_word := (others => '0');
    signal param_id         : t_half_word := (others => '0');
    signal cmd_type         : t_packet_type := undefined;
    signal err_ok           : std_logic := '0';
    signal payload_size     : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal packet_payload   : t_packet_payload := (others => (others => '0'));
    signal params_valid     : std_logic := '0';
    signal builder_ready    : std_logic := '0';

    -- packet builder <-> uart_controller
    signal tx_busy      : std_logic := '0';
    signal tx_send_byte    : std_logic := '0';
    signal tx_byte_data    : t_byte := (others => '0');

    -- frame_builder -> command_handler 
    signal last_frame_sent    : std_logic := '0';

    -- channels controller signals
    signal channels_ctr_DAC_start_pulse : std_logic := '0';
    signal channels_DAC_addr        : std_logic_vector(DAC_ADDR_SIZE - 1 downto 0) := (others => '0');
    signal channels_line_selector   : t_line_sel_array := (others => (others => '0'));
    signal channels_data_selector   : unsigned(bits_req(NUM_DATA_MODES) - 1 downto 0) := (others => '0');

    -- row_selector signals
    signal new_row      : std_logic := '0';
    signal row_num      : unsigned(bits_req(MAX_ROWS - 1) - 1 downto 0)   := (others => '0');
    signal frame_active : std_logic := '0';

    -- row_activator signals
    signal row_activator_DAC_start_pulse    : std_logic := '0';
    signal row_activator_DAC_CS_signal      : std_logic := '0'; -- We need it because we need to read it
    signal row_activator_DAC_CLK_signal     : std_logic := '0'; -- We need it because we need to read it
    signal row_activator_DAC_sel            : unsigned(bits_req(NUM_DACS_ROW_ACTIVATOR) - 1 downto 0) := (others => '0');
    signal row_activator_DAC_CS_vector      : std_logic_vector(sel_size_to_input(row_activator_DAC_sel'length) - 1 downto 0) := (others => '0');
    signal row_activator_DAC_data           : std_logic_vector(DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE - 1 downto 0) := (others => '0');

    -- ADC_triggerer -> ADC_gate_controller
    signal ADC_start_pulse : std_logic := '0';

    -- ADC signals
    signal ADC_SDO_vector   : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');
    signal ADC_CNV_signal   : std_logic := '0'; -- We need it because we need to read it

    -- ddr_input -> input_shift_register
    type ddr_parallel_array is array(0 to MAX_CHANNELS - 1) of std_logic_vector(1 downto 0);
    signal ddr_parallel     : ddr_parallel_array := (others => (others=> '0'));

    -- fall_edge_dector (cnv) -> input_shift_register
    signal cnv_fall_pulse : std_logic := '0';

    -- input_shift_register -> sample_selector
    signal valid_word    : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');
    type t_adc_data_array is array(0 to MAX_CHANNELS - 1) of std_logic_vector(ADC_DATA_SIZE - 1 downto 0);
    signal parallel_data : t_adc_data_array := (others =>(others => '0'));

    -- sample_selector -> sample_accumulator
    signal valid_sample : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');
    signal sample_data  : t_adc_data_array := (others => (others => '0'));
    

    -- sample_accumulator -> feedback calculator
    signal acc_sample : t_channel_record_array := (
        others => (
            value => (others => '0'),
            row_num => (others => '0'),
            valid => '0'
        )
    );

    signal acc_sample_stretched : t_channel_record_array := (
        others => (
            value => (others => '0'),
            row_num => (others => '0'),
            valid => '0'
        )
    );

    -- feedback_calculator
    signal fb_sample : t_channel_record_array := (
        others => (
            value => (others => '0'),
            row_num => (others => '0'),
            valid => '0'
        )
    );

    type fb_ram_addr_signal_array is array(0 to MAX_CHANNELS - 1) of unsigned(FB_RAM_ADDR_WIDTH - 1 downto 0);
    signal fb_ram_write_addr_signal : fb_ram_addr_signal_array := (others => (others => '0'));

    -- feedback reader -> dual ram
    type read_address_array is array(0 to MAX_CHANNELS - 1) of unsigned(FB_RAM_ADDR_WIDTH - 1 downto 0);
    signal read_address : read_address_array := (others => (others => '0'));
    type t_word_array is array(0 to MAX_CHANNELS - 1) of t_word;
    signal read_data : t_word_array := (others => (others => '0'));

    -- feedback reader -> channel mux
    signal sa_fb_data : t_adc_data_array := (others => (others => '0'));

    -- channel mux -> data serializer
    type t_channels_line_data_array is array(0 to MAX_CHANNELS - 1) of std_logic_vector(DAC_VOLTAGE_SIZE - 1 downto 0);
    signal channels_line_data : t_channels_line_data_array := (others => (others => '0'));

    -- channels DAC signals
    signal channels_DAC_SDI_vector : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');
    signal channels_DAC_CS_signal : std_logic := '0'; -- Needed because we need to read it
    signal channels_DAC_CLK_signal : std_logic := '0'; -- Needed because we need to read it

    -- channels readout -> frame_builder
    signal channels_data : t_channel_record_array := (
        others => (
            value => (others => '0'),
            valid => '0',
            row_num => (others => '0')
        )
    );
    -- frame_builder -> packet_sender
    signal send_data_packet         : std_logic := '0';
    signal data_packet_payload_size : unsigned(bits_req(MAX_PAYLOAD) - 1 downto 0) := (others => '0');
    signal data_packet_payload      : t_packet_payload := (others => (others => '0'));

    -- TES_bias_setter signals
    signal TES_bias_DAC_start_pulse : std_logic := '0';
    signal TES_bias_DAC_data        : std_logic_vector(DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE - 1 downto 0) := (others => '0');
    signal TES_bias_DAC_CS_signal   : std_logic := '0';
    signal TES_bias_DAC_CLK_signal  : std_logic := '0';

    -- Param buffers signals
    signal data_mode        : t_param_array(0 to PARAM_ID_TO_SIZE(DATA_MODE_ID) - 1) := (others => (others => '0'));
    signal servo_mode       : t_param_array(0 to PARAM_ID_TO_SIZE(SERVO_MODE_ID) - 1) := (others => (others => '0'));
    signal fb_dly           : t_param_array(0 to PARAM_ID_TO_SIZE(FB_DLY_ID) - 1) := (others => (others => '0'));
    signal num_rows         : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_ROWS_ID) - 1) := (others => (others => '0'));
    signal row_len          : t_param_array(0 to PARAM_ID_TO_SIZE(ROW_LEN_ID) - 1) := (others => (others => '0'));
    signal on_bias          : t_param_array(0 to PARAM_ID_TO_SIZE(ON_BIAS_ID) - 1) := (others => (others => '0'));
    signal off_bias         : t_param_array(0 to PARAM_ID_TO_SIZE(OFF_BIAS_ID) - 1) := (others => (others => '0'));
    signal cnv_len          : t_param_array(0 to PARAM_ID_TO_SIZE(CNV_LEN_ID) - 1) := (others => (others => '0'));
    signal sck_dly          : t_param_array(0 to PARAM_ID_TO_SIZE(SCK_DLY_ID) - 1) := (others => (others => '0'));
    signal sck_half_period  : t_param_array(0 to PARAM_ID_TO_SIZE(SCK_HALF_PERIOD_ID) - 1) := (others => (others => '0'));
    signal sample_dly       : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_DLY_ID) - 1) := (others => (others => '0'));
    signal sample_num       : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_NUM_ID) - 1) := (others => (others => '0'));
    signal gain_0           : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_0_ID) - 1) := (others => (others => '0'));
    signal gain_1           : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_1_ID) - 1) := (others => (others => '0'));
    signal tes_bias         : t_param_array(0 to PARAM_ID_TO_SIZE(BIAS_ID) - 1) := (others => (others => '0'));
    signal ret_data_s       : t_param_array(0 to PARAM_ID_TO_SIZE(RET_DATA_S_ID) - 1) := (others => (others => '0'));
    signal data_rate        : t_param_array(0 to PARAM_ID_TO_SIZE(DATA_RATE_ID) - 1) := (others => (others => '0'));
    signal num_cols         : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_COLS_REP_ID) - 1) := (others => (others => '0'));
    signal sa_fb_cte        : t_param_array(0 to PARAM_ID_TO_SIZE(SA_FB_ID) - 1) := (others => (others => '0'));
    signal sa_bias_cte      : t_param_array(0 to PARAM_ID_TO_SIZE(SA_BIAS_ID) - 1) := (others => (others => '0'));
    signal sq1_fb_cte       : t_param_array(0 to PARAM_ID_TO_SIZE(SQ1_FB_ID) - 1) := (others => (others => '0'));
    signal sq1_bias_cte     : t_param_array(0 to PARAM_ID_TO_SIZE(SQ1_BIAS_ID) - 1) := (others => (others => '0'));

    type t_gain_array is array(0 to MAX_CHANNELS - 1) of t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_0_ID) - 1);
    signal gain_array : t_gain_array := (others => (others => (others => '0')));

begin

    -- Simple assigments of some outputs that need to be read
    -- Row activator DACs
    row_activator_DAC_CLK   <= row_activator_DAC_CLK_signal;
    row_activator_DAC_CS_0  <= row_activator_DAC_CS_vector(0);
    row_activator_DAC_CS_1  <= row_activator_DAC_CS_vector(1);
    row_activator_DAC_CS_2  <= row_activator_DAC_CS_vector(2);
    -- Channels DACs
    channels_DAC_CS         <= channels_DAC_CS_signal;
    channels_DAC_CLK        <= channels_DAC_CLK_signal;
    -- TES bias DAC
    TES_bias_DAC_CS         <= TES_bias_DAC_CS_signal;
    TES_bias_DAC_CLK        <= TES_bias_DAC_CLK_signal;
    -- ADC
    ADC_CNV                 <= ADC_CNV_signal;

    -- UART module
    uart_controller_module : entity concept.uart_controller
        port map(
            clk         => sys_clk_100,
            rst         => sys_rst,

            tx_ena      => tx_send_byte,
            tx_data     => tx_byte_data,

            rx          => rx_uart_serial,
            rx_busy     => rx_busy,
            rx_error    => open,
            rx_data     => rx_byte_data,

            tx_busy     => tx_busy,
            tx          => tx_uart_serial
        );

    -- Packet parser
    packet_parser : entity concept.packet_parser
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,

            packet_type     => parser_packet_type,
            card_id         => parser_card_id,
            param_id        => parser_param_id,
            cmd_type        => open,
            err_ok          => open,
            payload_size    => parser_payload_size,
            packet_payload  => parser_packet_payload,

            rx_busy         => rx_busy,
            byte_data       => rx_byte_data,
            params_valid    => parser_params_valid
        );


    command_handler_module : entity concept.command_handler
        generic map(
            MAX_PAYLOAD_SIZE        => MAX_PAYLOAD,
            MAX_REPLY_PAYLOAD_SIZE  => MAX_REPLY_PAYLOAD,
            RAM_ADDR_WIDTH          => PARAM_RAM_ADDR_WIDTH,
            PARAM_ID_WIDTH          => PARAM_ID_WIDTH,
            MAX_PARAM_ID_SIZE       => MAX_PARAM_ID_SIZE
        )
        port map(
            clk                     => sys_clk_5,
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
            update_param_pulse      => update_param_pulse,
            param_id_to_update      => param_id_to_update,
            
            -- Interface with channels controller
            set_SF                  => set_SF,
            set_SB                  => set_SB,
            set_FF                  => set_FF,
            set_FB                  => set_FB,

            -- Interface with TES bias setter
            set_TES_bias            => set_TES_bias,

            -- Interface with row_activator
            update_off_value        => update_off_value,

            -- Interface with frame_builder
            last_data_frame_pulse   => last_frame_sent,
            stop_received           => stop_received,

            acquisition_on          => acquisition_on
        );


    packet_sender_module : entity concept.packet_sender
        generic map(
            PARAM_ID_WIDTH          => PARAM_ID_WIDTH,
            MAX_REPLY_PAYLOAD_SIZE  => MAX_REPLY_PAYLOAD,
            MAX_PAYLOAD_SIZE        => MAX_PAYLOAD
        )
        port map(
            clk                    => sys_clk_5,
            rst                    => sys_rst,

            -- Interface with command_handler
            send_reply_pulse       => send_reply_pulse,
            reply_param_id         => param_id_to_update,
            reply_cmd_type         => reply_cmd_type,
            reply_err_ok           => reply_err_ok,
            reply_payload_size     => reply_payload_size,
            reply_payload          => param_data,
                                
            -- Interface with frame_builder
            send_data_frame_pulse  => send_data_packet,
            data_frame_payload_size=> data_packet_payload_size,
            data_frame_payload     => data_packet_payload,
                                
            -- Interface with packet_builder
            builder_ready          => builder_ready,
            packet_type            => packet_type,
            card_id                => card_id,
            param_id               => param_id,
            cmd_type               => cmd_type,
            err_ok                 => err_ok,
            payload_size           => payload_size,
            packet_payload         => packet_payload,
            params_valid           => params_valid,

            ready                  => packet_sender_ready
        );

    packet_builder_module : entity concept.packet_builder
        port map(
            clk             => sys_clk_5,
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
            send_byte       => tx_send_byte,
            byte_data       => tx_byte_data, 
            builder_ready   => builder_ready
        );


    bram_wrapper_module : entity concept.BRAM_single_wrapper
        generic map(
            DATA_WIDTH  => PARAM_RAM_DATA_WIDTH,
            BRAM_SIZE   => PARAM_RAM_BRAM_SIZE,
            READ_DEPTH  => PARAM_RAM_READ_DEPTH,
            ADDR_WIDTH  => PARAM_RAM_ADDR_WIDTH,
            WE_WIDTH    => PARAM_RAM_WE_WIDTH
        )
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,
                            
            address         => ram_address,
            write_data      => ram_write_data,
            write_pulse     => ram_write,
            read_data       => ram_read_data
        );
    
    channels_controller_module : entity concept.channels_controller
        port map(
            clk                 => sys_clk_5,
            rst                 => sys_rst,

            data_mode           => data_mode(0)(bits_req(NUM_DATA_MODES) - 1 downto 0),
            servo_mode          => servo_mode,
            fb_dly              => unsigned(fb_dly(0)(bits_req(MAX_FB_DLY) - 1 downto 0)),

            new_row             => new_row,
            acquisition_on      => acquisition_on,
            frame_active        => frame_active,
            set_SF              => set_SF,
            set_SB              => set_SB,
            set_FF              => set_FF,
            set_FB              => set_FB,

            DAC_start_pulse     => channels_ctr_DAC_start_pulse,
            DAC_address         => channels_DAC_addr,
            line_sel            => channels_line_selector,
            data_sel            => channels_data_selector
        );

    channels_DAC_gate_ctrl : entity concept.DAC_gate_controller
        generic map(
            SCLK_TOTAL_PULSES   => DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE,
            SCLK_HALF_PERIOD    => DAC_SCLK_HALF_PERIOD,
            LDAC_SETUP          => DAC_LDAC_SETUP,
            LDAC_WIDTH          => DAC_LDAC_WIDTH,
            LDAC_HOLD           => DAC_LDAC_HOLD
        )
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,
            
            start_conv_pulse    => channels_ctr_DAC_start_pulse,
            CS                  => channels_DAC_CS_signal,
            SCLK                => channels_DAC_CLK_signal,
            LDAC                => channels_DAC_LDAC
        );
    
    row_selector_module : entity concept.row_selector
        generic map(
            MAX_NUM_ROWS => MAX_ROWS,
            MAX_ROW_LEN => MAX_ROW_LEN
        )
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,
                               
            sync_frame      => sync_frame,
            acquisition_on  => acquisition_on,
            num_rows        => unsigned(num_rows(0)(bits_req(MAX_ROWS) - 1 downto 0)),
            row_len         => unsigned(row_len(0)(bits_req(MAX_ROW_LEN) - 1 downto 0)),
                               
            new_row         => new_row,
            row_num         => row_num,
            frame_active    => frame_active
        );

    row_activator_module : entity concept.row_activator
        generic map(
            MAX_DAC_MODULES_ROW_ACTIVATOR => NUM_DACS_ROW_ACTIVATOR,
            DAC_DLY                       => MAX_DAC_DLY,
            MAX_NUM_ROWS                  => MAX_ROWS,
            VOLTAGE_SIZE                  => DAC_VOLTAGE_SIZE,
            ADDR_SIZE                     => DAC_ADDR_SIZE
        )
        port map(
            clk                 => sys_clk_5,
            rst                 => sys_rst,

            on_bias             => on_bias,
            off_bias            => off_bias,
            num_rows            => unsigned(num_rows(0)(bits_req(MAX_ROWS) - 1 downto 0)),

            new_row             => new_row,
            row_num             => row_num,
            acquisition_on      => acquisition_on,
            update_off_value    => update_off_value, 
            DAC_start_pulse     => row_activator_DAC_start_pulse,
            DAC_sel             => row_activator_DAC_sel,
            DAC_data            => row_activator_DAC_data
        );

    row_activator_DAC_gate_ctrl : entity concept.DAC_gate_controller
        generic map(
            SCLK_TOTAL_PULSES   => DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE,
            SCLK_HALF_PERIOD    => DAC_SCLK_HALF_PERIOD,
            LDAC_SETUP          => DAC_LDAC_SETUP,
            LDAC_WIDTH          => DAC_LDAC_WIDTH,
            LDAC_HOLD           => DAC_LDAC_HOLD
        )
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,
            
            start_conv_pulse    => row_activator_DAC_start_pulse,
            CS                  => row_activator_DAC_CS_signal,
            SCLK                => row_activator_DAC_CLK_signal,
            LDAC                => row_activator_DAC_LDAC
        );


    CS_demux : entity concept.demux
        generic map(
            DATA_SIZE => 1,
            SEL_SIZE  => row_activator_DAC_sel'length
        )
        port map(
            selector    => row_activator_DAC_sel,
            data_in(0)  => row_activator_DAC_CS_signal,
            data_out    => row_activator_DAC_CS_vector
        );
    
    row_activator_data_serializer : entity concept.data_serializer_wrapper
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            gate_read       => row_activator_DAC_CS_signal,
            data_clk        => row_activator_DAC_CLK_signal,
            valid           => '1',
            parallel_data   => row_activator_DAC_data,
            busy_flag       => '0',
            DAC_start_pulse => row_activator_DAC_start_pulse,
            serial_data     => open
        );

    ADC_triggerer_module : entity concept.ADC_triggerer
        generic map(
            trigg_clk_cycles        => 20
        )
        port map(
            clk                     => sys_clk_100,
            rst                     => sys_rst,

            frame_active            => frame_active,
            ADC_start_pulse         => ADC_start_pulse
        );


    ADC_gate_controller : entity concept.ADC_gate_controller
        generic map(
            NUM_OF_SCK_CYCLES => ADC_DATA_SIZE / 2
        )
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            cnv_len         => unsigned(cnv_len(0)(ADC_PARAMS_WIDTH - 1 downto 0)),
            sck_dly         => unsigned(sck_dly(0)(ADC_PARAMS_WIDTH - 1 downto 0)),
            sck_half_period => unsigned(sck_half_period(0)(ADC_PARAMS_WIDTH - 1 downto 0)),

            start_pulse     => ADC_start_pulse,

            CNV             => ADC_CNV_signal,
            SCK             => ADC_SCK
        );

    fall_edge_detector_CNV : entity concept.FallEdgeDetector
        port map (
            clk             => sys_clk_100,
            rst             => sys_rst,
            signal_in       => ADC_CNV_signal,
            signal_out      => cnv_fall_pulse
        );


    channels_DAC_SDI_0 <= channels_DAC_SDI_vector(0);
    channels_DAC_SDI_1 <= channels_DAC_SDI_vector(1);
    ADC_SDO_vector(0) <= ADC_SDO_0;
    ADC_SDO_vector(1) <= ADC_SDO_1;

    gain_array(0) <= gain_0; 
    gain_array(1) <= gain_1;

    channels_readout : for i in 0 to MAX_CHANNELS - 1 generate

        ddr_input_module : entity concept.ddr_input
            port map(
                clock        => ADC_CLKOUT,
                reset        => sys_rst,

                output_en    => '1',
                ddr_in       => ADC_SDO_vector(i),
                parallel_out => ddr_parallel(i)
            );

        
        input_shift_register_module : entity concept.input_shift_register
            port map(
                clk                     => sys_clk_100,
                rst                     => sys_rst,

                serial_clk              => ADC_CLKOUT,
                iddr_parallel_output    => ddr_parallel(i),
                conv_started            => ADC_CNV_signal,
                valid_word              => valid_word(i),
                parallel_data           => parallel_data(i)
            );

        sample_selector_module : entity concept.sample_selector
            generic map(
                MAX_SAMPLE_NUM  => MAX_SAMPLE_NUM,
                MAX_SAMPLE_DLY  => MAX_SAMPLE_DLY,
                DATA_WIDTH      => ADC_DATA_SIZE
            )
            port map(
                clk                     => sys_clk_100,
                rst                     => sys_rst,

                sample_dly              => unsigned(sample_dly(0)(bits_req(MAX_SAMPLE_DLY) - 1 downto 0)),
                sample_num              => unsigned(sample_num(0)(bits_req(MAX_SAMPLE_NUM) - 1 downto 0)),
                new_row                 => new_row,
                valid_word              => valid_word(i),
                parallel_data           => parallel_data(i),
                valid_sample            => valid_sample(i),
                sample_data             => sample_data(i)
            );

        sample_accumulator_module : entity concept.sample_accumulator
            generic map(
                MAX_ROW_NUM     => MAX_ROWS,
                MAX_SAMPLE_NUM  => MAX_SAMPLE_NUM,
                DATA_WIDTH      => ADC_DATA_SIZE
            )
            port map(
                clk                     => sys_clk_100,
                rst                     => sys_rst,

                sample_num              => unsigned(sample_num(0)(bits_req(MAX_SAMPLE_NUM) - 1 downto 0)),
                valid_sample            => valid_sample(i),
                sample                  => sample_data(i),
                row_num                 => row_num,
                acc_sample              => acc_sample(i)
            );

        pulse_stretcher : entity concept.pulse_stretcher
            port map(
                clk                 => sys_clk_100,
                rst                 => sys_rst,

                fast_pulse          => acc_sample(i).valid,
                stretched_pulse     => acc_sample_stretched(i).valid
            );

        acc_sample_stretched(i).value      <= acc_sample(i).value;
        acc_sample_stretched(i).row_num    <= acc_sample(i).row_num;

        feedback_calculator_module : entity concept.feedback_calculator
            port map(
                clk                 => sys_clk_5,
                rst                 => sys_rst,

                acc_sample          => acc_sample_stretched(i),
                sa_fb_gain          => signed(gain_array(i)(0)),
                fb_sample           => fb_sample(i)
            );

        fb_ram_write_addr_signal(i) <= resize(fb_sample(i).row_num, fb_ram_write_addr_signal(i)'length);

        bram_dual_wrapper_module : entity concept.bram_dual_wrapper
            generic map(
                DATA_WIDTH  => FB_RAM_DATA_WIDTH,
                BRAM_SIZE   => FB_RAM_BRAM_SIZE,
                READ_DEPTH  => FB_RAM_READ_DEPTH,
                ADDR_WIDTH  => FB_RAM_ADDR_WIDTH,
                WE_WIDTH    => FB_RAM_WE_WIDTH
            )
            port map(
                clk             => sys_clk_5,
                rst             => sys_rst,

                write_address   => fb_ram_write_addr_signal(i),
                write_data      => std_logic_vector(fb_sample(i).value),
                write_pulse     => fb_sample(i).valid,
                read_address    => read_address(i),
                read_data       => read_data(i)
            );
        
        feedback_reader_module : entity concept.feedback_reader
            generic map(
                DATA_SIZE       => DAC_VOLTAGE_SIZE,
                MAX_NUM_ROWS    => MAX_ROWS,
                READ_ADDR_SIZE  => FB_RAM_ADDR_WIDTH
            )
            port map(
                clk             => sys_clk_5,
                rst             => sys_rst,

                new_row         => new_row,
                row_num         => row_num,
                num_rows        => unsigned(num_rows(0)(bits_req(MAX_ROWS) - 1 downto 0)),

                read_address    => read_address(i),
                read_data       => read_data(i)(DAC_VOLTAGE_SIZE - 1 downto 0),

                sa_fb_data      => sa_fb_data(i)
            );

        channel_mux : entity concept.mux
            generic map(
                DATA_SIZE   => DAC_VOLTAGE_SIZE,
                SEL_SIZE    => LINE_SEL_SIZE -- Req bits for 6 inputs (calc_fb, ramp, SF, SB, FF, FB)
            )             
            port map(     
                selector => channels_line_selector(i),
                data_in(1 * DAC_VOLTAGE_SIZE - 1 downto 0 * DAC_VOLTAGE_SIZE) => sa_fb_data(i),
                data_in(2 * DAC_VOLTAGE_SIZE - 1 downto 1 * DAC_VOLTAGE_SIZE) => (others => '0'), -- Ramp not implemented yet
                data_in(3 * DAC_VOLTAGE_SIZE - 1 downto 2 * DAC_VOLTAGE_SIZE) => sa_fb_cte(i)(DAC_VOLTAGE_SIZE - 1 downto 0),
                data_in(4 * DAC_VOLTAGE_SIZE - 1 downto 3 * DAC_VOLTAGE_SIZE) => sa_bias_cte(i)(DAC_VOLTAGE_SIZE - 1 downto 0),
                data_in(5 * DAC_VOLTAGE_SIZE - 1 downto 4 * DAC_VOLTAGE_SIZE) => sq1_fb_cte(i)(DAC_VOLTAGE_SIZE - 1 downto 0),
                data_in(6 * DAC_VOLTAGE_SIZE - 1 downto 5 * DAC_VOLTAGE_SIZE) => sq1_bias_cte(i)(DAC_VOLTAGE_SIZE - 1 downto 0),
                data_in(total_inputs(bits_req(NUM_CHANNEL_LINES)) * DAC_VOLTAGE_SIZE - 1 downto 6 * DAC_VOLTAGE_SIZE) => (others => '0'),
                data_out => channels_line_data(i)
            );

        channel_data_serializer : entity concept.data_serializer_wrapper
            port map(
                clk             => sys_clk_100,
                rst             => sys_rst,

                gate_read                                                               => channels_DAC_CS_signal,
                data_clk                                                                => channels_DAC_CLK_signal,
                valid                                                                   => '1',
                parallel_data(DAC_VOLTAGE_SIZE - 1 downto 0)                               => channels_line_data(i),
                parallel_data(DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE - 1 downto DAC_VOLTAGE_SIZE)   => channels_DAC_addr,
                busy_flag                                                               => '0',
                DAC_start_pulse                                                         => channels_ctr_DAC_start_pulse,
                serial_data                                                             => channels_DAC_SDI_vector(i)
            );

    end generate;


    TES_bias_setter_module : entity concept.TES_bias_setter
        generic map(
            NUM_DACS    => PARAM_ID_TO_SIZE(BIAS_ID),
            DAC_DLY     => MAX_DAC_DLY 
        )
        port map(
            clk                     => sys_clk_5,
            rst                     => sys_rst,

            set_bias                => set_TES_bias,
            TES_bias                => tes_bias,
            DAC_start_pulse         => TES_bias_DAC_start_pulse,
            DAC_data                => TES_bias_DAC_data
        );

    TES_bias_DAC_gate_controller : entity concept.DAC_gate_controller
        generic map(
            SCLK_TOTAL_PULSES   => DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE,
            SCLK_HALF_PERIOD    => DAC_SCLK_HALF_PERIOD,
            LDAC_SETUP          => DAC_LDAC_SETUP,
            LDAC_WIDTH          => DAC_LDAC_WIDTH,
            LDAC_HOLD           => DAC_LDAC_HOLD
        )
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,
            start_conv_pulse    => TES_bias_DAC_start_pulse,
            CS                  => TES_bias_DAC_CS_signal,
            SCLK                => TES_bias_DAC_CLK_signal,
            LDAC                => TES_bias_DAC_LDAC 
        );

    TES_bias_data_serializer : entity concept.data_serializer_wrapper
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            gate_read       => TES_bias_DAC_CS_signal,
            data_clk        => TES_bias_DAC_CLK_signal,
            valid           => '1',
            parallel_data   => TES_bias_DAC_data,
            busy_flag       => '0',
            DAC_start_pulse => TES_bias_DAC_start_pulse,
            serial_data     => open
        );

    channels_data <= fb_sample;

    frame_builder_module : entity concept.frame_builder
        port map(
            clk                     => sys_clk_5,
            rst                     => sys_rst,

            -- Param buffers
            ret_data_setup          => ret_data_s,
            data_rate               => unsigned(data_rate(0)(bits_req(MAX_DATA_RATE) - 1 downto 0)),
            num_rows                => unsigned(num_rows(0)(bits_req(MAX_ROWS) - 1 downto 0)),
            num_cols                => unsigned(num_cols(0)(bits_req(MAX_CHANNELS) - 1 downto 0)),
            row_len                 => unsigned(row_len(0)(bits_req(MAX_ROW_LEN) - 1 downto 0)),

            -- Interface with cmd handler
            acquisition_on          => acquisition_on,
            stop_received           => stop_received,
            frame_active            => frame_active,
            last_frame_sent         => last_frame_sent,
            
            -- Interface with channels
            channels_data           => channels_data,

            -- Interface with packet sender
            sender_ready            => packet_sender_ready,
            send_data_packet        => send_data_packet,
            payload_size            => data_packet_payload_size,
            frame_payload           => data_packet_payload
        );

    -- params buffers

    -- DATA_MODE_ID
    data_mode_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(DATA_MODE_ID),
            param_id            => to_unsigned(DATA_MODE_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => data_mode
        );

    -- SERVO_MODE_ID
    servo_mode_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SERVO_MODE_ID),
            param_id            => to_unsigned(SERVO_MODE_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => SERVO_MODE_DEF,
            param_data          => servo_mode
        );

    -- FB_DLY_ID
    fb_dly_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(FB_DLY_ID),
            param_id            => to_unsigned(FB_DLY_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => FB_DLY_DEF,
            param_data          => fb_dly
        );

    -- NUM_ROWS_ID
    num_rows_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(NUM_ROWS_ID),
            param_id            => to_unsigned(NUM_ROWS_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => NUM_ROWS_DEF,
            param_data          => num_rows
        );

    -- ROW_LEN_ID
    row_len_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(ROW_LEN_ID),
            param_id            => to_unsigned(ROW_LEN_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => ROW_LEN_DEF,
            param_data          => row_len
        );

    -- ON_BIAS_ID
    on_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(ON_BIAS_ID),
            param_id            => to_unsigned(ON_BIAS_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => ON_BIAS_DEF,
            param_data          => on_bias
        );

    -- OFF_BIAS_ID
    off_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(OFF_BIAS_ID),
            param_id            => to_unsigned(OFF_BIAS_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => OFF_BIAS_DEF,
            param_data          => off_bias
        );

    -- CNV_LEN_ID
    cnv_len_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(CNV_LEN_ID),
            param_id            => to_unsigned(CNV_LEN_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => CNV_LEN_DEF,
            param_data          => cnv_len
        );

    -- SCK_DLY_ID
    sck_dly_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SCK_DLY_ID),
            param_id            => to_unsigned(SCK_DLY_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => SCK_DLY_DEF,
            param_data          => sck_dly
        );

    -- SCK_HALF_PERIOD_ID
    sck_half_period_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SCK_HALF_PERIOD_ID),
            param_id            => to_unsigned(SCK_HALF_PERIOD_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => SCK_HALF_PERIOD_DEF,
            param_data          => sck_half_period
        );

    -- SAMPLE_DLY_ID
    sample_dly_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SAMPLE_DLY_ID),
            param_id            => to_unsigned(SAMPLE_DLY_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => SAMPLE_DLY_DEF,
            param_data          => sample_dly
        );

    -- SAMPLE_NUM_ID
    sample_num_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SAMPLE_NUM_ID),
            param_id            => to_unsigned(SAMPLE_NUM_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => SAMPLE_NUM_DEF,
            param_data          => sample_num
        );

    -- GAIN_0_ID
    gain_0_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(GAIN_0_ID),
            param_id            => to_unsigned(GAIN_0_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => GAIN_0_DEF,
            param_data          => gain_0
        );

    -- GAIN_1_ID
    gain_1_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(GAIN_1_ID),
            param_id            => to_unsigned(GAIN_1_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => GAIN_1_DEF,
            param_data          => gain_1
        );

    -- BIAS_ID
    tes_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(BIAS_ID),
            param_id            => to_unsigned(BIAS_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => tes_bias
        );

    -- RET_DATA_S_ID
    ret_data_s_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(RET_DATA_S_ID),
            param_id            => to_unsigned(RET_DATA_S_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => ret_data_s
        );

    -- DATA_RATE_ID
    data_rate_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(DATA_RATE_ID),
            param_id            => to_unsigned(DATA_RATE_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => DATA_RATE_DEF,
            param_data          => data_rate
        );

    -- NUM_COLS_REP_ID
    num_cols_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(NUM_COLS_REP_ID),
            param_id            => to_unsigned(NUM_COLS_REP_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => NUM_COLS_REP_DEF,
            param_data          => num_cols
        );

    -- SA_FB_ID
    sa_fb_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SA_FB_ID),
            param_id            => to_unsigned(SA_FB_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sa_fb_cte
        );

    -- SA_BIAS_ID
    sa_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SA_BIAS_ID),
            param_id            => to_unsigned(SA_BIAS_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sa_bias_cte
        );

    -- SQ1_FB_ID
    sq1_fb_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SQ1_FB_ID),
            param_id            => to_unsigned(SQ1_FB_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sq1_fb_cte
        );

    -- SQ1_BIAS_ID
    sq1_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SQ1_BIAS_ID),
            param_id            => to_unsigned(SQ1_BIAS_ID, PARAM_ID_WIDTH)
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sq1_bias_cte
        );

end Behavioral;
