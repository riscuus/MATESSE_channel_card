----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 27.02.2022
-- Module Name: input_shift_register.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module that reads the serial data from ADC and parallelizes it. The first bit comes directly from the 
--              serial ouput of the ADC. The rest of the bits come from the ddr_input module.
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


entity input_shift_register is
    port ( 
        clk                     : in std_logic; -- 100 MHz clock
        nrst                    : in std_logic; -- Async reset active low
        serial_clk              : in std_logic; -- The serial clock sent to ADC
        iddr_parallel_output    : in std_logic_vector(1 downto 0); -- Output of the ddr_input module
        conv_started            : in std_logic; -- Pulse that indicates that the conversion has started
        valid_word              : out std_logic; -- Active when the 16 bits have been read
        parallel_data           : out std_logic_vector(15 downto 0) -- Data parallelized
    );
end input_shift_register;

architecture Behavioral of input_shift_register is
    -- Register to store the data received
    signal input_word_iddr : std_logic_vector(15 downto 0) := (others => '0');
    -- Register that indicates if the shifting register must be working or not
    signal shift_on : std_logic := '0';
    -- Register that serves as condition to know when the iddr_parallel_output data is valid
    signal valid_bits : std_logic := '0';
    -- Bits counter
    signal counter : natural range 0 to 16 := 0;
begin

    process(clk, nrst) is
    begin
        if nrst = '1' then
            input_word_iddr <= (others => '0');
            valid_word <= '0';
            shift_on <= '0';
            counter <= 0;
            valid_bits <= '0';
            
        elsif rising_edge(clk) then
            -- Conversion has started
            if(conv_started = '1') then
                shift_on <= '1';
            end if;

            -- Serial clock has started
            if (serial_clk = '1' and shift_on = '1') then
                valid_bits <= '1';
            end if;

            -- Store iddr_parallel_output and shift bits
            if (serial_clk = '0' and valid_bits = '1') then
                -- We store them in reverse order because the output of the iddr_input sets the MSB as the LSB
                input_word_iddr(0) <= iddr_parallel_output(1); 
                input_word_iddr(1) <= iddr_parallel_output(0);
                input_word_iddr(15 downto 2) <= input_word_iddr(13 downto 0);
                counter <= counter + 2;
                valid_bits <= '0';
            end if;
            -- Note that we read 16 bits but the condition has to be set at 14 because the counter will be updated on
            -- next cycle
            if (counter = 14) then
                shift_on <= '0';
                valid_word <= '1';
            end if;

            if (valid_word = '1') then
                valid_word = '0';
            end if;
        end if;
    end process;

    parallel_data <= input_word_iddr;

end Behavioral;
