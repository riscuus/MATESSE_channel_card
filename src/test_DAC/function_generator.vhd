----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 08.02.2020
-- Module Name: function_generator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Generation of the different data and the start_conv signals to generate a triangular function
--              This module is only intended for the testing of the DAC components
--              The idea is to generate a triangular function of a frequency of around 1KHz.
--              We will have 512 samples and a difference in voltage of 256 bits. Which means that we will have a 
--              new voltage level (data) every 2000ns more or less, which are 200 clk cycles
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

entity function_generator is
    port ( 
        -- 100MHz clock
        clk : in std_logic;
        -- Async reset
        rst : in std_logic;
        -- Signal that determines if the function generator must be active
        enabled : in std_logic;
        -- Signal to announce that a new DAC cycle must start
        DAC_start_pulse : out std_logic;
        -- Signal that announces that the current data is already valid
        data_valid : out std_logic;
        -- The data to be sent to the DAC
        parallel_data : out std_logic_vector(17 downto 0)
    );
end function_generator;

architecture Behavioral of function_generator is
    -- Number of samples for the rising edge of the triangular function
    constant NUM_HALF_SAMPLES : positive := 256;
    -- Number of samples for the whole period of the triangular function
    constant NUM_SAMPLES : positive := 512;
    -- The increment in voltage value on each sample
    constant INCREMENT : positive := 256;
    -- The number of clk cycles between each new sample
    constant NEW_VALUE_CLK_CYCLES : positive := 200;
    -- The number of clk cycles before triggering the start pulse
    constant TRIGGER_START_PULSE : positive := 2;
    -- The number of clk cycles that the start pulse lasts
    constant START_PULSE_DURATION : positive := 1;

    -- Counter for the number of clk cycles
    signal clk_count : natural range 0 to NEW_VALUE_CLK_CYCLES := 0;
    -- Counter for the number of samples
    signal sample_count : positive := 1;
    -- The value of each sample
    signal data : std_logic_vector(15 downto 0) := (others => '0');
begin

    generation : process (clk, rst)
    begin
        if (rst = '1') then
            DAC_start_pulse <= '0';
            --parallel_data <= (others => '0');
            data <= (others => '0');
            sample_count <= 1;
            clk_count <= 0;
        elsif(rising_edge(clk)) then
            if(enabled = '1') then
                -- We only update the data value every NEW_VALUE_CLK_CYCLES
                if(clk_count = NEW_VALUE_CLK_CYCLES) then
                    data_valid <= '0';
                    if (sample_count <= NUM_HALF_SAMPLES) then
                        -- Just for the first step we just increment INCREMENT - 1 in order to not overpass in the last sample
                        if(sample_count = 1) then
                            data <= std_logic_vector(unsigned(data) + INCREMENT - 1);
                        else
                            data <= std_logic_vector(unsigned(data) + INCREMENT);
                        end if;
                        sample_count <= sample_count + 1;
                    end if;
                    
                    if (sample_count > NUM_HALF_SAMPLES and sample_count < NUM_SAMPLES) then
                        data <= std_logic_vector(unsigned(data) - INCREMENT);
                        sample_count <= sample_count + 1;
                    end if;

                    -- Once we have done the whole period we reset the variable and the cycle starts again
                    if (sample_count = NUM_SAMPLES) then
                        data <= (others => '0');
                        sample_count <= 1;
                    end if;
                    clk_count <= 0;
                else 
                    clk_count <= clk_count + 1;
                end if;

                if (clk_count = TRIGGER_START_PULSE) then
                    data_valid <= '1';
                    DAC_start_pulse <= '1';
                end if;
                if (clk_count = TRIGGER_START_PULSE + START_PULSE_DURATION) then
                    DAC_start_pulse <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Address bits of the DAC
    parallel_data(17 downto 16) <= "11";
    -- Voltage bits
    parallel_data(15 downto 0) <= data;

end Behavioral;
