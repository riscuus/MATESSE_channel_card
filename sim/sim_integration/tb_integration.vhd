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
    constant PACKET_DELAY       : time := 1500 us; -- Time between trying a new packet
    constant SIM_DURATION       : time := 200 ms;

    -- Clock
    signal sys_clk_100  : std_logic;
    signal sys_clk_5    : std_logic;
    signal sys_rst      : std_logic;

    -- External
    signal sync_frame : std_logic := '0';
    
    -- tb -> PC packet builder
    signal PC_packet_type       : t_packet_type := undefined;
    signal PC_card_id           : t_half_word := (others => '0');
    signal PC_param_id          : t_half_word := (others => '0');
    signal PC_cmd_type          : t_packet_type := undefined;
    signal PC_err_ok            : std_logic := '0';
    signal PC_payload_size      : natural := 0;
    signal PC_packet_payload    : t_packet_payload := (others => (others => '0'));
    signal PC_params_valid      : std_logic := '0';
    
    -- PC builder <-> PC uart module
    signal PC_send_byte         : std_logic := '0';
    signal PC_byte_data         : t_byte := (others => '0');
    signal PC_builder_ready     : std_logic := '0';
    signal PC_tx_busy           : std_logic := '0';

    -- PC uart module -> FPGA RX uart module
    signal rx_uart_serial : std_logic := '0';

    -- FPGA RX uart module <-> packet parser
    signal rx_busy      : std_logic := '0';
    signal rx_byte_data : t_byte := (others => '0');

    -- packet parser -> cmd_handler
    signal parser_packet_type       : t_packet_type := cmd_wb;
    signal parser_card_id           : t_half_word := DAUGHTER_CARD_ID;
    signal parser_param_id          : t_half_word := "0000000011111111";
    signal parser_cmd_type          : t_packet_type := undefined;
    signal parser_err_ok            : std_logic := '0';
    signal parser_payload_size      : natural := 0;
    signal parser_packet_payload    : t_packet_payload := (others => (others => '0'));
    signal parser_params_valid      : std_logic := '0';

    -- command_handler <-> RAM
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

    -- packet_sender <-> packet_builder
    signal packet_type      : t_packet_type := undefined;
    signal card_id          : t_half_word := (others => '0');
    signal param_id         : t_half_word := (others => '0');
    signal cmd_type         : t_packet_type := undefined;
    signal err_ok           : std_logic := '0';
    signal payload_size     : natural := 0;
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

    -- channels DAC
    signal channels_DAC_CS      : std_logic := '0';
    signal channels_DAC_CLK     : std_logic := '0';
    signal channels_DAC_LDAC    : std_logic := '0';

    -- row_selector signals
    signal new_row      : std_logic := '0';
    signal row_num      : natural   := 0;
    signal frame_active : std_logic := '0';

    -- row_activator signals
    signal row_activator_DAC_start_pulse    : std_logic := '0';
    signal row_activator_DAC_sel            : unsigned(bits_req(NUM_ROW_DACS) - 1 downto 0) := (others => '0');
    signal row_activator_DAC_data           : std_logic_vector(DAC_DATA_SIZE + DAC_ADDR_SIZE - 1 downto 0) := (others => '0');

    -- row_activator_DAC_gate_controller signals
    signal row_activator_DAC_CS     : std_logic := '0';
    signal row_activator_DAC_CLK    : std_logic := '0';
    signal row_activator_DAC_LDAC   : std_logic := '0';

    -- ADC_triggerer -> ADC_gate_controller
    signal ADC_start_pulse : std_logic := '0';

    -- ADC_gate_controller -> ADC_simulator
    signal adc_cnv  : std_logic := '0';
    signal adc_sck  : std_logic := '0';

    -- ADC_simulators signals
    type t_16_bit_data_array is array(0 to MAX_CHANNELS - 1) of std_logic_vector(15 downto 0);
    signal adc_sim_data     :  t_16_bit_data_array := (others => (others => '0'));
    signal adc_sdo          : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');

    -- ddr_input -> input_shift_register
    type ddr_parallel_array is array(0 to MAX_CHANNELS - 1) of std_logic_vector(1 downto 0);
    signal ddr_parallel     : ddr_parallel_array := (others => (others=> '0'));

    -- fall_edge_dector (cnv) -> input_shift_register
    signal cnv_fall_pulse : std_logic := '0';

    -- input_shift_register -> sample_selector
    signal valid_word    : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');
    signal parallel_data : t_16_bit_data_array := (others =>(others => '0'));

    -- sample_selector -> sample_accumulator
    signal valid_sample : std_logic_vector(MAX_CHANNELS - 1 downto 0) := (others => '0');
    signal sample_data  : t_16_bit_data_array := (others => (others => '0'));
    

    -- sample_accumulator -> feedback calculator
    signal acc_sample : t_channel_record_array := (
        others => (
            value => (others => '0'),
            row_num => 0,
            valid => '0'
        )
    );

    signal acc_sample_stretched : t_channel_record_array := (
        others => (
            value => (others => '0'),
            row_num => 0,
            valid => '0'
        )
    );

    -- feedback_calculator
    signal fb_sample : t_channel_record_array := (
        others => (
            value => (others => '0'),
            row_num => 0,
            valid => '0'
        )
    );

    -- feedback reader -> dual ram
    type read_address_array is array(0 to MAX_CHANNELS - 1) of natural;
    signal read_address : read_address_array := (others => 0);
    type t_word_array is array(0 to MAX_CHANNELS - 1) of t_word;
    signal read_data : t_word_array := (others => (others => '0'));

    -- feedback reader -> channel mux
    signal sa_fb_data : t_16_bit_data_array := (others => (others => '0'));

    -- channel mux -> data serializer
    type t_channels_line_data_array is array(0 to MAX_CHANNELS - 1) of std_logic_vector(DAC_DATA_SIZE - 1 downto 0);
    signal channels_line_data : t_channels_line_data_array := (others => (others => '0'));

    -- channels readout -> frame_builder
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

    -- TES_bias_setter signals
    signal TES_bias_DAC_start_pulse : std_logic := '0';
    signal TES_bias_DAC_data : std_logic_vector(DAC_DATA_SIZE + DAC_ADDR_SIZE - 1 downto 0) := (others => '0');

    -- TES_bias_DAC_gate_controller signals
    signal TES_bias_DAC_CS      : std_logic := '0';
    signal TES_bias_DAC_CLK     : std_logic := '0';
    signal TES_bias_DAC_LDAC    : std_logic := '0';

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

    -- Test cases
    packet_params_generation : process
    begin
        -- Wait for rst
        wait for RST_START + RST_PULSE_LENGTH + 100 ns;

        -- #1: wrong card_id
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= x"0f0f"; -- wrong
        PC_param_id         <= x"00ff";
        PC_payload_size     <= 2;
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';

        wait for PACKET_DELAY;

        -- #2: wrong packet_type (we cmd_handler only accepts commands)
        PC_packet_type      <= reply; -- wrong
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= x"00ff";
        PC_payload_size     <= 5;
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';

        wait for PACKET_DELAY;

        -- #3: wrong param_id
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= x"00ff"; -- wrong
        PC_payload_size     <= 5;
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';

        wait for PACKET_DELAY;

        -- #4: Wrong payload size (parser will not accept 0 length payload)
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(ON_BIAS_ID, parser_param_id'length));
        PC_payload_size     <= 0; -- Wrong
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #5: Wrong payload size (it does not coincide with the specified size of this parameter, cmd handler should not accept it)
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(ON_BIAS_ID, parser_param_id'length));
        PC_payload_size     <= 3; -- Wrong
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #6: Good write
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(ON_BIAS_ID, parser_param_id'length));
        PC_payload_size     <= MAX_ROWS; 
        PC_packet_payload   <= (0  => x"0f0f0f00", 
                                1  => x"0f0f0f01",
                                2  => x"0f0f0f02",
                                3  => x"0f0f0f03",
                                4  => x"0f0f0f04",
                                5  => x"0f0f0f05",
                                6  => x"0f0f0f06",
                                7  => x"0f0f0f07",
                                8  => x"0f0f0f08",
                                9  => x"0f0f0f09",
                                10 => x"0f0f0f10",
                                11 => x"0f0f0f11",
                                others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #7: Good read
        PC_packet_type      <= cmd_rb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(ON_BIAS_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #8: Wrong start acquisition (Wrong parameter)
        PC_packet_type      <= cmd_go;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(ON_BIAS_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #9: Wrong start acquisition (Good address but no previous setup)
        PC_packet_type      <= cmd_go;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(RET_DATA_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #10: Wrong stop acquisition (acquisition_on = '0')
        PC_packet_type      <= cmd_st;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(RET_DATA_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #11: Set acquisition config 
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(RET_DATA_S_ID, parser_param_id'length));
        PC_payload_size     <= 2; 
        PC_packet_payload   <= (0 => std_logic_vector(to_unsigned(3, t_word'length)), 
                                1 => std_logic_vector(to_unsigned(6, t_word'length)),
                                others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #12: Good start acquisition (with current parameters it should last around 6000us until the last frame put in module, and 7500 until it is sent)
        PC_packet_type      <= cmd_go;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(RET_DATA_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #13: Good write but has to be ignored because acquisition is on
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(ON_BIAS_ID, parser_param_id'length));
        PC_payload_size     <= 8; 
        PC_packet_payload   <= (0 => x"0f0f0f00", 
                                    1 => x"0f0f0f01",
                                    2 => x"0f0f0f02",
                                    3 => x"0f0f0f03",
                                    4 => x"0f0f0f04",
                                    5 => x"0f0f0f05",
                                    6 => x"0f0f0f06",
                                    7 => x"0f0f0f07",
                                    others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        ---- #14: Bad write but has to be ignored because acquisition is on (wrong param id)
        --PC_packet_type      <= cmd_wb;
        --PC_card_id          <= DAUGHTER_CARD_ID;
        --PC_param_id         <= x"00ff"; -- wrong
        --PC_payload_size     <= 1;
        --PC_packet_payload   <= (others => (others => '0'));

        --wait for DATA_SETUP;
        --PC_params_valid <= '1';
        --wait for PARAMS_VALID_HIGH;
        --PC_params_valid <= '0';
        --wait for PACKET_DELAY;


        -- #15: bad start acquisition (acq already on)
        PC_packet_type      <= cmd_go;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(RET_DATA_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for 2 * PACKET_DELAY;

        -- #16: Good start acquisition (But sender still busy)
        PC_packet_type      <= cmd_go;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(RET_DATA_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for 2 * PACKET_DELAY;

        -- #17: Good stop (It should finish before last frame and set the corresponding bits)
        PC_packet_type      <= cmd_st;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= x"0016";
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #18: Good write sa fb cte 
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(SA_FB_ID, PC_param_id'length));
        PC_payload_size     <= PARAM_ID_TO_SIZE(SA_FB_ID); 
        PC_packet_payload   <= (0 => x"01010100", 1 => x"01010101", others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #19: Good write sa bias cte 
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(SA_BIAS_ID, PC_param_id'length));
        PC_payload_size     <= PARAM_ID_TO_SIZE(SA_BIAS_ID); 
        PC_packet_payload   <= (0 => x"0000F1F0", 1 => x"0000F1F1", others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        
        -- #20: Good write (set ch0 -> servo_mode_const, ch1 -> servo_mode_PID)
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(SERVO_MODE_ID, PC_param_id'length));
        PC_payload_size     <= PARAM_ID_TO_SIZE(SERVO_MODE_ID); 
        PC_packet_payload   <= (0 => std_logic_vector(to_unsigned(SERVO_MODE_CONST, t_word'length)), 
                                1 => std_logic_vector(to_unsigned(SERVO_MODE_PID, t_word'length)), 
                                others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #21: Good write TES bias 
        PC_packet_type      <= cmd_wb;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(BIAS_ID, PC_param_id'length));
        PC_payload_size     <= PARAM_ID_TO_SIZE(BIAS_ID); 
        PC_packet_payload   <= (0 => x"FFFFFFF0", 1 => x"FFFFFFF1", 2 => x"FFFFFFF2", 3 => x"FFFFFFF3", others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for PACKET_DELAY;

        -- #22: Good start acquisition
        PC_packet_type      <= cmd_go;
        PC_card_id          <= DAUGHTER_CARD_ID;
        PC_param_id         <= std_logic_vector(to_unsigned(RET_DATA_ID, parser_param_id'length));
        PC_payload_size     <= 1; 
        PC_packet_payload   <= (others => (others => '0'));

        wait for DATA_SETUP;
        PC_params_valid <= '1';
        wait for PARAMS_VALID_HIGH;
        PC_params_valid <= '0';
        wait for 2 * PACKET_DELAY;

        --wait for 200 ns;
        --wait for 20 ns;

        --wait for PACKET_DELAY;
        wait;

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
            byte_data       => PC_byte_data,
            builder_ready   => PC_builder_ready
        );

    -- (PC) TX uart module
    PC_uart_module : entity concept.uart_controller
        port map(
            clk          => sys_clk_100,
            rst          => sys_rst,

            tx_ena       => PC_send_byte,
            tx_data      => PC_byte_data,
            rx           => '0',
            rx_busy      => open,
            rx_error     => open,
            rx_data      => open,
            tx_busy      => PC_tx_busy,
            tx           => rx_uart_serial
        );
    
    -- (FPGA) RX uart module
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
            tx          => open
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
            fb_dly              => to_integer(unsigned(fb_dly(0))),

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
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,
            
            start_conv_pulse    => channels_ctr_DAC_start_pulse,
            CS                  => channels_DAC_CS,
            SCLK                => channels_DAC_CLK,
            LDAC                => channels_DAC_LDAC
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
            DAC_start_pulse     => row_activator_DAC_start_pulse,
            DAC_sel             => row_activator_DAC_sel,
            DAC_data            => row_activator_DAC_data
        );

    row_activator_DAC_gate_ctrl : entity concept.DAC_gate_controller
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,
            
            start_conv_pulse    => row_activator_DAC_start_pulse,
            CS                  => row_activator_DAC_CS,
            SCLK                => row_activator_DAC_CLK,
            LDAC                => row_activator_DAC_LDAC
        );

    -- TODO: implement demux for row_activator CS
    
    row_activator_data_serializer : entity concept.data_serializer_wrapper
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            gate_read       => row_activator_DAC_CS,
            data_clk        => row_activator_DAC_CLK,
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

    fall_edge_detector_CNV : entity concept.FallEdgeDetector
        port map (
            clk             => sys_clk_100,
            rst             => sys_rst,
            signal_in       => adc_cnv,
            signal_out      => cnv_fall_pulse
        );

    gain_array(0) <= gain_0; 
    gain_array(1) <= gain_1;

    channels_readout : for i in 0 to MAX_CHANNELS - 1 generate

        ADC_simulator : entity concept.ADC_simulator
            port map(
                clk     => sys_clk_100,
                rst     => sys_rst,
                        
                nCNV    => adc_cnv,
                SCK     => adc_sck,
                data    => adc_sim_data(i),
                        
                SDO     => adc_sdo(i)
            );


        ddr_input_module : entity concept.ddr_input
            port map(
                clock        => adc_sck,
                reset        => sys_rst,

                output_en    => '1',
                ddr_in       => adc_sdo(i),
                parallel_out => ddr_parallel(i)
            );

        
        input_shift_register_module : entity concept.input_shift_register
            port map(
                clk                     => sys_clk_100,
                rst                     => sys_rst,

                serial_clk              => adc_sck,
                iddr_parallel_output    => ddr_parallel(i),
                conv_started            => adc_cnv,
                valid_word              => valid_word(i),
                parallel_data           => parallel_data(i)
            );

        sample_selector_module : entity concept.sample_selector
            port map(
                clk                     => sys_clk_100,
                rst                     => sys_rst,

                sample_dly              => to_integer(unsigned(sample_dly(0))),
                sample_num              => to_integer(unsigned(sample_num(0))),
                new_row                 => new_row,
                valid_word              => valid_word(i),
                parallel_data           => parallel_data(i),
                valid_sample            => valid_sample(i),
                sample_data             => sample_data(i)
            );

        sample_accumulator_module : entity concept.sample_accumulator
            port map(
                clk                     => sys_clk_100,
                rst                     => sys_rst,

                sample_num              => to_integer(unsigned(sample_num(0))),
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
                sa_fb_gain          => to_integer(signed(gain_array(i)(0))),
                fb_sample           => fb_sample(i)
            );

        bram_dual_wrapper_module : entity concept.bram_dual_wrapper
            port map(
                clk             => sys_clk_5,
                rst             => sys_rst,

                write_address   => fb_sample(i).row_num,
                write_data      => fb_sample(i).value,
                write_pulse     => fb_sample(i).valid,
                read_address    => read_address(i),
                read_data       => read_data(i)
            );
        
        feedback_reader_module : entity concept.feedback_reader
            port map(
                clk             => sys_clk_5,
                rst             => sys_rst,

                new_row         => new_row,
                row_num         => row_num,
                num_rows        => to_integer(unsigned(num_rows(0))),

                read_address    => read_address(i),
                read_data       => read_data(i),

                sa_fb_data      => sa_fb_data(i)
            );

        channel_mux : entity concept.mux
            generic map(
                DATA_SIZE   => DAC_DATA_SIZE,
                SEL_SIZE    => LINE_SEL_SIZE -- Req bits for 6 inputs (calc_fb, ramp, SF, SB, FF, FB)
            )             
            port map(     
                selector                                                                                            => channels_line_selector(i),
                data_in(1 * DAC_DATA_SIZE - 1 downto 0 * DAC_DATA_SIZE)                                             => sa_fb_data(i),
                data_in(2 * DAC_DATA_SIZE - 1 downto 1 * DAC_DATA_SIZE)                                             => (others => '0'), -- Ramp not implemented yet
                data_in(3 * DAC_DATA_SIZE - 1 downto 2 * DAC_DATA_SIZE)                                             => sa_fb_cte(i)(DAC_DATA_SIZE - 1 downto 0),
                data_in(4 * DAC_DATA_SIZE - 1 downto 3 * DAC_DATA_SIZE)                                             => sa_bias_cte(i)(DAC_DATA_SIZE - 1 downto 0),
                data_in(5 * DAC_DATA_SIZE - 1 downto 4 * DAC_DATA_SIZE)                                             => sq1_fb_cte(i)(DAC_DATA_SIZE - 1 downto 0),
                data_in(6 * DAC_DATA_SIZE - 1 downto 5 * DAC_DATA_SIZE)                                             => sq1_bias_cte(i)(DAC_DATA_SIZE - 1 downto 0),
                data_in(total_inputs(bits_req(NUM_CHANNEL_LINES)) * DAC_DATA_SIZE - 1 downto 6 * DAC_DATA_SIZE)    => (others => '0'),
                data_out                                                                                            => channels_line_data(i)
            );

        channel_data_serializer : entity concept.data_serializer_wrapper
            port map(
                clk             => sys_clk_100,
                rst             => sys_rst,

                gate_read                                                               => channels_DAC_CS,
                data_clk                                                                => channels_DAC_CLK,
                valid                                                                   => '1',
                parallel_data(DAC_DATA_SIZE - 1 downto 0)                               => channels_line_data(i),
                parallel_data(DAC_DATA_SIZE + DAC_ADDR_SIZE - 1 downto DAC_DATA_SIZE)   => channels_DAC_addr,
                busy_flag                                                               => '0',
                DAC_start_pulse                                                         => channels_ctr_DAC_start_pulse,
                serial_data                                                             => open
            );

    end generate;

    TES_bias_setter_module : entity concept.TES_bias_setter
        port map(
            clk                     => sys_clk_5,
            rst                     => sys_rst,

            set_bias                => set_TES_bias,
            TES_bias                => tes_bias,
            DAC_start_pulse         => TES_bias_DAC_start_pulse,
            DAC_data                => TES_bias_DAC_data
        );

    TES_bias_DAC_gate_controller : entity concept.DAC_gate_controller
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,
            start_conv_pulse    => TES_bias_DAC_start_pulse,
            CS                  => TES_bias_DAC_CS,
            SCLK                => TES_bias_DAC_CLK,
            LDAC                => TES_bias_DAC_LDAC 
        );

    TES_bias_data_serializer : entity concept.data_serializer_wrapper
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            gate_read       => TES_bias_DAC_CS,
            data_clk        => TES_bias_DAC_CLK,
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
            default_value       => SERVO_MODE_DEF,
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
            default_value       => FB_DLY_DEF,
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
            default_value       => NUM_ROWS_DEF,
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
            default_value       => ROW_LEN_DEF,
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
            default_value       => ON_BIAS_DEF,
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
            default_value       => OFF_BIAS_DEF,
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
            default_value       => CNV_LEN_DEF,
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
            default_value       => SCK_DLY_DEF,
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
            default_value       => SCK_HALF_PERIOD_DEF,
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
            default_value       => SAMPLE_DLY_DEF,
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
            default_value       => SAMPLE_NUM_DEF,
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
            default_value       => GAIN_0_DEF,
            param_data          => gain_0
        );

    -- GAIN_1_ID
    gain_1_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(GAIN_1_ID),
            param_id            => GAIN_1_ID
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
            default_value       => DATA_RATE_DEF,
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
            default_value       => NUM_COLS_REP_DEF,
            param_data          => num_cols
        );

    -- SA_FB_ID
    sa_fb_buffer : entity concept.param_buffer
        generic map(
            param_size          => PARAM_ID_TO_SIZE(SA_FB_ID),
            param_id            => SA_FB_ID
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
            param_id            => SA_BIAS_ID
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
            param_id            => SQ1_FB_ID
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
            param_id            => SQ1_BIAS_ID
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
