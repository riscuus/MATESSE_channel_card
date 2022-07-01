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

        acc_sample          : in t_channel_record; -- Contains the acc sample from the sample_accumulator, a signal indicating if its valid and the row it belongs to
        sa_fb_gain          : in signed(WORD_WIDTH - 1 downto 0); -- The gain to be applied to the acc sample
        fb_sample           : out t_channel_record -- Contains the fb value, signal indicating if it is valid and the row
                                                -- The value is simply the acc value * gain
                                                -- The valid signal is also use to enable the ram write
    );

end feedback_calculator;

architecture behave of feedback_calculator is

    type stateType is (idle, write_ram);
    signal state : stateType;

    -- Internal register to store the acc sample as integer
    signal calc_value : signed(WORD_WIDTH - 1 downto 0) := (others => '0');

begin

main_logic : process(clk, rst)
begin
    if (rst = '1') then

        fb_sample.valid <= '0';
        fb_sample.row_num <= (others => '0');
        fb_sample.value <= (others => '0');

        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                fb_sample.valid <= '0';

                if(acc_sample.valid = '1') then
                    fb_sample.value <= calc_value;
                    fb_sample.row_num <= acc_sample.row_num;
                    fb_sample.valid <= '1';

                    state <= write_ram;
                else
                    state <= state;
                end if;
            when write_ram =>
                fb_sample.valid <= '0';
                state <= idle;
            when others =>
                state <= idle;
        end case;
    end if;
end process;

calc_value <= to_signed(to_integer(acc_sample.value) * to_integer(sa_fb_gain), calc_value'length);

end behave;