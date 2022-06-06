----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.31.2022
-- Module Name: feedback_calculator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of applying the gain parameter to the ADC sample and writing it into the RAM.

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

entity feedback_calculator is
    port(
        clk                 : in std_logic; -- 5mhz clock                                                                           
        rst                 : in std_logic; -- asynchronous reset

        acc_sample          : in t_word; -- The accumulated sample received from the sample_accumulator
        acc_sample_valid    : in std_logic; -- Pulse to indicate that the acc sample is already valid
        acc_sample_row      : in natural; -- The row the acc sample belongs to
        sa_fb_gain          : in integer; -- The gain to be applied to the acc sample
        write_row_num       : out natural; -- The address in the ram memory to write the calc_fb
        write_en            : out std_logic; -- Enable signal to write in the ram memory
        calc_fb             : out t_word -- The calculated fb = acc_sample * sa_fb_gain
    );

end feedback_calculator;

architecture behave of feedback_calculator is

    type stateType is (idle, write_ram);
    signal state : stateType;

    -- Internal register to store the acc sample as integer
    signal acc_sample_int : integer := 0;

begin

acc_sample_int <= to_integer(signed(acc_sample));

main_logic : process(clk, rst)
begin
    if (rst = '1') then
        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                write_en <= '0';
                write_row_num <= 0;
                calc_fb <= (others => '0');

                if(acc_sample_valid = '1') then
                    calc_fb <= std_logic_vector(to_signed(acc_sample_int * sa_fb_gain, calc_fb'length)); 
                    write_row_num <= acc_sample_row;
                    write_en <= '1';

                    state <= write_ram;
                else
                    state <= state;
                end if;
            when write_ram =>
                write_en <= '0';
                state <= idle;
            when others =>
                state <= idle;
        end case;
    end if;

end process;

end behave;