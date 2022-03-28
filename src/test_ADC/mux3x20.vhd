----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03.19.2020
-- Module Name: mux3x20.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Multiplexer of 2 channels with each channel consisting of 20 signals
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

entity mux3x20 is
    port ( 
        sel     : in std_logic_vector(1 downto 0); -- Outputs a1 when set to '0', a2 if set to '1'.
        a1      : in std_logic_vector(19 downto 0);
        a2      : in std_logic_vector(19 downto 0);
        a3      : in std_logic_vector(19 downto 0);
        b       : out std_logic_vector(19 downto 0)
    );
end mux3x20;

architecture Behavioral of mux3x20 is

begin

    b <= a1 when (sel = "00") else 
         a2 when (sel = "01") else
         a3 when (sel = "10") else
         (others => '0');

end Behavioral;
