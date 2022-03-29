----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03.14.2022
-- Module Name: test_ADC.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Top module to be able to test the correct functionality of the ADC components. The objective is to
--              create a loopback from the voltage generated through the DACs to the ADCs and prove that we can
--              correctly read its values. Ideally we should be able to generate a triangular signal in a DAC, 
--              send it to an ADC, read it and send it again to a DAC to visualize it in the oscilloscope.
--              Another option is to just read it trough the ila interface and prove that the values make sense.
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
use IEEE.numeric_std.all;


library concept;
use concept.all;


entity test_ADC is
    port ( 
        sys_clk              : in std_logic;
        sys_rst              : in std_logic;
        -- Enabling signals
        DAC_enabled          : in std_logic;
        ADC_enabled          : in std_logic;
        -- Buttons
        btn0                 : in std_logic;
        btn1                 : in std_logic;
        btn2                 : in std_logic;
        btn3                 : in std_logic;
        -- DAC U0 (Channel 0)
        DAC_SDI_IO6          : out std_logic;
        -- DAC U1 (Channel 1)
        DAC_SDI_IO30         : out std_logic;
        -- DAC U0, U1 shared
        DAC_LD_IO3           : out std_logic;
        DAC_CS_IO4           : out std_logic;
        DAC_CK_IO5           : out std_logic;
        -- DAC U20 (Row Operations)
        DAC_CS_IO8           : out std_logic;
        -- DAC U21 (Row Operations)
        DAC_CS_IO9           : out std_logic;
        -- DAC U22 (Row Operations)
        DAC_CS_IO10          : out std_logic;
        -- DAC U20, U21, U22 shared 
        DAC_LD_IO7           : out std_logic;
        DAC_CK_IO11          : out std_logic;
        DAC_SDI_IO12         : out std_logic;
        -- DAC U23 (Bias)
        DAC_SDI_IO28         : out std_logic;
        DAC_LD_IO13          : out std_logic;
        DAC_CS_IO26          : out std_logic;
        DAC_CK_IO27          : out std_logic;
        -- ADC control signals
        ADC_CNV_IO0          : out std_logic;
        ADC_SCK_IO1          : out std_logic;
        ADC_SDO_IO2          : in std_logic

        --DAC_send_pulse       : in std_logic;
        --DAC_selector_signal  : in std_logic_vector(2 downto 0)
    );

end test_ADC;

architecture Behavioral of test_ADC is

    -- DAC SPI communication
    signal DAC_LDAC_signal  : std_logic := '1';
    signal DAC_CS_signal    : std_logic := '1';
    signal DAC_CK_signal    : std_logic := '0';
    signal DAC_SDI_signal   : std_logic := '0';

    -- DAC Intermediate signals for selectors
    signal DAC_SDI_row_select1  : std_logic := '0';
    signal DAC_SDI_row_select2  : std_logic := '0';
    signal DAC_SDI_row_select3  : std_logic := '0';
    signal DAC_CS_channel0      : std_logic := '1';
    signal DAC_CS_channel1      : std_logic := '1';
    signal DAC_CK_channel0      : std_logic := '0';
    signal DAC_CK_channel1      : std_logic := '0';
    signal DAC_CK_row_select1   : std_logic := '0';
    signal DAC_CK_row_select2   : std_logic := '0';
    signal DAC_CK_row_select3   : std_logic := '0';
    signal DAC_LD_channel0      : std_logic := '1';
    signal DAC_LD_channel1      : std_logic := '1';
    signal DAC_LD_row_select1   : std_logic := '1';
    signal DAC_LD_row_select2   : std_logic := '1';
    signal DAC_LD_row_select3   : std_logic := '1';

    -- DAC data serializer
    signal busy_flag            : std_logic := '0';

    -- ADC communication
    signal ADC_start_pulse      : std_logic := '0';
    signal ADC_SCK_signal       : std_logic := '0';
    signal ADC_CNV_signal       : std_logic := '1';
    signal ADC_SDO_signal       : std_logic := '0';

    -- ADC input shift register signals
    signal parallel_ddr_data    : std_logic_vector(1 downto 0) := (others => '0');
    signal CNV_fall_pulse       : std_logic := '0';
    signal valid_word           : std_logic := '0';
    signal parallel_word_data   : std_logic_vector(15 downto 0) := (others => '0');

    -- Volatge generator signals
        -- In this test code we have two ways of generating different volatge values for the DACs, one is by 
        -- clicking the btns in the ARTY board, this modifies all the DACs values, 
        -- another is by setting via VIO a custom value for an specific DAC

        -- 19 --> DAC_start_pulse
        -- 18 --> data_valid
        -- 17 dowto 0 --> parallel_data (address + voltage data)
    signal btn_voltage_signals          : std_logic_vector(19 downto 0) := (others => '0');
    signal custom_voltage_signals       : std_logic_vector(19 downto 0) := (others => '0');
    signal function_voltage_signals     : std_logic_vector(19 downto 0) := (others => '0');
    signal voltage_signals              : std_logic_vector(19 downto 0) := (others => '0');

    -- Signals that will be controlled by the VIO
    signal generator_sel            : std_logic_vector(1 downto 0) := "01";
    signal DAC_voltage              : std_logic_vector(15 downto 0) := "0101001010100101";
    signal DAC_address              : std_logic_vector(1 downto 0) := "10";
    signal DAC_send_pulse           : std_logic := '0';
    signal DAC_selector_signal      : std_logic_vector(2 downto 0) := (others => '0');
    signal DAC_function_amplitude   : std_logic_vector(6 downto 0) := (others => '0');
    signal DAC_function_offset      : std_logic_vector(15 downto 0) := (others => '0');
    signal cnv_length_signal        : std_logic_vector(3 downto 0) := "0100";
    signal sck_delay_signal         : std_logic_vector(3 downto 0) := "0100";
    signal sck_half_period_signal   : std_logic_vector(3 downto 0) := "0001";

    -- Signals to keep for debugging
    attribute keep : string;
    attribute keep of parallel_word_data    : signal is "true";
    attribute keep of voltage_signals       : signal is "true";

    -- Component declarations
    component vio_test_adc
        port (
            clk        : in std_logic;
            probe_out0 : out std_logic_vector(1 downto 0);
            probe_out1 : out std_logic_vector(15 downto 0);
            probe_out2 : out std_logic_vector(1 downto 0);
            probe_out3 : out std_logic_vector(0 downto 0);
            probe_out4 : out std_logic_vector(2 downto 0);
            probe_out5 : out std_logic_vector(6 downto 0);
            probe_out6 : out std_logic_vector(15 downto 0);
            probe_out7 : out std_logic_vector(3 downto 0);
            probe_out8 : out std_logic_vector(3 downto 0);
            probe_out9 : out std_logic_vector(3 downto 0)
        );
    end component;


begin

    ----- OUTPUTS ASSIGMENTS -----

    -- ADC control signals
    ADC_CNV_IO0     <= ADC_CNV_signal;
    ADC_SCK_IO1     <= ADC_SCK_signal;
    ADC_SDO_signal  <= ADC_SDO_IO2;


    ---- SUBCOMPONENTS DECLARATIONS ----

    -- DAC Controller

    DAC_controller : entity concept.DAC_controller
        port map(
            clock               => sys_clk,
            rst                 => sys_rst,
            start_conv_pulse    => voltage_signals(19),
            CS                  => DAC_CS_signal,
            CLK                 => DAC_CK_signal,
            LDAC                => DAC_LDAC_signal
        );

    -- DAC voltage generators

    DAC_btn_voltage_generator : entity concept.DAC_voltage_generator
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            enabled             => DAC_enabled,
            v0_pulse            => btn0,
            v1_pulse            => btn1,
            v2_pulse            => btn2,
            v3_pulse            => btn3,
            parallel_data       => btn_voltage_signals(17 downto 0),
            data_valid          => btn_voltage_signals(18),
            DAC_start_pulse     => btn_voltage_signals(19)
        );

    DAC_custom_voltage_generator : entity concept.custom_voltage_generator
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            address             => DAC_address,
            voltage             => DAC_voltage,
            send_pulse          => DAC_send_pulse,
            parallel_data       => custom_voltage_signals(17 downto 0),
            data_valid          => custom_voltage_signals(18),
            DAC_start_pulse     => custom_voltage_signals(19)
        );

    DAC_function_generator : entity concept.function_generator
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            enabled             => DAC_enabled,
            address             => DAC_address,
            amplitude           => unsigned(DAC_function_amplitude),
            offset              => DAC_function_offset,
            DAC_start_pulse     => function_voltage_signals(19),
            data_valid          => function_voltage_signals(18),
            parallel_data       => function_voltage_signals(17 downto 0)
        );

    -- Multiplexer to choose between btn or custom volatge
    generator_selector : entity concept.mux3x20
        port map(
            sel     => generator_sel,
            a1      => btn_voltage_signals,
            a2      => custom_voltage_signals,
            a3      => function_voltage_signals,
            b       => voltage_signals
        );

    -- DAC data serializer
    data_serializer_wrapper : entity concept.data_serializer_wrapper
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            gate_read           => DAC_CS_signal,
            data_clk            => DAC_CK_signal,
            valid               => voltage_signals(18), 
            parallel_data       => voltage_signals(17 downto 0),
            busy_flag           => busy_flag, 
            DAC_start_pulse     => voltage_signals(19),
            serial_data         => DAC_SDI_signal
            );

    -- DAC selectors
    DAC_SDI_selector : entity concept.demux_1_to_6
        port map(
            sel     => DAC_selector_signal,
            a       => DAC_SDI_signal,
            b1      => DAC_SDI_IO6,
            b2      => DAC_SDI_IO30,
            b3      => DAC_SDI_row_select1,
            b4      => DAC_SDI_row_select2,
            b5      => DAC_SDI_row_select3,
            b6      => DAC_SDI_IO28
        );

    DAC_SDI_IO12 <= DAC_SDI_row_select1 or DAC_SDI_row_select2 or DAC_SDI_row_select3;

    DAC_CS_selector : entity concept.demux_1_to_6
        port map(
            sel     => DAC_selector_signal,
            a       => DAC_CS_signal,
            b1      => DAC_CS_channel0,
            b2      => DAC_CS_channel1,
            b3      => DAC_CS_IO8,
            b4      => DAC_CS_IO9,
            b5      => DAC_CS_IO10,
            b6      => DAC_CS_IO26
        );
    
    DAC_CS_IO4 <= DAC_CS_channel0 or DAC_CS_channel1;

    DAC_CK_selector : entity concept.demux_1_to_6
        port map(
            sel     => DAC_selector_signal,
            a       => DAC_CK_signal,
            b1      => DAC_CK_channel0,
            b2      => DAC_CK_channel1,
            b3      => DAC_CK_row_select1,
            b4      => DAC_CK_row_select2,
            b5      => DAC_CK_row_select3,
            b6      => DAC_CK_IO27
        );

    DAC_CK_IO5  <= DAC_CK_channel0 or DAC_CK_channel1;
    DAC_CK_IO11 <= DAC_CK_row_select1 or DAC_CK_row_select2 or DAC_CK_row_select3;

    DAC_LD_selector : entity concept.demux_1_to_6
        port map(
            sel     => DAC_selector_signal,
            a       => DAC_LDAC_signal,
            b1      => DAC_LD_channel0,
            b2      => DAC_LD_channel1,
            b3      => DAC_LD_row_select1,
            b4      => DAC_LD_row_select2,
            b5      => DAC_LD_row_select3,
            b6      => DAC_LD_IO13
        );

    DAC_LD_IO3 <= DAC_LD_channel0 or DAC_LD_channel1;
    DAC_LD_IO7 <= DAC_LD_row_select1 or DAC_LD_row_select2 or DAC_LD_row_select3;

    -- ADC start pulse generator

    ADC_start_pulse_generator : entity concept.ADC_start_pulse_generator
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            enabled             => ADC_enabled,
            ADC_start_pulse     => ADC_start_pulse
        );
    
    -- ADC controller

    ADC_controller : entity concept.ADC_controller
        port map(
            clk             => sys_clk,
            rst             => sys_rst,
            start_pulse     => ADC_start_pulse,
            CNV             => ADC_CNV_signal,
            SCK             => ADC_SCK_signal,
            CNV_LENGTH      => to_integer(unsigned(cnv_length_signal)),
            SCK_DELAY       => to_integer(unsigned(sck_delay_signal)),
            SCK_HALF_PERIOD => to_integer(unsigned(sck_half_period_signal))
        );

    -- ADC DDR input reader

    ddr_input : entity concept.ddr_input
        port map (
            clock           => ADC_SCK_signal,
            reset           => sys_rst,
            output_en       => ADC_enabled,
            ddr_in          => ADC_SDO_signal,
            parallel_out    => parallel_ddr_data
        );

    -- ADC CNV falling edge detector

    fall_edge_detector_CNV : entity concept.FallEdgeDetector
        port map (
            clk             => sys_clk,
            rst             => sys_rst,
            signal_in       => ADC_CNV_signal,
            signal_out      => CNV_fall_pulse
        );

    -- ADC input shift register

    input_shift_register : entity concept.input_shift_register
        port map(
            clk                     => sys_clk,
            rst                     => sys_rst,
            serial_clk              => ADC_SCK_signal,
            iddr_parallel_output    => parallel_ddr_data,
            conv_started            => CNV_fall_pulse,
            valid_word              => valid_word,
            parallel_data           => parallel_word_data
        );

    -- VIO component
    
    vio : vio_test_ADC
        port map(
            clk             => sys_clk,
            probe_out0      => generator_sel,
            probe_out1      => DAC_voltage,
            probe_out2      => DAC_address,
            probe_out3(0)   => DAC_send_pulse,
            probe_out4      => DAC_selector_signal,
            probe_out5      => DAC_function_amplitude,
            probe_out6      => DAC_function_offset,
            probe_out7      => cnv_length_signal,
            probe_out8      => sck_delay_signal,
            probe_out9      => sck_half_period_signal
        );

end Behavioral;
