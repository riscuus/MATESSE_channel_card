
----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.31.2022
-- Module Name: pulse_stretcher.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of stretching the input signal for two clocks of the slower clock

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

entity pulse_stretcher is
    generic(
        conversion_ratio    : natural := 20; -- Faster clock (100MHz) / Slower clock (5 MHz)
        stretching_length   : natural := 2  -- How many slow clocks to maitain the signal stretched
    );
    port(
        clk             : in std_logic; -- 100MHz clock                                                                           
        rst             : in std_logic; -- asynchronous reset

        fast_pulse      : in std_logic;
        stretched_pulse : out std_logic
    );

end pulse_stretcher;

architecture behave of pulse_stretcher is

    constant STRETCHING_CLKS    : natural := conversion_ratio * stretching_length;

    signal stretching_on        : std_logic := '0';
    signal clk_counter          : natural := 0;

begin

stretched_pulse <= stretching_on;

main_logic : process(clk, rst)
begin
    if (rst = '1') then
        stretching_on <= '0';
        clk_counter <= 0;
    elsif (rising_edge(clk)) then
        if (fast_pulse = '1') then
            stretching_on <= '1';
        end if;

        if (stretching_on = '1') then
            clk_counter <= clk_counter + 1;
        end if;

        if (clk_counter = STRETCHING_CLKS - 1) then
            clk_counter <= 0;
            stretching_on <= '0';
        end if;

    end if;
end process;

end behave;