----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/28/2020 12:18:39 AM
-- Design Name: 
-- Module Name: RiseEdgeDetector - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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

entity RiseEdgeDetector is
      Port ( 	 clk         : in  STD_LOGIC;
				 rst        : in  STD_LOGIC;
                 signal_in   : in  STD_LOGIC;
                 signal_out  : out  STD_LOGIC);
end RiseEdgeDetector;

architecture RiseEdgeDetector_BEHAVE of RiseEdgeDetector is

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
		signal_out <= signal_in and (not signal_d) ;		
	end if;
end process;


end RiseEdgeDetector_BEHAVE;