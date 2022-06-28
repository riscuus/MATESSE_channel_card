----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.29.2022
-- Module Name: sample_selector.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of specifying which samples are valid based on the given parameters

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

entity sample_selector is
    generic(
        MAX_SAMPLE_NUM : natural;
        MAX_SAMPLE_DLY : natural;
        DATA_WIDTH : natural
    );
    port(
        clk                     : in std_logic; -- 100MHz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        sample_dly              : in unsigned(bits_req(MAX_SAMPLE_DLY - 1) - 1 downto 0);   -- Num of samples to be discarted when a new row starts
        sample_num              : in unsigned(bits_req(MAX_SAMPLE_NUM - 1) - 1 downto 0);   -- Num of samples valid
        new_row                 : in std_logic; -- Pulse that indicates that a new row starts
        valid_word              : in std_logic; -- Pulse that indicates that we have a new sample data
        parallel_data           : in std_logic_vector(DATA_WIDTH - 1 downto 0); -- Data comming from the input shift register
        valid_sample            : out std_logic; -- Signal that indicates that the current sample is valid
        sample_data             : out std_logic_vector(DATA_WIDTH - 1 downto 0) -- Sample data sent to the sample accumulator
    );

end sample_selector;

architecture behave of sample_selector is

    type stateType is (idle, wait_sample);
    signal state : stateType;

    signal sample_count : unsigned(sample_num'range) := (others => '0');

begin


main_logic : process(clk, rst)
begin
    if (rst = '1') then
        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                valid_sample <= '0';
                sample_data <= (others => '0');
                sample_count <= (others => '0');
                if (new_row = '1') then
                    state <= wait_sample;
                else
                    state <= state;
                end if;
            
            when wait_sample =>
                -- Sample received
                valid_sample <= '0';
                if (valid_word = '1') then
                    if (sample_count > sample_dly - 1 and sample_count < (sample_dly + sample_num)) then
                        sample_data <= parallel_data;
                        valid_sample <= '1';
                    else
                        valid_sample <= '0';
                    end if;
                    sample_count <= sample_count + 1;
                end if;

                if (sample_count = sample_dly + sample_num) then -- All valid samples already received, wait next row
                    state <= idle;
                else
                    state <= state;
                end if;

            when others =>
                state <= idle;
        end case;
    end if;

end process;

end behave;