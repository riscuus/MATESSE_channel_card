----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.14.2022
-- Module Name: samples_triggerer.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of triggering the triangular_samples_generator once every X amount of samples.

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

entity samples_triggerer is
    generic(
        NUM_CYCLES_WIDTH : natural
    );
    port(
        clk                 : in std_logic; -- 5MHz clk
        rst                 : in std_logic; -- async reset

        enable              : in std_logic; -- We only trigger if enable is active high
        num_cycles          : in unsigned(NUM_CYCLES_WIDTH - 1 downto 0); -- We trigger a new sample every num_cycles clk cycles

        new_sample          : out std_logic -- Pulse to trigger a new sample
    );

end samples_triggerer;

architecture behave of samples_triggerer is

    signal clk_counter : unsigned(num_cycles'range) := (others => '0');

begin

    new_sample <= '1' when clk_counter = num_cycles - 1 else
                  '0';

    main_logic : process(clk, rst)
    begin
        if (rst = '1') then
            clk_counter <= (others => '0');

        elsif (rising_edge(clk)) then
            if (enable = '1') then
                if(clk_counter = num_cycles - 1) then
                    clk_counter <= (others => '0');
                else
                    clk_counter <= clk_counter + 1;
                end if;
            else
                clk_counter <= (others => '0');
            end if;
        end if;
    end process;

end behave;