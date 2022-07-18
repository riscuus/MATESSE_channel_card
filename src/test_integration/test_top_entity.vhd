----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/24/2022
-- Module Name: test_top_entity.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Test module that works as the top entity to be implemented in the FPGA. Very similar to the real test_top_entity
--              but this test module includes the signal_generator to be able to loopback a custom signal through the ADCs
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

entity test_top_entity is
    port (
        clk_100                     : in std_logic;
        sys_rst                     : in std_logic;
        
        -- UART interface
        rx_uart_serial              : in std_logic;
        tx_uart_serial              : out std_logic;

        -- row_activator DACS
        --sync_frame                  : in std_logic;
        row_activator_DAC_CS_0_IO8  : out std_logic;
        row_activator_DAC_CS_1_IO9  : out std_logic;
        row_activator_DAC_CS_2_IO10 : out std_logic;
        row_activator_DAC_CLK_IO11  : out std_logic;
        row_activator_DAC_LDAC_IO7  : out std_logic;
        row_activator_DAC_SDI_IO12  : out std_logic;

        -- TES bias DAC interface
        TES_bias_DAC_CS_IO26        : out std_logic;
        TES_bias_DAC_CLK_IO27       : out std_logic;
        TES_bias_DAC_LDAC_IO13      : out std_logic;
        TES_bias_DAC_SDI_IO28       : out std_logic;

        -- Channels DAC interface
        channels_DAC_CS_IO4         : out std_logic;
        channels_DAC_CLK_IO5        : out std_logic;
        channels_DAC_LDAC_IO3       : out std_logic;
        channels_DAC_SDI_0_IO6      : out std_logic;
        channels_DAC_SDI_1_IO30     : out std_logic;

        -- ADC interface
        ADC_CNV_IO0                 : out std_logic;
        ADC_SCK_IO1                 : out std_logic;
        ADC_CLKOUT_IO31             : in std_logic;
        ADC_SDO_0_IO2               : in std_logic;
        ADC_SDO_1_IO29              : in std_logic
     );
end entity;


architecture RTL of test_top_entity is

    -- Signal generator generics
    constant NUM_CYCLES_WIDTH        : natural := 6;  -- This allows to set as max num cycles 2^6 = 64 cycles, for the fast signal 
    constant CYCLES_MULTPLR_WIDTH    : natural := 5;  -- We can make the slow signal around 2^5 = 32 times slower
    constant K_GAIN_WIDTH            : natural := 4;  -- We can amplify from 1 to 11. 
    constant M                       : natural := 8;  -- For going from 0 to 1 we will take 256 samples

    -- clk signals
    signal sys_clk_5    : std_logic := '0';
    signal sys_clk_100  : std_logic := '0';

    -- sync_frame signal
    signal sync_frame   : std_logic := '1';

    -- signal_generator signals
    signal signal_gen_data       : std_logic_vector(DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE - 1 downto 0) := (others => '0');
    signal signal_gen_data_valid : std_logic := '0';

    -- VIO component signals
    signal enable_slow      : std_logic := '0';
    signal enable_fast      : std_logic := '0';
    signal n_cycles         : std_logic_vector(NUM_CYCLES_WIDTH - 1 downto 0) := (others => '0');
    signal cycles_multplr   : std_logic_vector(CYCLES_MULTPLR_WIDTH - 1 downto 0) := (others => '0');
    signal downscaling      : std_logic_vector(K_GAIN_WIDTH - 1 downto 0) := (others => '0');
    signal k_gain           : std_logic_vector(K_GAIN_WIDTH - 1 downto 0) := (others => '0');
    signal offset           : std_logic_vector(DAC_VOLTAGE_SIZE - 1 downto 0) := (others => '0');

    component vio_test_top_entity
      port (
        clk         : in std_logic;
        probe_in0   : in std_logic_vector(0 downto 0);
        probe_in1   : in std_logic_vector(0 downto 0);
        probe_in2   : in std_logic_vector(15 downto 0);
        probe_in3   : in std_logic_vector(0 downto 0);
        probe_out0  : out std_logic_vector(0 downto 0);
        probe_out1  : out std_logic_vector(0 downto 0);
        probe_out2  : out std_logic_vector(5 downto 0);
        probe_out3  : out std_logic_vector(4 downto 0);
        probe_out4  : out std_logic_vector(3 downto 0);
        probe_out5  : out std_logic_vector(3 downto 0);
        probe_out6  : out std_logic_vector(15 downto 0)
      );
    end component;

begin

---------------------------------------------------------------------
---------------- Clock Distribution ---------------------------------
---------------------------------------------------------------------

    clock_distr: entity concept.clock_distribution
        port map(
            clock_in   => clk_100,
            clock_005  => sys_clk_5,
            clock_100  => sys_clk_100,
            locked     => open
        );

---------------------------------------------------------------------
----------------------- Main module ---------------------------------
---------------------------------------------------------------------

    main_module : entity concept.main_module
        port map(
            sys_clk_5               => sys_clk_5,
            sys_clk_100             => sys_clk_100,
            sys_rst                 => sys_rst,

            -- UART interface
            rx_uart_serial          => rx_uart_serial,
            tx_uart_serial          => tx_uart_serial,

            -- row_activator DACS interface
            sync_frame              => sync_frame,
            row_activator_DAC_CS_0  => row_activator_DAC_CS_0_IO8,
            row_activator_DAC_CS_1  => row_activator_DAC_CS_1_IO9,
            row_activator_DAC_CS_2  => row_activator_DAC_CS_2_IO10,
            row_activator_DAC_CLK   => row_activator_DAC_CLK_IO11,
            row_activator_DAC_LDAC  => row_activator_DAC_LDAC_IO7,
            row_activator_DAC_SDI   => row_activator_DAC_SDI_IO12,
                
            -- TES bias DAC interface
            TES_bias_DAC_CS         => open, --TES_bias_DAC_CS_IO26,
            TES_bias_DAC_CLK        => open, --TES_bias_DAC_CLK_IO27,
            TES_bias_DAC_LDAC       => open, --TES_bias_DAC_LDAC_IO13,
            TES_bias_DAC_SDI        => open, --TES_bias_DAC_SDI_IO28,
                
            -- Channels DAC interface
            channels_DAC_CS         => channels_DAC_CS_IO4,
            channels_DAC_CLK        => channels_DAC_CLK_IO5,
            channels_DAC_LDAC       => channels_DAC_LDAC_IO3,
            channels_DAC_SDI_0      => channels_DAC_SDI_0_IO6,
            channels_DAC_SDI_1      => channels_DAC_SDI_1_IO30,
                
            -- ADC interface
            ADC_CNV                 => ADC_CNV_IO0,
            ADC_SCK                 => ADC_SCK_IO1,
            ADC_CLKOUT              => ADC_CLKOUT_IO31,
            ADC_SDO_0               => ADC_SDO_0_IO2,
            ADC_SDO_1               => ADC_SDO_1_IO29
        );

---------------------------------------------------------------------
--------------------- Signal generator ------------------------------
---------------------------------------------------------------------

    signal_generator_module : entity concept.signal_generator
        generic map(
            NUM_CYCLES_WIDTH        => NUM_CYCLES_WIDTH,
            CYCLES_MULTPLR_WIDTH    => CYCLES_MULTPLR_WIDTH,
            K_GAIN_WIDTH            => K_GAIN_WIDTH,
            DATA_WIDTH              => DAC_VOLTAGE_SIZE,
            M                       => M
        )
        port map(
            clk                 => sys_clk_5,
            rst                 => sys_rst,

            enable_slow         => enable_slow,
            enable_fast         => enable_fast,
            n_cycles            => unsigned(n_cycles),
            cycles_multplr      => unsigned(cycles_multplr),

            downscaling         => unsigned(downscaling),
            k_gain              => unsigned(k_gain),
            offset              => unsigned(offset),

            data                => signal_gen_data(DAC_VOLTAGE_SIZE - 1 downto 0), -- 16 bits
            data_valid          => signal_gen_data_valid
        );

    signal_generator_DAC_driver : entity concept.DAC_driver
        generic map(
            DATA_WIDTH          => DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE,
            SCLK_TOTAL_PULSES   => DAC_VOLTAGE_SIZE + DAC_ADDR_SIZE,
            SCLK_HALF_PERIOD    => DAC_SCLK_HALF_PERIOD,
            LDAC_SETUP          => DAC_LDAC_SETUP,
            LDAC_WIDTH          => DAC_LDAC_WIDTH,
            LDAC_HOLD           => DAC_LDAC_HOLD
        )
        port map(
            clk                => sys_clk_100,
            rst                => sys_rst,

            start_pulse        => signal_gen_data_valid,
            parallel_data      => signal_gen_data, -- 18 bits

            CS                 => TES_bias_DAC_CS_IO26,
            SCLK               => TES_bias_DAC_CLK_IO27,
            LDAC               => TES_bias_DAC_LDAC_IO13,
            SDI                => TES_bias_DAC_SDI_IO28
        );

    -- VIO component
    vio : vio_test_top_entity
        port map(
            clk             => sys_clk_100,
            probe_in0(0)    => ADC_CLKOUT_IO31,
            probe_in1(0)    => ADC_SDO_0_IO2,
            probe_in2       => signal_gen_data(DAC_VOLTAGE_SIZE - 1 downto 0),
            probe_in3(0)    => signal_gen_data_valid,
            probe_out0(0)   => enable_slow,
            probe_out1(0)   => enable_fast,
            probe_out2      => n_cycles,
            probe_out3      => cycles_multplr,
            probe_out4      => downscaling,
            probe_out5      => k_gain,
            probe_out6      => offset
        );
    
end architecture;
