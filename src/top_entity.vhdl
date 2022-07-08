library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

entity top_entity is
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

        -- TES bias DAC interface
        TES_bias_DAC_CS_IO26        : out std_logic;
        TES_bias_DAC_CLK_IO27       : out std_logic;
        TES_bias_DAC_LDAC_IO13      : out std_logic;

        -- Channels DAC interface
        channels_DAC_CS_IO4         : out std_logic;
        channels_DAC_CLK_IO5        : out std_logic;
        channels_DAC_LDAC_IO3       : out std_logic;
        channels_DAC_SDI_0_IO6      : out std_logic;
        channels_DAC_SDI_1_IO30     : out std_logic;

        -- ADC interface
        ADC_CNV_IO0                 : out std_logic;
        ADC_SCK_IO1                 : out std_logic;
        --ADC_CLKOUT                  : in std_logic;
        ADC_SDO_0_IO2               : in std_logic;
        ADC_SDO_1_IO29              : in std_logic
     );
end entity;


architecture RTL of top_entity is

    signal sys_clk_5    : std_logic := '0';
    signal sys_clk_100  : std_logic := '0';

    signal sync_frame   : std_logic := '0';
    signal ADC_CLKOUT   : std_logic := '0';

begin

    ADC_SCK_IO1 <= ADC_CLKOUT; -- Temporal fix until board is modified
    
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
                
            -- TES bias DAC interface  -- TES bias DAC int
            TES_bias_DAC_CS         => TES_bias_DAC_CS_IO26,
            TES_bias_DAC_CLK        => TES_bias_DAC_CLK_IO27,
            TES_bias_DAC_LDAC       => TES_bias_DAC_LDAC_IO13,
                
            -- Channels DAC interface  -- Channels DAC int
            channels_DAC_CS         => channels_DAC_CS_IO4,
            channels_DAC_CLK        => channels_DAC_CLK_IO5,
            channels_DAC_LDAC       => channels_DAC_LDAC_IO3,
            channels_DAC_SDI_0      => channels_DAC_SDI_0_IO6,
            channels_DAC_SDI_1      => channels_DAC_SDI_1_IO30,
                
            -- ADC interface           -- ADC int
            ADC_CNV                 => ADC_CNV_IO0,
            ADC_SCK                 => ADC_CLKOUT,
            ADC_CLKOUT              => ADC_CLKOUT,
            ADC_SDO_0               => ADC_SDO_0_IO2,
            ADC_SDO_1               => ADC_SDO_1_IO29
        );
    
end architecture;
