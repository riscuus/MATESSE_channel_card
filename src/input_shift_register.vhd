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
        rst                     : in std_logic; -- Async reset active low
        serial_clk              : in std_logic; -- The serial clock sent to ADC
        iddr_parallel_output    : in std_logic_vector(1 downto 0); -- Output of the ddr_input module
        conv_started            : in std_logic; -- Pulse that indicates that the conversion has started
        valid_word              : out std_logic; -- Active when the 16 bits have been read
        parallel_data           : out std_logic_vector(15 downto 0) -- Data parallelized
    );
end input_shift_register;

architecture Behavioral of input_shift_register is
    -- Num of cycles that the SCK does. As we use DDR it is 8
    constant NUM_OF_SCK_CYCLES : positive := 8;
    -- Register to store the data received
    signal input_word_iddr : std_logic_vector(15 downto 0) := (others => '0');
    -- SCK cycles counter
    signal counter : natural range 0 to 8 := 0;


    type StateType is (init, wait_start, wait_sck_on, wait_sck_off, delay_valid_word, valid_word_on);
    signal state : StateType;
begin

    process(clk, rst) is
    begin
        if rst = '1' then
            state <= init;
            
        elsif rising_edge(clk) then
            case state is
                when init =>
                    input_word_iddr <= (others => '0');
                    counter <= 0;
                    state <= wait_start;

                when wait_start =>
                    if(conv_started = '1') then
                        state <= wait_sck_on;
                    else 
                        state <= state;
                    end if;

                when wait_sck_on =>
                    if(serial_clk = '1') then
                        state <= wait_sck_off;
                    else
                        state <= state;
                    end if;

                when wait_sck_off =>
                    if(serial_clk = '0') then
                        -- We store them in reverse order because the output of the iddr_input sets the MSB as the LSB
                        input_word_iddr(0) <= iddr_parallel_output(1); 
                        input_word_iddr(1) <= iddr_parallel_output(0);
                        input_word_iddr(15 downto 2) <= input_word_iddr(13 downto 0);
                        counter <= counter + 1;
                        -- Condition to know when to end shifting
                        if(counter = NUM_OF_SCK_CYCLES - 1) then
                            counter <= 0;
                            state <= delay_valid_word;
                        else
                            state <= wait_sck_on;
                        end if;
                    else
                        state <= state;
                    end if;

                when delay_valid_word =>
                    -- We delay one clock cycle the valid_word pulse
                    state <= valid_word_on;

                when valid_word_on =>
                    state <= init;

                when others =>
                    state <= init;
            end case;
        end if;
    end process;
    
    valid_word <= '1' when state = valid_word_on else
                  '0';
                      
    parallel_data <= input_word_iddr;

end Behavioral;
