----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06/09/2022
-- Module Name: tb_mux.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the generic mux module
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library concept;
use concept.utils.all;

entity tb_mux is
end tb_mux;

architecture behave of tb_mux is
    constant DATA_SIZE  : integer := 16;
    constant SEL_SIZE   : integer := 2;

    signal a : std_logic_vector(DATA_SIZE - 1 downto 0) := (others => '0');
    signal b : std_logic_vector(DATA_SIZE - 1 downto 0) := (others => '0');
    signal c : std_logic_vector(DATA_SIZE - 1 downto 0) := (others => '0');
    signal d : std_logic_vector(DATA_SIZE - 1 downto 0) := (others => '0');

    signal muxed_data : std_logic_vector(DATA_SIZE - 1 downto 0) := (others => '0');

    signal selector : unsigned(SEL_SIZE - 1 downto 0) := (others => '0');
    

begin

    generate_data : process
    begin
            a <= std_logic_vector(unsigned(a) + 1); 
            b <= std_logic_vector(unsigned(b) + 2); 
            c <= std_logic_vector(unsigned(c) + 3); 
            d <= std_logic_vector(unsigned(d) + 4); 
            wait for 2 us;
    end process;

    generate_sel : process
    begin
        selector <= selector + 1;
        wait for 3 us;
    end process;

    mux_module : entity concept.mux
        generic map(
            DATA_SIZE => 16,
            SEL_SIZE => 2
        )
        port map(
            selector => selector,
            data_in(1 * DATA_SIZE - 1 downto 0 * DATA_SIZE) => a,
            data_in(2 * DATA_SIZE - 1 downto 1 * DATA_SIZE) => b,
            data_in(3 * DATA_SIZE - 1 downto 2 * DATA_SIZE) => c,
            data_in(4 * DATA_SIZE - 1 downto 3 * DATA_SIZE) => d,
            data_out => muxed_data
        );

end behave;