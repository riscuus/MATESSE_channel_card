----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/28/2020 12:42:21 AM
-- Design Name: 
-- Module Name: FallEdgeDetector - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library concept;
use concept.utils.all;

entity FallEdgeDetector is
      Port ( 	 clk         : in  STD_LOGIC;
				 rst        : in  STD_LOGIC;
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
