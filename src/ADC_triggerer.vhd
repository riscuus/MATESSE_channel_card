----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.31.2022
-- Module Name: ADC_triggerer.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of triggering the ADC at the desired freq each time a new row starts.
--              The conditions to start the triggering is that the acquisition is on and a new row pulse is received
--              Then, until the acquisition is off we will constantly trigger the ADC at the desired frequency

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

entity ADC_triggerer is
    generic(
        TRIGG_CLK_CYCLES        : natural := 20 -- The ADC is triggered every "trigg_clk_cycles". 20 for 5MHz
    );
    port(
        clk                     : in std_logic; -- 100mhz clock
        rst                     : in std_logic; -- asynchronous reset

        frame_active            : in std_logic; -- Signal that indicates that the acquisition has started
        ADC_start_pulse         : out std_logic -- Pulse to trigger the ADC
    );

end ADC_triggerer;

architecture behave of ADC_triggerer is

    signal clk_counter  : unsigned(bits_req(TRIGG_CLK_CYCLES - 1) - 1 downto 0) := (others => '0');

begin

start_pulse_gen : process(clk, rst)
begin
    if (rst = '1') then
        clk_counter <= (others => '0');
    elsif (rising_edge(clk)) then
        if (frame_active = '1') then
            if (clk_counter = TRIGG_CLK_CYCLES - 1) then
                clk_counter <= (others => '0');
            else
                clk_counter <= clk_counter + 1;
            end if;
        else
            clk_counter <= (others => '0');
        end if;
    end if;
end process;

ADC_start_pulse <= '1' when clk_counter = 0 and frame_active = '1' else
                   '0';

end behave;