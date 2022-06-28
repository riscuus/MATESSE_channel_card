----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.27.2022
-- Module Name: demux.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is a generic demultiplexer that can be setup through the generic parameters

-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

-- Packages that are going to be used in the module
library IEEE; -- Make library visible
use     IEEE.std_logic_1164.all;  -- Make package visible
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

entity demux is
    generic(
        DATA_SIZE   : positive;
        SEL_SIZE    : positive
    );
    port(
        selector    : in unsigned(SEL_SIZE - 1 downto 0);
        data_in     : in std_logic_vector(DATA_SIZE - 1 downto 0);
        data_out    : out std_logic_vector(DATA_SIZE * sel_size_to_input(SEL_SIZE) - 1 downto 0)
    );

end demux;

architecture behave of demux is

begin

select_process : process(selector, data_in)
begin
    for i in 0 to sel_size_to_input(SEL_SIZE) - 1 loop
        if (i = to_integer(selector)) then
            data_out((i + 1) * DATA_SIZE - 1 downto i * DATA_SIZE) <= data_in;
        else
            data_out((i + 1) * DATA_SIZE - 1 downto i * DATA_SIZE) <= (others => '0');
        end if;
    end loop;
end process;

end behave;