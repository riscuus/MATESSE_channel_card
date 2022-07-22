
----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco, Iban Ibanez
-- 
-- Create Date: 20.05.2020
-- Module Name: clock_distribution.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Wrapper around the clock wizard ip provided by Xilinx. 3 clocks must be generated comming from an
--              initial clock of 12 MHz. (5 MHz, 100 MHz, 200 MHz)

-- 
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


entity clock_distribution is
    port (
        rst         : in std_logic;
        clk_in_12   : in std_logic;
        clk_out_100 : out std_logic;
        clk_out_200 : out std_logic;
        clk_out_005 : out std_logic
    );
end clock_distribution;

architecture RTL of clock_distribution is

------------------------------------------------------------------------------
--  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
--   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
------------------------------------------------------------------------------
-- clk_out1___100.000______0.000______50.0______297.831____286.028
-- clk_out2___200.000______0.000______50.0______251.921____286.028
-- clk_out3_____5.000______0.000______50.0______569.565____286.028
--
------------------------------------------------------------------------------
-- Input Clock   Freq (MHz)    Input Jitter (UI)
------------------------------------------------------------------------------
-- __primary__________30.000____________0.010
------------------------------------------------------------------------------

component clk_wizard
port
    (
        reset             : in     std_logic;
        clk_in1           : in     std_logic;
        clk_out1          : out    std_logic;
        clk_out2          : out    std_logic;
        clk_out3          : out    std_logic;
        -- Status and control signals
        locked            : out    std_logic
    );
end component;

begin

clk_generator : clk_wizard
    port map ( 
        reset       => rst,
        clk_in1     => clk_in_12,
        clk_out1    => clk_out_100,
        clk_out2    => clk_out_200,
        clk_out3    => clk_out_005,
        locked      => open
    );

end architecture;
