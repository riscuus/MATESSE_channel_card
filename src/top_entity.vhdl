----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/24/2022
-- Module Name: top_entity.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module that works as the top entity to be implemented in the FPGA. Its outputs are directly the physical
--              outputs of the FPGA
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

entity top_entity is
    port (
        clk_12                      : in std_logic;
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


architecture RTL of top_entity is

    signal sys_clk_5    : std_logic := '0';
    signal sys_clk_100  : std_logic := '0';
    signal sys_clk_200  : std_logic := '0';

    signal sync_frame   : std_logic := '1';
    signal ADC_CLKOUT   : std_logic := '0';

begin

---------------------------------------------------------------------
---------------- Clock Distribution ---------------------------------
---------------------------------------------------------------------

    clock_distr: entity concept.clock_distribution
        port map(
            rst         => sys_rst,
            clk_in_12   => clk_12,
            clk_out_100 => sys_clk_100,
            clk_out_200 => sys_clk_200,
            clk_out_005 => sys_clk_5
        );

---------------------------------------------------------------------
----------------------- Main module ---------------------------------
---------------------------------------------------------------------

    main_module : entity concept.main_module
        port map(
            sys_clk_5               => sys_clk_5,
            sys_clk_100             => sys_clk_100,
            sys_clk_200             => sys_clk_200,
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
                
            -- TES bias DAC interface  -- TES bias DAC int
            TES_bias_DAC_CS         => TES_bias_DAC_CS_IO26,
            TES_bias_DAC_CLK        => TES_bias_DAC_CLK_IO27,
            TES_bias_DAC_LDAC       => TES_bias_DAC_LDAC_IO13,
            TES_bias_DAC_SDI        => TES_bias_DAC_SDI_IO28,
                
            -- Channels DAC interface  -- Channels DAC int
            channels_DAC_CS         => channels_DAC_CS_IO4,
            channels_DAC_CLK        => channels_DAC_CLK_IO5,
            channels_DAC_LDAC       => channels_DAC_LDAC_IO3,
            channels_DAC_SDI_0      => channels_DAC_SDI_0_IO6,
            channels_DAC_SDI_1      => channels_DAC_SDI_1_IO30,
                
            -- ADC interface           -- ADC int
            ADC_CNV                 => ADC_CNV_IO0,
            ADC_SCK                 => ADC_SCK_IO1,
            ADC_CLKOUT              => ADC_CLKOUT_IO31,
            ADC_SDO_0               => ADC_SDO_0_IO2,
            ADC_SDO_1               => ADC_SDO_1_IO29
        );
    
end architecture;
