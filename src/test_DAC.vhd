----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.03.2022
-- Module Name: test_DAC.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Top module to be able to test the correct functionality of the DAC components. The objective is to
--              communicate different voltages to a/various DAC and measure the output voltage with an oscilloscope
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


entity test_DAC is
    port ( 
        sys_clk              : in std_logic;
        sys_rst              : in std_logic;
        DAC_start_pulse      : in std_logic;
        SDI_IO28             : out std_logic;
        LD_IO13              : out std_logic;
        CS_IO26              : out std_logic;
        CK_IO27              : out std_logic
        --clk_5mhz             : out std_logic;
        --clk_100mhz           : out std_logic

    );
end test_DAC;

architecture Behavioral of test_DAC is

    -- Clocks output

    --signal sys_clk_100mhz   : std_logic;
    --signal sys_clk_5mhz     : std_logic;
    --signal sys_clk_locked   : std_logic;

    -- DAC SPI communication

    signal LDAC_signal  : std_logic;
    signal CS_signal    : std_logic;
    signal CK_signal    : std_logic;
    signal SDI_signal   : std_logic;

    -- DAC data serializer

    signal busy_flag                : std_logic := '0';
    signal data_valid               : std_logic := '1';
    signal serializer_ready         : std_logic;
    signal parallel_data            : std_logic_vector(17 downto 0) := "100110101011100010";


begin

    -- OUTPUTS assigments
    --clk_5mhz <= sys_clk_5mhz;
    --clk_100mhz <= sys_clk_100mhz;

    LD_IO13 <= LDAC_signal;
    CS_IO26 <= CS_signal; 
    CK_IO27 <= CK_signal;
    SDI_IO28 <= SDI_signal;


    -- Clock distribution
--   clock_distr: entity concept.clock_distribution
--       port map(
--           clock_in   => sys_clk,
--           clock_005  => sys_clk_5mhz,
--           clock_100  => sys_clk_100mhz,
--           locked     => sys_clk_locked
--       );
    
    -- DAC Controller

    DAC_controller : entity concept.DAC_controller
        port map(
            clock               => sys_clk,
            rst                 => sys_rst,
            start_conv_pulse    => DAC_start_pulse,
            CS                  => CS_signal,
            CLK                 => CK_signal,
            LDAC                => LDAC_signal
        );

    -- Data serializer

     data_serializer_wrapper : entity concept.data_serializer_wrapper
        port map(
            clk                 => sys_clk,
            rst                 => sys_rst,
            gate_read           => CS_signal,
            data_clk            => CK_signal,
            valid               => data_valid, 
            parallel_data       => parallel_data, 
            busy_flag           => busy_flag, 
            ready               => serializer_ready, 
            serial_data         => SDI_signal
            );
end Behavioral;
