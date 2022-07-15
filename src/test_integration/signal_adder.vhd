----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.14.2022
-- Module Name: signal_adder.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of adding two signals.

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

entity signal_adder is
    generic(
        K_GAIN_WIDTH    : natural;
        DATA_WIDTH      : natural; -- Output data width
        M               : natural  -- Data is quantized as binary fractional of QM.
    );
    port(
        clk                 : in std_logic; -- 5MHz clk
        rst                 : in std_logic; -- async reset

        signal_0            : in unsigned(M - 1 downto 0); -- Data has M bits
        signal_1            : in unsigned(M - 1 downto 0); -- Data has M bits
        signal_1_en         : in std_logic; -- Indicates if the signal 1 is present or not
        signals_valid       : in std_logic; 
        
        downscaling         : in unsigned(K_GAIN_WIDTH - 1 downto 0); -- signal 1 will be downscaled a factor 2^downscaling
        k_gain              : in unsigned(K_GAIN_WIDTH - 1 downto 0); -- We will shift left k_gain bits, and shift right M bits
        offset              : in unsigned(DATA_WIDTH - 1 downto 0);

        data                : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        data_valid          : out std_logic
    );

end signal_adder;

architecture behave of signal_adder is

    type stateType is (idle, reg_sum, reg_amp);
    signal state : stateType := idle;

    signal signal_sum : unsigned(2*M - 1 downto 0) := (others => '0');
    signal signal_sum_reg : unsigned(signal_sum'range) := (others => '0');
    signal signal_amp : unsigned(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal signal_amp_reg : unsigned(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal signal_off : unsigned(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal signal_off_reg : unsigned(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal data_valid_reg : std_logic := '0';

begin

    -- 2M = max(2M, 2M)
    -- We sum and divide by 2 to scale again (approximately) to a fractional value between 0 and 1 (if signal_1 enabled)
    signal_sum <= shift_right(resize(signal_0, signal_sum'length) + resize(shift_right(signal_1, to_integer(downscaling)), signal_sum'length), 1) when signal_1_en = '1' else
                  resize(signal_0, signal_sum'length);
    signal_amp <= shift_left(signal_sum, to_integer(k_gain) - M)(DATA_WIDTH - 1 downto 0);
    signal_off <= signal_amp_reg + offset;

    data <= std_logic_vector(signal_off_reg);
    data_valid <= data_valid_reg;

    main_logic : process(clk, rst)
    begin
        if (rst = '1') then
            data_valid_reg <= '0';
        elsif (rising_edge(clk)) then
            case state is
                when idle =>
                    data_valid_reg <= '0';
                    if (signals_valid = '1') then
                        signal_sum_reg <= signal_sum;
                        state <= reg_sum;
                    end if;

                when reg_sum =>
                    signal_amp_reg <= signal_amp;
                    state <= reg_amp;
                
                when reg_amp =>
                    signal_off_reg <= signal_off;
                    data_valid_reg <= '1';
                    state <= idle;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end behave;