----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 05/02/2020
-- Module Name: DAC_controller
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Generation of the serial lines for controlling the ADC LTC2325-16

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

entity DAC_controller IS
    port(   clock                   : in std_logic;
            rst                     : in std_logic;
            start_conv_pulse        : in std_logic;
            CS                      : out std_logic;
            CLK                     : out std_logic;
            LDAC                    : out std_logic
            );
end DAC_controller;


architecture behave of DAC_controller is

    
    signal CLK_reg : std_logic;
    signal CS_reg : std_logic;
    signal CLK_counter : unsigned(4 downto 0); 
    signal cycle_on : std_logic;
    signal LDAC_reg: std_logic;
    signal half_bit_counter: unsigned(5 downto 0);
    signal load_input_register: std_logic;
    
--  attribute mark_debug : string;
    
--  attribute mark_debug of CNV_counter : signal is "true";
    
begin

CLK <= CLK_reg;
CS <= CS_reg;
LDAC <= LDAC_reg;

SCK_generation: process (clock, rst )
-- Clocked state transitions
begin
    if rst  = '1' then
        CS_reg <= '1';
        CLK_reg <= '0';
        cycle_on <= '0';
        LDAC_reg <= '1';
        CLK_counter <= (others => '0');
        half_bit_counter <= (others => '0');
        load_input_register <= '0';
                
    elsif (rising_edge(clock)) then
        -- Start pulse received, cycle starts
        if start_conv_pulse = '1' then
            cycle_on <= '1';
        end if;

        -- Set activate low CS
        if cycle_on = '1' then
            CS_reg <= '0';
        end if;
        
        -- Counter for the CLK signal
        if cycle_on = '1' and half_bit_counter < 36 then
          CLK_counter <= CLK_counter + 1; -- 3 clock cycles is 30ns.
        end if;
        
        -- CLK starts, pulses of 40ns (4 clock cycles)
        if CLK_counter = 3 and load_input_register = '0' then
            CLK_reg <= not CLK_reg;
            CLK_counter <= (others => '0');
            half_bit_counter <= half_bit_counter + 1; 
        end if;
        
        -- End of cycle
        if (half_bit_counter = 36) then
            cycle_on <= '0';
            half_bit_counter <= (others => '0');
            load_input_register <= '1';
        end if;
        
        -- CS deactivate high, and send a low LDAC pulse to save sent data
        if load_input_register = '1' then
            CLK_counter <= CLK_counter + 1;
            -- Deactivate CS
            if CLK_counter = 2 then
              CS_reg <= '1';
            end if;
            
            -- LDAC pulse of 30ns
            if CLK_counter = 4 then
              LDAC_reg <= '0';
            end if;
            if CLK_counter = 7 then
              LDAC_reg <= '1';
            end if;  

            -- LDAC deactivated hold for 30ns
            if CLK_counter = 10 then
              load_input_register <= '0';
              CLK_counter <= (others => '0');	      
            end if;
        end if;
    end if;

end process SCK_generation;

end behave;
