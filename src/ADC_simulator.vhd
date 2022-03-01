----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 27.02.2022
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
        clk     : in std_logic; -- 100Mhz clock
        nrst    : in std_logic; -- Async reset
        nCNV    : in std_logic; -- CNV signal active low for the ADC
        SCK     : in std_logic; -- Serial clock for the ADC
        SDO     : out std_logic -- Serial data output
    );
end ADC_simulator;

architecture Behavioral of ADC_simulator is
    -- Data that will be sent through the serial output
    signal data : std_logic_vector(15 downto 0) := "1001101010111001";
    -- Keeps track of the bit that has to be sent
    signal counter : integer range 0 to 15 := 15;
    -- Register that allows us to know if currently we are in a conversion
    signal conversion_active : std_logic := '0';
    -- Register to know when the conversion is about to start
    signal cnv_high : std_logic;

begin

    activate_module : process (nrst, clk)
    begin
        if(nrst = '1') then
            conversion_active <= '0';
            cnv_high <= '0';
        elsif (rising_edge(clk)) then
            if(nCNV = '1') then
                cnv_high <= '1';
            end if;
            if(nCNV = '0' and cnv_high = '1' and conversion_active = '0') then
                conversion_active <= '1';
            end if;
        end if;
    end process;

    sck_output : process (SCK)
    begin
        if(rising_edge(SCK)) then
            counter <= counter - 1;
        end if;
        if(falling_edge(SCK)) then
            if(counter = 0) then
                counter <= 15;
            else
                counter <= counter - 1;
            end if;
        end if;
    end process;

    SDO <= data(counter);

end Behavioral;
