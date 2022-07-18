----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.18.2020
-- Module Name: DAC_driver.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Generation of the gates signals for controlling the DAC AD5544. Wrapper around the DAC_gate_controller
--              and data_serialer modules

-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library concept;
use concept.utils.all;

entity DAC_driver is
    generic(
        DATA_WIDTH          : natural; -- The number of bits of the parallel data
        SCLK_TOTAL_PULSES   : natural; -- The number of pulses for the SCLK. (Should be the same as DATA_WIDTH)
        SCLK_HALF_PERIOD    : natural; -- The number of 100 MHz clk cycles for the serial clk half period 
        LDAC_SETUP          : natural; -- The number of 100 MHz clk cycles for the LDAC setup time
        LDAC_WIDTH          : natural; -- The number of 100 MHz clk cycles to be activated the LDAC pulse
        LDAC_HOLD           : natural; -- The number of 100 MHz clk cycles for the LDAC hold time
    );
    port(
        clk                 : in std_logic; -- 100MHz clock
        rst                 : in std_logic; -- Async reset

        start_conv_pulse    : in std_logic;
        parallel_data       : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        CS                  : out std_logic;
        SCLK                : out std_logic;
        LDAC                : out std_logic;
        SDI                 : out std_logic
    );
end DAC_driver;


architecture behave OF DAC_driver is


begin

    DAC_gate_ctrl_module : entity concept.DAC_gate_controller
        generic map(
            SCLK_TOTAL_PULSES   => SCLK_TOTAL_PULSES,
            SCLK_HALF_PERIOD    => SCLK_HALF_PERIOD,
            LDAC_SETUP          => LDAC_SETUP,
            LDAC_WIDTH          => LDAC_WIDTH,
            LDAC_HOLD           => LDAC_HOLD
        )
        port map(
            clk                 => clk,
            rst                 => rst,
            
            start_conv_pulse    => start_conv_pulse,
            CS                  => CS,
            SCLK                => SCLK,
            LDAC                => LDAC
        );

    DAC_data_serializer_module : entity concept.data_serializer_wrapper
        port map(
            clk             => clk,
            rst             => rst,

            gate_read       => CS,
            data_clk        => SCLK,
            valid           => '1',
            parallel_data   => parallel_data,
            busy_flag       => '0',
            DAC_start_pulse => DAC_start_pulse,
            serial_data     => SDI
        );

end behave;
