----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 05.28.2020
-- Module Name: fall_edge_detector.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component triggers a high active pulse when the input signal has a falling edge

-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library concept;
use concept.utils.all;

entity FallEdgeDetector is
      port (     clk         : in  STD_LOGIC;
                 rst         : in  STD_LOGIC;
                 signal_in   : in  STD_LOGIC;
                 signal_out  : out  STD_LOGIC);
end FallEdgeDetector;

architecture FallEdgeDetector_BEHAVE of FallEdgeDetector is

-- lists of type and signals -----------------------------------------
signal signal_d : STD_LOGIC;

-- end of lists of type and signals -----------------------------------------
begin

process1 : process (clk, rst)
begin
    if rst = '1' then
        signal_out <= '0';
        signal_d <= '0';
    elsif rising_edge(clk) then
        signal_d <= signal_in;
        signal_out <= (not signal_in) and signal_d ;		
    else
    end if;
end process;


end FallEdgeDetector_BEHAVE;
