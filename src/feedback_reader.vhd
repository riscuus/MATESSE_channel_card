----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.06.2022
-- Module Name: feedback_reader.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of reading from the dual ram component the feedback values and set them
--              as the data for next row

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

entity feedback_reader is
    port(
        clk             : in std_logic; -- 100MHz clock                                                                           
        rst             : in std_logic; -- asynchronous reset

        new_row         : in std_logic; -- Pulse sent by the row selector indicating the beginning of a new row
        row_num         : in natural;   -- The number of the new row
        num_rows        : in natural;   -- The total ammount of rows

        -- Interface with the dual ram
        read_address    : out natural; -- The row number from which we will read its feedback value in the ram
        read_data       : in t_word;   -- The data read from the ram
        
        sa_fb_data      : out std_logic_vector(15 downto 0) -- The voltage value to be set in the DAC 
    );

end feedback_reader;

architecture behave of feedback_reader is

    type stateType is (init, idle, wait_read_data, read_ram_data);
    signal state : stateType;

    signal next_fb_value : std_logic_vector(15 downto 0) := (others => '0');

begin


main_logic : process(clk, rst)
begin
    if (rst = '1') then
        state <= init;
    elsif (rising_edge(clk)) then
        case state is
            when init =>
                sa_fb_data <= (others => '0');
                read_address <= 0;
                state <= idle;

            when idle =>
                if (new_row = '1') then
                    sa_fb_data <= next_fb_value;

                    if(row_num = num_rows - 1) then
                        read_address <= 0;
                    else
                        read_address <= row_num + 1; -- We will read already the next row value
                    end if;

                    state <= wait_read_data;
                else
                    state <= state;
                end if;

            when wait_read_data =>
                state <= read_ram_data;

            when read_ram_data =>
                next_fb_value <= read_data(15 downto 0);
                state <= idle;

            when others =>
                state <= idle;
        end case;
    end if;

end process;

end behave;