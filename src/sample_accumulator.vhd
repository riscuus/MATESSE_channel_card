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
    generic(
        MAX_ROW_NUM : natural;
        MAX_SAMPLE_NUM : natural;
        DATA_WIDTH : natural
    );
    port(
        clk                     : in std_logic; -- 100MHz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        sample_num              : in unsigned(bits_req(MAX_SAMPLE_NUM) - 1 downto 0); -- Num of samples to be accumulated
        valid_sample            : in std_logic; -- Signal that indicates that the current sample is valid
        sample                  : in std_logic_vector(DATA_WIDTH - 1 downto 0); -- Sample data sent to the sample accumulator
        row_num                 : in unsigned(bits_req(MAX_ROW_NUM - 1) - 1 downto 0); -- Current row the samples belong to (we store the row of the first sample)
        acc_sample              : out t_channel_record -- Record object that contains: the acc samples, signal indicating if valid and the row_num to which belongs
    );

end sample_accumulator;

architecture behave of sample_accumulator is

    type stateType is (idle, accumulate);
    signal state : stateType;

    signal acc_sample_value_reg : signed(acc_sample.value'range) := (others => '0');
    signal sample_count : unsigned(sample_num'range) := (others => '0');
    signal sum_result : signed(acc_sample.value'range) := (others => '0');
    
begin


main_logic : process(clk, rst)
begin
    if (rst = '1') then
        sample_count <= (others => '0');
        acc_sample_value_reg <= (others => '0');
        acc_sample.value <= (others => '0');
        acc_sample.row_num <= (others => '0');
        acc_sample.valid <= '0';
        state <= idle;

    elsif (rising_edge(clk)) then
        case state is
            when idle => 
                sample_count <= (others => '0');
                acc_sample.valid <= '0';

                if (valid_sample = '1') then
                    acc_sample.row_num <= row_num;
                    acc_sample_value_reg <= resize(signed(sample), acc_sample_value_reg'length);
                    sample_count <= sample_count + 1;

                    if (sample_count = sample_num - 1) then -- Case sample_num = 1
                        acc_sample.valid <= '1';
                        state <= state;
                    else 
                        state <= accumulate;
                    end if;
                else
                    state <= state;
                end if;

            when accumulate =>
                if (valid_sample = '1') then
                    acc_sample_value_reg <= sum_result; -- Store the sum value
                    if (sample_count = sample_num - 1) then
                        acc_sample.valid <= '1';
                        sample_count <= (others => '0');
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

    sum_result <= acc_sample_value_reg + resize(signed(sample), acc_sample_value_reg'length);
    acc_sample.value <= acc_sample_value_reg;
end process;

end behave;