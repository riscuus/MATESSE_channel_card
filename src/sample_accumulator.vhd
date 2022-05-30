----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.29.2022
-- Module Name: sample_accumulator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of accumulating a number of valid samples

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

entity sample_accumulator is
    port(
        clk                     : in std_logic; -- 100MHz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        sample_num              : in natural; -- Num of samples to be accumulated
        valid_sample            : in std_logic; -- Signal that indicates that the current sample is valid
        sample                  : in t_adc_sample; -- Sample data sent to the sample accumulator
        acc_sample              : out t_word;       -- Output data (samples accumulated)
        valid                   : out std_logic   -- Parameter that indicates that the data is already valid
    );

end sample_accumulator;

architecture behave of sample_accumulator is

    type stateType is (idle, accumulate);
    signal state : stateType;

    signal acc_sample_int : integer := 0;
    signal sample_count : natural := 0;
    signal sample_reg : t_adc_sample := (others => '0');
    
begin

acc_sample <= std_logic_vector(to_signed(acc_sample_int, acc_sample'length));

main_logic : process(clk, rst)
begin
    if (rst = '1') then
        sample_count <= 0;
        acc_sample_int <= 0;
        valid <= '0';
        state <= idle;

    elsif (rising_edge(clk)) then
        case state is
            when idle => 
                sample_count <= 0;

                if (valid_sample = '1') then
                    valid <= '0';
                    acc_sample_int <= to_integer(signed(sample));
                    sample_count <= sample_count + 1;

                    if (sample_count = sample_count - 1) then -- Case sample_num = 1
                        valid <= '1';
                        state <= state;
                    else 
                        state <= accumulate;
                    end if;
                else
                    state <= state;
                end if;

            when accumulate =>
                if (valid_sample = '1') then
                    acc_sample_int <= acc_sample_int + to_integer(signed(sample));
                    if (sample_count = sample_num - 1) then
                        valid <= '1';
                        sample_count <= 0;
                        state <= idle;
                    else
                        sample_count <= sample_count + 1;
                        state <= state;
                    end if;
                end if;

            when others =>
                state <= idle;
        end case;
    end if;

end process;

end behave;