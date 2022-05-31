----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.30.2022
-- Module Name: TES_bias_setter.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of setting the constant bias values for the TES detectors

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

entity TES_bias_setter is
    port(
        clk                     : in std_logic; -- 100MHz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        set_bias                : in std_logic; -- Pulse signal to start the setting of the values
        TES_bias                : in t_param_array(3 downto 0); -- Values to be set on each DAC
        DAC_start_pulse         : out std_logic; -- Pulse to be sent to the DAC gate controller to set the value
        DAC_data                : out std_logic_vector(17 downto 0) -- Data to be sent to the DAC (address + voltage)
    );

end TES_bias_setter;

architecture behave of TES_bias_setter is

    -- Number of DACs (each chip contains 4)
    constant NUM_DACs   : natural := 4;
    -- Delay between each start_DAC_pulse
    constant DAC_DLY    : natural := 10;

    -- States of the main state machine
    type stateType is (idle, update);
    signal state : stateType;

    -- Address of the DAC (A,B,C,D)
    signal address      : std_logic_vector(1 downto 0) := (others => '0');
    -- Voltage sent to the DAC
    signal v_data       : std_logic_vector(15 downto 0) := (others => '0');

    -- Signal to indicate the start pulse process to start generating the start pulse
    signal gen_start    : std_logic := '0';
    -- Counter to go through all the DACs
    signal dac_counter  : natural := 0;
    -- Counter to generater the start DAC pulse on every DAC_DLY
    signal clk_counter  : natural := 0;

begin

address <= "00" when dac_counter = 0 else
           "01" when dac_counter = 1 else
           "10" when dac_counter = 2 else
           "11";

v_data <= TES_bias(dac_counter)(15 downto 0) when dac_counter < NUM_DACs else
          (others => '0');

DAC_data <= address & v_data;

DAC_start_pulse <= '1' when clk_counter = 0 and gen_start = '1' else
                   '0';

main_logic : process(clk, rst)
begin
    if (rst = '1') then
        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                if (set_bias = '1') then
                    gen_start <= '1';
                    state <= update;
                else
                    state <= state;
                end if;
            when update =>
                if (clk_counter = DAC_DLY - 1) then
                    if (dac_counter = NUM_DACs - 1) then
                        gen_start <= '0';
                        dac_counter <= 0;
                        state <= idle;
                    else
                        dac_counter <= dac_counter + 1;
                    end if;
                end if;
                    
            when others =>
                state <= idle;
        end case;
    end if;
end process;

start_pulse_gen : process(clk, rst)
begin
    if (rst = '1') then
        clk_counter <= 0;
    elsif (rising_edge(clk)) then
        if (gen_start = '1') then
            if (clk_counter = DAC_DLY - 1) then
                clk_counter <= 0;
            else
                clk_counter <= clk_counter + 1;
            end if;
        end if;
    end if;
end process;

end behave;