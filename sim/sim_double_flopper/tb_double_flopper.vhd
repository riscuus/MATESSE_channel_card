----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07/26/2022
-- Module Name: tb_double_flopper.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the double flopper module
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all; -- Allows to open and read a file
--use ieee.std_logic_textio.all; -- Adding this package also allows to read std_logic_vectors from the file

library concept;
use concept.utils.all;

entity tb_double_flopper is
end tb_double_flopper;

architecture behave of tb_double_flopper is

    constant DATA_SIZE : natural := 8;

    signal clk_5        : std_logic := '0';
    signal clk_100      : std_logic := '0';
    signal slow_data    : std_logic_vector(DATA_SIZE - 1 downto 0) := (others => '0');

begin

    -- 5 CLK generation
    clk_generation_5 : process 
    begin
        clk_5 <= '1';
        wait for 100 ns; 
        clk_5 <= '0';
        wait for 100 ns;
    end process;

    -- 100 CLK generation
    clk_generation_100 : process 
    begin
        clk_100 <= '1';
        wait for 5 ns; 
        clk_100 <= '0';
        wait for 5 ns;
    end process;

    slow_data_gen : process
    begin
        slow_data <= x"ab";
        wait for 3 * 200 ns;
        slow_data <= (others => '0');
        wait for 1 * 200 ns;
        slow_data <= x"cd";
        wait;

    end process;

    flopper : entity concept.double_flopper
    generic map(
        DATA_SIZE   => DATA_SIZE
    )
    port map(
        fast_clk    => clk_100,
        data_in     => slow_data,
        data_out    => open
    );


end behave;