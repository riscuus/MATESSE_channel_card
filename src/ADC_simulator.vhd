----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 27.02.2022 16:53:30
-- Module Name: ADC_simulator
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module to simulate the ADC behaviour. Only used for testing
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


entity ADC_simulator is
    Port ( 
        nCNV : in std_logic;
        SCK : in std_logic;
        SDO : out std_logic
    );
end ADC_simulator;

architecture Behavioral of ADC_simulator is
    -- Data that will be sent through the serial output
    signal data : std_logic_vector(15 downto 0) := "1001101010111001";
    -- Keeps track of the bit that has to be sent
    signal counter : integer range 0 to 15 := 15;
    -- Register that allows us to know if currently we are in a conversion
    signal conversion_active : std_logic := '0';
begin

    serial_output : process (nCNV, SCK)
    begin
        if(rising_edge(nCNV)) then
            conversion_active <= '1';
        end if;
        -- TODO: for a more realistic simulation the first bit should wait up to 170ns to appear
        if(falling_edge(nCNV) or rising_edge(SCK) or falling_edge(SCK)) then
            if(conversion_active = '1') then 
                SDO <= data(counter);
                if (counter = 0) then 
                    counter <= 15;
                    conversion_active <= '0';
                else
                    counter <= counter - 1;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
