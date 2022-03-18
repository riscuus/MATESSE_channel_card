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
    );
end test_ADC;

architecture Behavioral of test_ADC is

    -- DAC SPI communication
    signal DAC_LDAC_signal  : std_logic;
    signal DAC_CS_signal    : std_logic;
    signal DAC_CK_signal    : std_logic;
    signal DAC_SDI_signal   : std_logic;

    -- DAC data serializer
    signal busy_flag                : std_logic := '0';
    signal data_valid               : std_logic := '0';
    signal parallel_data            : std_logic_vector(17 downto 0) := "100110101011100010";
    signal DAC_start_pulse          : std_logic := '0';


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

    -- Set debugging signals
    attribute keep : string;
    attribute keep of parallel_data       : signal is "true";

begin

    ----- OUTPUTS ASSIGMENTS -----

    -- DAC U0 (Channel 0)
    DAC_SDI_IO6     <= DAC_SDI_signal;
    -- DAC U1 (Channel 1)
    DAC_SDI_IO30    <= DAC_SDI_signal;
    -- DAC U0, U1 shared
    DAC_LD_IO3      <= DAC_LDAC_signal;
    DAC_CS_IO4      <= DAC_CS_signal;
    DAC_CK_IO5      <= DAC_CK_signal;
    -- DAC U20 (Row Operations)
    DAC_CS_IO8      <= DAC_CS_signal;
    -- DAC U21 (Row Operations)
    DAC_CS_IO9      <= DAC_CS_signal;
    -- DAC U22 (Row Operations)
    DAC_CS_IO10     <= DAC_CS_signal;
    -- DAC U20, U21, U22 shared 
    DAC_LD_IO7      <= DAC_LDAC_signal;
    DAC_CK_IO11     <= DAC_CK_signal;
    DAC_SDI_IO12    <= DAC_SDI_signal;
    -- DAC U23 (Bias)
    DAC_LD_IO13     <= DAC_LDAC_signal;
    DAC_CS_IO26     <= DAC_CS_signal; 
    DAC_CK_IO27     <= DAC_CK_signal;
    DAC_SDI_IO28    <= DAC_SDI_signal;

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
            start_conv_pulse    => DAC_start_pulse,
            CS                  => DAC_CS_signal,
            CLK                 => DAC_CK_signal,
            LDAC                => DAC_LDAC_signal
        );

    -- DAC voltage generator
     
    DAC_voltage_generator : entity concept.DAC_voltage_generator
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            enabled             => DAC_enabled,
            v0_pulse            => btn0,
            v1_pulse            => btn1,
            v2_pulse            => btn2,
            v3_pulse            => btn3,
            DAC_start_pulse     => DAC_start_pulse,
            data_valid          => data_valid,
            parallel_data       => parallel_data
        );

    -- DAC data serializer

     data_serializer_wrapper : entity concept.data_serializer_wrapper
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            gate_read           => DAC_CS_signal,
            data_clk            => DAC_CK_signal,
            valid               => data_valid, 
            parallel_data       => parallel_data, 
            busy_flag           => busy_flag, 
            DAC_start_pulse     => DAC_start_pulse,
            serial_data         => DAC_SDI_signal
            );

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
            nrst            => sys_rst,
            start_pulse     => ADC_start_pulse,
            CNV             => ADC_CNV_signal,
            SCLK            => ADC_SCK_signal
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
            nrst                    => sys_rst,
            serial_clk              => ADC_SCK_signal,
            iddr_parallel_output    => parallel_ddr_data,
            conv_started            => CNV_fall_pulse,
            valid_word              => valid_word,
            parallel_data           => parallel_word_data
        );
    

end Behavioral;
