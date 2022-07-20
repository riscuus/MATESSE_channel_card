----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.19.2022
-- Module Name: clocked_ddr_input.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module to read the DDR input signal, using a higher frequency clk
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


entity clocked_ddr_input is
    generic(
        DLY_CYCLES_WIDTH : natural
    );
    port ( 
        rst             : in std_logic; -- Async reset
        clk             : in std_logic; -- 200 Mhz clk
        dly_cycles      : in unsigned(DLY_CYCLES_WIDTH - 1 downto 0);
        serial_clk      : in std_logic; -- The 50 Mhz SCK
        serial_in       : in std_logic; -- The serialized DDR data
        parallel_out    : out std_logic_vector(1 downto 0); -- The ouput data
        parallel_valid  : out std_logic -- Pulse indicating that a pair of bits have been received
    );
end clocked_ddr_input;

architecture Behavioral of clocked_ddr_input is

    type stateType is (wait_serial_high, wait_serial_low);
    signal state : stateType := wait_serial_high;

    signal rising_bit_reg       : std_logic := '0';
    signal parallel_out_reg     : std_logic_vector(1 downto 0) := (others => '0');
    signal parallel_valid_reg   : std_logic := '0';

    signal cycles_ctr : unsigned(DLY_CYCLES_WIDTH - 1 downto 0) := (others => '0');

begin

    parallel_out    <= parallel_out_reg;
    parallel_valid  <= parallel_valid_reg;

    main_logic : process(clk, rst)
    begin
        if(rst = '1') then
            rising_bit_reg <= '0';
            parallel_valid_reg <= '0';
            cycles_ctr <= (others => '0');
            
            state <= wait_serial_high;
        elsif (rising_edge(clk)) then
            case state is
                when wait_serial_high =>
                    parallel_valid_reg <= '0';
                    if (serial_clk = '1') then
                        if (cycles_ctr = dly_cycles - 1) then
                            rising_bit_reg <= serial_in;
                            state <= wait_serial_low;
                        else
                            cycles_ctr <= cycles_ctr + 1;
                        end if;
                    end if;

                when wait_serial_low =>
                    if (serial_clk = '0') then
                        if (cycles_ctr = dly_cycles - 1) then
                            parallel_out_reg(0) <= rising_bit_reg;
                            parallel_out_reg(1) <= serial_in;
                            parallel_valid_reg <= '1';
                            state <= wait_serial_high;
                        else
                            cycles_ctr <= cycles_ctr + 1;
                        end if;
                    end if;

                when others =>
                    state <= wait_serial_high;
            end case;
        end if;
    end process;

end Behavioral;
