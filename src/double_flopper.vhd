----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.23.2022
-- Module Name: double_flopper.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is a generic double flopper (2 D flip-flops) that can be used to pass a signal from a 
--              slow domain to a faster domain

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

library concept;
use concept.utils.all;

entity double_flopper is
    generic(
        DATA_SIZE   : positive
    );
    port(
        fast_clk    : in std_logic;
        data_in     : in std_logic_vector(DATA_SIZE - 1 downto 0);
        data_out    : out std_logic_vector(DATA_SIZE - 1 downto 0)
    );

end double_flopper;

architecture behave of double_flopper is

    signal r_1 : std_logic_vector(data_in'range) := (others => '0');
    signal r_2 : std_logic_vector(data_in'range) := (others => '0');

begin

    data_out <= r_2;

main_logic : process(fast_clk)
begin
    if (rising_edge(fast_clk)) then
        r_1 <= data_in;
        r_2 <= r_1;
    end if;
end process;

end behave;