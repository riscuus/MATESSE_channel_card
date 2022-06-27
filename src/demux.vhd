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


-----------------------------------------------------------------------------------------
-- Packages that are going to be used in the package
library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

package conv_utility is 
    -- Here we make the funtions visible
    function sel_size_to_input(constant sel_size : positive) return positive;
end package;

package body conv_utility is
    -- Returns the number of the mux inputs for a determined selector size
    function sel_size_to_input(constant sel_size : positive) return positive is
    begin
        -- The number of inputs is 2 power the length of the selector vector (s) = 2^s
        return to_integer(shift_left(to_unsigned(1, SEL_SIZE + 1), SEL_SIZE));
    end function;
end package body;
-----------------------------------------------------------------------------------------


-- Packages that are going to be used in the module
library IEEE; -- Make library visible
use     IEEE.std_logic_1164.all;  -- Make package visible
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

use work.conv_utility; -- Work means our current active library

entity mux is
    generic(
        DATA_SIZE   : positive := 16;
        SEL_SIZE    : positive := 2
    );
    port(
        selector    : in unsigned(SEL_SIZE - 1 downto 0);
        data_in     : in std_logic_vector(DATA_SIZE - 1 downto 0);
        data_out    : out std_logic_vector(DATA_SIZE * conv_utility.sel_size_to_input(SEL_SIZE) - 1 downto 0)
    );

end mux;

architecture behave of mux is

begin

select_process : process(selector, data_in)
begin
    data_out <= (others => '0');
    for i in 0 to conv_utility.sel_size_to_input(SEL_SIZE) - 1 loop
        if (i = to_integer(selector)) then
            data_out((to_integer(selector) + 1) * DATA_SIZE - 1 downto to_integer(selector) * DATA_SIZE) <= data_in;
        end if;
    end loop;
end process;

end behave;