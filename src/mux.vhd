----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.23.2022
-- Module Name: mux.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is a generic multiplexer that can be setup through the generic parameters

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

entity mux is
    generic(
        DATA_SIZE   : positive;
        SEL_SIZE    : positive
    );
    port(
        selector    : in unsigned(SEL_SIZE - 1 downto 0);
        data_in     : in std_logic_vector(DATA_SIZE * sel_size_to_input(SEL_SIZE) - 1 downto 0);
        data_out    : out std_logic_vector(DATA_SIZE - 1 downto 0)
    );

end mux;

architecture behave of mux is

begin

data_out <= data_in((to_integer(selector) + 1) * DATA_SIZE - 1 downto to_integer(selector) * DATA_SIZE);

end behave;