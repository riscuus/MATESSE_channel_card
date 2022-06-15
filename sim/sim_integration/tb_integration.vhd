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
    constant T_HALF_CLK_100     : time := 5 ns;
    constant T_HALF_CLK_5       : time := 100 ns;
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 300 ns;
    constant PARAMS_VALID_START : time := 300 ns; 
    constant DATA_SETUP         : time := 200 ns;
    constant PARAMS_VALID_HIGH  : time := 200 ns;
    constant PACKET_DELAY       : time := 2 us; -- Time between trying a new packet
    constant SIM_DURATION       : time := 200 ms;

    -- Clock
    signal sys_clk_100  : std_logic;
    signal sys_clk_5    : std_logic;
    signal sys_rst      : std_logic;

    -- External
    signal sync_frame : std_logic := '0';

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

    -- command_handler -> packet_sender
    signal packet_sender_ready      : std_logic := '0';
    signal send_reply_pulse         : std_logic := '0';
    signal reply_cmd_type           : t_packet_type := undefined;
    signal reply_err_ok             : std_logic := '0';
    signal reply_payload_size       : natural := 0;
    signal param_data               : t_packet_payload := (others => (others => '0'));

    -- command_handler -> param_buffers
    signal update_param_pulse   : std_logic := '0';
    signal param_id_to_update   : natural := 0;

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

    -- frame_builder -> command_handler 
    signal last_frame_sent    : std_logic := '0';

    -- row_selector signals
    signal new_row      : std_logic := '0';
    signal row_num      : natural   := 0;
    signal frame_active : std_logic := '0';

    -- ADC_triggerer -> ADC_gate_controller
    signal ADC_start_pulse : std_logic := '0';

    -- ADC_gate_controller -> ADC_simulator
    signal adc_cnv  : std_logic := '0';
    signal adc_sck  : std_logic := '0';

    -- ADC_simulator_0 signals
    signal adc_sim_data_0   : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_sdo_0        : std_logic := '0';

    -- ADC_simulator_1 signals
    signal adc_sim_data_1   : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_sdo_1        : std_logic := '0';

    -- ddr_input -> input_shift_register
    signal ddr_parallel     : std_logic_vector(1 downto 0) := (others => '0');

    -- fall_edge_dector (cnv) -> input_shift_register
    signal cnv_fall_pulse : std_logic := '0';

    -- input_shift_register -> sample_selector
    signal valid_word    : std_logic := '0';
    signal parallel_data : std_logic_vector(15 downto 0) := (others => '0');

    -- sample_selector -> sample_accumulator
    signal valid_sample : std_logic := '0';
    signal sample_data  : t_adc_sample := (others => '0');
    
    -- sample_accumulator -> feedback calculator
    signal acc_sample : t_channel_record := (
        value => (others => '0'),
        row_num => 0,
        valid => '0'
    );

    signal acc_sample_stretched : t_channel_record := (
        value => (others => '0'),
        row_num => 0,
        valid => '0'
    );

    -- feedback_calculator
    signal fb_sample : t_channel_record := (
        value => (others => '0'),
        row_num => 0,
        valid => '0'
    );

    -- feedback reader -> dual ram
    signal read_address : natural := 0;
    signal read_data : t_word := (others => '0');

    -- feedback reader -> channel mux
    signal sa_fb_data : std_logic_vector(15 downto 0) := (others => '0');

    -- channels -> frame_builder
    signal channels_data : t_channel_record_array := (
        others => (
            value => (others => '0'),
            valid => '0',
            row_num => 0
        )
    );
    -- frame_builder -> packet_sender
    signal send_data_packet         : std_logic := '0';
    signal data_packet_payload_size : natural := 0;
    signal data_packet_payload      : t_packet_payload := (others => (others => '0'));

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
    signal tes_bias         : t_param_array(0 to PARAM_ID_TO_SIZE(BIAS_ID) - 1) := (others => (others => '0'));
    signal ret_data_s       : t_param_array(0 to PARAM_ID_TO_SIZE(RET_DATA_S_ID) - 1) := (others => (others => '0'));
    signal data_rate        : t_param_array(0 to PARAM_ID_TO_SIZE(DATA_RATE_ID) - 1) := (others => (others => '0'));
    signal num_cols         : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_COLS_REP_ID) - 1) := (others => (others => '0'));

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
        wait for 20 ns;

        wait for PACKET_DELAY;

    end process;

    command_handler_module : entity concept.command_handler
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

            data_mode           => to_integer(unsigned(data_mode(0))),
            servo_mode          => to_integer(unsigned(servo_mode(0))),
            fb_dly              => to_integer(unsigned(fb_dly(0))),

            new_row             => new_row,
            acquisition_on      => acquisition_on,
            frame_active        => frame_active,
            set_SF              => set_SF,
            set_SB              => set_SB,
            set_FF              => set_FF,
            set_FB              => set_FB,

            DAC_start_pulse     => open,
            DAC_address         => open,
            line_sel            => open,
            data_sel            => open
        );

    row_selector_module : entity concept.row_selector
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,
                               
            sync_frame      => sync_frame,
            acquisition_on  => acquisition_on,
            num_rows        => to_integer(unsigned(num_rows(0))),
            row_len         => to_integer(unsigned(row_len(0))),
                               
            new_row         => new_row,
            row_num         => row_num,
            frame_active    => frame_active
        );

    row_activator_module : entity concept.row_activator
        port map(
            clk                 => sys_clk_5,
            rst                 => sys_rst,

            new_row             => new_row,
            row_num             => row_num,
            acquisition_on      => acquisition_on,
            on_bias             => on_bias,
            off_bias            => off_bias,
            num_rows            => to_integer(unsigned(num_rows(0))),
            update_off_value    => update_off_value, 
            DAC_start_pulse     => open,
            DAC_sel             => open,
            DAC_data            => open
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
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            cnv_len         => to_integer(unsigned(cnv_len(0))),
            sck_dly         => to_integer(unsigned(sck_dly(0))),
            sck_half_period => to_integer(unsigned(sck_half_period(0))),

            start_pulse     => ADC_start_pulse,

            CNV             => adc_cnv,
            SCK             => adc_sck
        );



    ADC_simulator_0 : entity concept.ADC_simulator
        port map(
            clk     => sys_clk_100,
            rst     => sys_rst,
                    
            nCNV    => adc_cnv,
            SCK     => adc_sck,
            data    => adc_sim_data_0,
                    
            SDO     => adc_sdo_0
        );


    ddr_input_module : entity concept.ddr_input
        port map(
            clock        => sys_clk_100,
            reset        => sys_rst,

            output_en    => '1',
            ddr_in       => adc_sdo_0,
            parallel_out => ddr_parallel
        );

    fall_edge_detector_CNV : entity concept.FallEdgeDetector
        port map (
            clk             => sys_clk_100,
            rst             => sys_rst,
            signal_in       => adc_cnv,
            signal_out      => cnv_fall_pulse
        );
    
    input_shift_register_module : entity concept.input_shift_register
        port map(
            clk                     => sys_clk_100,
            rst                     => sys_rst,

            serial_clk              => adc_sck,
            iddr_parallel_output    => ddr_parallel,
            conv_started            => cnv_fall_pulse,
            valid_word              => valid_word,
            parallel_data           => parallel_data
        );

    sample_selector_module : entity concept.sample_selector
        port map(
            clk                     => sys_clk_100,
            rst                     => sys_rst,

            sample_dly              => to_integer(unsigned(sample_dly(0))),
            sample_num              => to_integer(unsigned(sample_num(0))),
            new_row                 => new_row,
            valid_word              => valid_word,
            parallel_data           => parallel_data,
            valid_sample            => valid_sample,
            sample_data             => sample_data
        );

    sample_accumulator_module : entity concept.sample_accumulator
        port map(
            clk                     => sys_clk_100,
            rst                     => sys_rst,

            sample_num              => to_integer(unsigned(sample_num(0))),
            valid_sample            => valid_sample,
            sample                  => sample_data,
            row_num                 => row_num,
            acc_sample              => acc_sample
        );

    pulse_stretcher : entity concept.pulse_stretcher
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,

            fast_pulse          => acc_sample.valid,
            stretched_pulse     => acc_sample_stretched.valid
        );

    acc_sample_stretched.value      <= acc_sample.value;
    acc_sample_stretched.row_num    <= acc_sample_stretched.row_num;

    feedback_calculator_module : entity concept.feedback_calculator
        port map(
            clk                 => sys_clk_5,
            rst                 => sys_rst,

            acc_sample          => acc_sample_stretched,
            sa_fb_gain          => to_integer(signed(gain_0(0))),
            fb_sample           => fb_sample
        );

    bram_dual_wrapper_module : entity concept.bram_dual_wrapper
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,

            write_address   => fb_sample.row_num,
            write_data      => fb_sample.value,
            write_pulse     => fb_sample.valid,
            read_address    => read_address,
            read_data       => read_data
        );
    
    feedback_reader_module : entity concept.feedback_reader
        port map(
            clk             => sys_clk_5,
            rst             => sys_rst,

            new_row         => new_row,
            row_num         => row_num,
            num_rows        => to_integer(unsigned(num_rows(0))),

            read_address    => read_address,
            read_data       => read_data,

            sa_fb_data      => sa_fb_data
        );

    TES_bias_setter_module : entity concept.TES_bias_setter
        port map(
            clk                     => sys_clk_5,
            rst                     => sys_rst,

            set_bias                => set_TES_bias,
            TES_bias                => tes_bias,
            DAC_start_pulse         => open,
            DAC_data                => open
        );

    channels_data(0) <= fb_sample;

    frame_builder_module : entity concept.frame_builder
        port map(
            clk                     => sys_clk_5,
            rst                     => sys_rst,

            -- Param buffers
            ret_data_setup          => ret_data_s,
            data_rate               => to_integer(unsigned(data_rate(0))),
            num_rows                => to_integer(unsigned(num_rows(0))),
            num_cols                => to_integer(unsigned(num_cols(0))),
            row_len                 => to_integer(unsigned(row_len(0))),

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
            param_id            => DATA_MODE_ID
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
            param_id            => SERVO_MODE_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => servo_mode
        );

    -- FB_DLY_ID
    fb_dly_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(FB_DLY_ID),
            param_id            => FB_DLY_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => fb_dly
        );

    -- NUM_ROWS_ID
    num_rows_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(NUM_ROWS_ID),
            param_id            => NUM_ROWS_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => num_rows
        );

    -- ROW_LEN_ID
    row_len_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(ROW_LEN_ID),
            param_id            => ROW_LEN_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => row_len
        );

    -- ON_BIAS_ID
    on_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(ON_BIAS_ID),
            param_id            => ON_BIAS_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => on_bias
        );

    -- OFF_BIAS_ID
    off_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(OFF_BIAS_ID),
            param_id            => OFF_BIAS_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => off_bias
        );

    -- CNV_LEN_ID
    cnv_len_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(CNV_LEN_ID),
            param_id            => CNV_LEN_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => cnv_len
        );

    -- SCK_DLY_ID
    sck_dly_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SCK_DLY_ID),
            param_id            => SCK_DLY_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sck_dly
        );

    -- SCK_HALF_PERIOD_ID
    sck_half_period_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SCK_HALF_PERIOD_ID),
            param_id            => SCK_HALF_PERIOD_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sck_half_period
        );

    -- SAMPLE_DLY_ID
    sample_dly_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SAMPLE_DLY_ID),
            param_id            => SAMPLE_DLY_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sample_dly
        );

    -- SAMPLE_NUM_ID
    sample_num_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SAMPLE_NUM_ID),
            param_id            => SAMPLE_NUM_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => sample_num
        );

    -- GAIN_0_ID
    gain_0_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(GAIN_0_ID),
            param_id            => GAIN_0_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => gain_0
        );

    -- BIAS_ID
    tes_bias_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(BIAS_ID),
            param_id            => BIAS_ID
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
            param_id            => RET_DATA_S_ID
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
            param_id            => DATA_RATE_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => data_rate
        );

    -- NUM_COLS_REP_ID
    num_cols_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(NUM_COLS_REP_ID),
            param_id            => NUM_COLS_REP_ID
        )                       
        port map(               
            clk                 => sys_clk_5,
            rst                 => sys_rst,
                                
            update              => update_param_pulse,
            param_id_to_update  => param_id_to_update,
            update_data         => param_data,
            default_value       => (others => (others => '0')),
            param_data          => num_cols
        );

end Behavioral;
