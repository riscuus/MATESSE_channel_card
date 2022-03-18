----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 05.02.2020
-- Module Name: ADC_controller.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Generation of the serial lines for controlling the ADC LTC2325-16. 
--              General requirements for the controller:
--                  - The CNV is triggered after the start_pulse and must be a pulse signal of at least 30ns
--                  - A minimum delay of 20 ns must exist between the falling edge of the CNV signal and the first 
--                    cycle of the serial clock => We will use 2 cycles of the 100Mhz clock
--                  - The serial clock must have a period of at least 18.2 ns => 2 cycles of the 100Mhz clock
--                  - The serial clock must output exactly 8 pulses
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

entity ADC_controller IS
    port(   clk             : in std_logic; -- 100MHz clock
            nrst            : in std_logic; -- Async reset
            start_pulse     : in std_logic; -- Input pulse that indicates that a new conversion must start
            CNV             : out std_logic; -- Output CNV pulse 30ns min high
            SCLK            : out std_logic -- Serial output clock, min period 18.2 ns
            );
end ADC_controller;


architecture behave OF ADC_controller IS
    -- Num of clk cycles for the serial clock to start
    constant START_SCLK : positive := 4;
    -- Num of clk cycles for the serial clock to end
    constant END_SCLK : positive := 21;

    -- Register to store the serial clock, needed because we also need to read the previous sclk signal
    signal SCLK_reg : std_logic;
    -- Counter that keeps track of the clk cycles during the conversion
    signal counter : natural range 0 to 36;
    -- Register to store the start pulse and delay the triggering of the CNV pulse one cycle
    signal start_pulse_reg : std_logic;
    
--  attribute mark_debug : string;
--  attribute mark_debug of counter                 : signal is "true";
--  attribute mark_debug of start_pulse_reg_ff      : signal is "true";
--  attribute mark_debug of SCLK_reg                : signal is "true";
    
    
begin

    SCLK <= SCLK_reg;

    adc_gates_generation : process (clk, nrst)
    -- Clocked state transitions
    begin
        if nrst = '1' then
            CNV <= '0';
            SCLK_reg <= '0';
            counter <= 0;
            start_pulse_reg <= '0';
            
        elsif (rising_edge(clk)) then

            -- Delay for the start pulse
            if start_pulse = '1' then
                start_pulse_reg <= '1';
            end if;
            
            -- CNV high for 3 clock cycles => 30ns
            if ((start_pulse_reg = '1')  or  (counter = 1) or  (counter = 2)) then
                CNV <= '1';
                start_pulse_reg <= '0';
                counter <= counter + 1;
            else
                CNV <= '0';
            end if;
            
            -- Serial clock 8 cycles => 16 clk cycles
            if ((counter > START_SCLK)  and  (counter < END_SCLK)) then
                SCLK_reg <= not SCLK_reg;
            end if;
            
            -- Counter update
            if (counter = END_SCLK - 1) then
            -- Conversion finished. We set to 0 one cycle before it will be updated on next cycle
                counter <= 0;
            elsif counter > 0 then
            -- The conversion has started
            counter <= counter + 1;
            end if;

        end if;

    end process adc_gates_generation;

end behave;
