----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 20.07.2022
-- Module Name: input_shift_register.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module that reads the serial data from ADC and parallelizes it.
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
use ieee.numeric_std.all;

library concept;
use concept.utils.all;


entity input_shift_register is
    generic(
        ADC_WORD_LENGTH : natural;
        DDR_bits        : natural
    );
    port ( 
        clk                     : in std_logic; -- 100 MHz clock
        rst                     : in std_logic; -- Async reset active low
        ddr_parallel            : in std_logic_vector(DDR_bits - 1 downto 0); -- Output of the ddr_input module
        ddr_valid               : in std_logic;
        ADC_word                : out std_logic_vector(ADC_WORD_LENGTH - 1 downto 0); -- Data parallelized
        valid_word              : out std_logic -- Active when the 16 bits have been read
    );
end input_shift_register;

architecture Behavioral of input_shift_register is
    -- Num of cycles that the SCK does. As we use DDR it is 8
    constant NUM_SCK_CYCLES : positive := ADC_WORD_LENGTH / 2;
    -- Register to store the data received
    signal ADC_word_reg : std_logic_vector(ADC_WORD_LENGTH - 1 downto 0) := (others => '0');
    signal valid_word_reg : std_logic := '0';
    -- SCK cycles counter
    signal counter : unsigned(bits_req(NUM_SCK_CYCLES - 1) - 1 downto 0) := (others => '0');

begin

    ADC_word <= ADC_word_reg;
    valid_word <= valid_word_reg;

    process(clk, rst) is
    begin
        if rst = '1' then
            ADC_word_reg <= (others => '0');
            valid_word_reg <= '0';
            counter <= (others => '0');
            
        elsif rising_edge(clk) then
            valid_word_reg <= '0';
            if (ddr_valid = '1') then
                if (counter = NUM_SCK_CYCLES - 1) then
                    valid_word_reg <= '1';
                    counter <= (others => '0');
                else
                    counter <= counter + 1;
                end if;

                -- Shift the bits
                ADC_word_reg(ADC_WORD_LENGTH - 1 downto DDR_bits) <= ADC_word_reg(ADC_WORD_LENGTH - DDR_bits - 1 downto 0);
                -- Store the new bits
                ADC_word_reg(0) <= ddr_parallel(1);
                ADC_word_reg(1) <= ddr_parallel(0);

            end if;
        end if;
    end process;

end Behavioral;
