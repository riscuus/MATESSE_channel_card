----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03.15.2020
-- Module Name: ADC_start_pulse_generator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Component meant to generate a periodic signal consisting of a pulse that will be used to read the 
--              current voltage in the ADC
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
use IEEE.numeric_std.all;

library concept;
use concept.all;

entity ADC_start_pulse_generator is
    port ( 
        -- 100MHz clock
        clk : in std_logic;
        -- Async reset
        rst : in std_logic;
        -- Signal that determines if the function generator must be active
        enabled : in std_logic;
        -- Signal to announce that a new DAC cycle must start
        ADC_start_pulse : out std_logic
    );
end ADC_start_pulse_generator;

architecture Behavioral of ADC_start_pulse_generator is
    -- Number of 100MHz clock cycles to trigger a new ADC reading
    constant SIGNAL_PERIOD : positive := 20;
    -- Counter of the clock cycles
    signal counter : natural range 0 to SIGNAL_PERIOD;
    -- start pulse signal to be able to read its state
    signal start_pulse_signal : std_logic;

begin

    ADC_start_pulse <= start_pulse_signal;

    pulse_generation : process(clk, rst)
    begin
        if(rst = '1') then
            start_pulse_signal <= '0';
            counter <= 0;
        elsif (rising_edge(clk)) then
            if(enabled = '1') then
                if(counter = SIGNAL_PERIOD - 1) then
                    counter <= 0;
                    start_pulse_signal <= '1';
                else 
                    -- We just trigger the start pulse signal for 1 clk period
                    if(start_pulse_signal = '1') then
                        start_pulse_signal <= '0';
                    end if;
                    counter <= counter + 1;
                end if;
            else
                -- We reset the component when it is not enabled
                counter <= 0;
                start_pulse_signal <= '0';
            end if;
        end if;
    end process;

end Behavioral;
