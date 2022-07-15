----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.14.2022
-- Module Name: triangular_samples_generator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of generating a new sample of a triangular waveform when requested.

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

entity triangular_samples_generator is
    generic(
        M          : natural -- N = 2^M number of samples to go from 0 to 1. The total number of samples for a period is 2N-2
    );
    port(
        clk                 : in std_logic; -- 5MHz clk
        rst                 : in std_logic; -- async reset

        next_sample         : in std_logic; -- Pulse to indicate the next sample

        data                : out unsigned(M - 1 downto 0); -- Quantized as binary fractional M decimal bits. So we will have M bits in total. Because we just want to go from 0000.. to 1111..
        data_valid          : out std_logic -- Pulse to indicate that data is valid
    );

end triangular_samples_generator;

architecture behave of triangular_samples_generator is
    constant MAX_SAMPLE : unsigned(M - 1 downto 0) := (others => '1');

    type stateType is (idle, calculate_next_sample);
    signal state : stateType := idle;

    -- Counter that will go from 0 to 2^M - 1
    signal samples_counter  : unsigned(M - 1 downto 0) := (others => '0');
    signal decreasing       : std_logic := '0'; -- Signal to know on which side of the triangle we currently are
    signal next_value       : unsigned(data'range) := (others => '0'); 

    -- Registers for outputs
    signal data_reg         : unsigned(data'range) := (others => '0'); -- Register for the output: data
    signal data_valid_reg   : std_logic := '0'; -- Register for the output: valid data

begin

    data <= data_reg;
    data_valid <= data_valid_reg;

    main_logic : process(clk, rst)
    begin
        if (rst = '1') then
            data_reg <= (others => '0');
            next_value <= (others => '0');
            samples_counter <= (others => '0');
            decreasing <= '0';
            data_valid_reg <= '0';

            state <= idle;
        elsif (rising_edge(clk)) then
            case state is
                when idle =>
                    if (next_sample = '1') then
                        data_valid_reg <= '1';
                        data_reg <= next_value;

                        state <= calculate_next_sample;
                    end if;

                when calculate_next_sample =>
                    data_valid_reg <= '0';

                    if (decreasing = '0') then -- Increasing side
                        if (samples_counter = MAX_SAMPLE - 1) then
                            decreasing <= '1';
                            next_value <= next_value - 1;
                            samples_counter <= (others => '0');
                        else
                            next_value <= next_value + 1;
                            samples_counter <= samples_counter + 1;
                        end if;
                    else -- decreasing side
                        if (samples_counter = (MAX_SAMPLE - 1) - 2) then -- We only allow 2^M - 2 decreasing samples because the 0 and the 2^M - 1 will be considered in the increasing side
                            decreasing <= '0';
                            next_value <= (others => '0');
                            samples_counter <= (others => '0');
                        else
                            next_value <= next_value - 1;
                            samples_counter <= samples_counter + 1;
                        end if;
                    end if;

                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end behave;