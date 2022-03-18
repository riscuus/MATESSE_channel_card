----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03.15.2020
-- Module Name: DAC_voltage_generator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Generatio of different voltages based on the inputs

-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library concept;
use concept.all;

entity DAC_voltage_generator is
    port ( 
        -- 100MHz clock
        clk : in std_logic;
        -- Async reset
        rst : in std_logic;
        -- Signal that determines if the function generator must be active
        enabled : in std_logic;
        -- Pulse to increment voltage in X ammount  
        v0_pulse : in std_logic;
        -- Pulse to decrement voltage in X ammount
        v1_pulse : in std_logic;
        -- Pulse to increment voltage in Y ammount
        v2_pulse : in std_logic;
        -- Pulse to decrement voltage in Y ammount
        v3_pulse : in std_logic;
        -- Signal to announce that a new DAC cycle must start
        DAC_start_pulse : out std_logic;
        -- Signal that announces that the current data is already valid
        data_valid : out std_logic;
        -- The data to be sent to the DAC
        parallel_data : out std_logic_vector(17 downto 0)
    );
end DAC_voltage_generator;

architecture Behavioral of DAC_voltage_generator is
    -- The number of clk cycles before triggering the start pulse
    constant TRIGGER_START_PULSE : positive := 2;
    -- The number of clk cycles that the start pulse lasts
    constant START_PULSE_DURATION : positive := 1;
    -- Increment when btn 0 is clicked. Btn 1 will decrement by this value
    constant INCREMENT_0_1 : positive := 64;
    -- Increment when btn 2 is clicked. Btn 3 will decrement by this value
    constant INCREMENT_2_3 : positive := 4096; 
    -- Max value that the data can have
    constant DATA_MAX_VALUE : positive := 65535;
    -- Min value that the data can have
    constant DATA_MIN_VALUE : natural := 0;
    -- Number of "DACs" inside a DAC component
    constant NUM_OF_DACS : natural := 4;
    -- Delay between start_pulse triggers in clk cycles
    constant DELAY_BETWEEN_STARTS : natural := 160;


    -- Signal that stores current data to be sent
    signal data : std_logic_vector(15 downto 0) := (others => '0');
    -- DAC count. We must trigger the 4 DACs that are inside the DAC component
    signal DAC_count : natural range 0 to 3 := 0;
    -- clk count to wait for the next start pulse 
    signal clk_count : natural range 0 to 160 := 0;
    -- Address of the current DAC
    signal address : std_logic_vector(1 downto 0) := (others => '0');
    -- States of the state machine
    type StateType is (wait_pulse, clicked_0, clicked_1, clicked_2, clicked_3, set_new_address, gen_start_pulse, 
                       shut_down_start_pulse, wait_btn_down, wait_for_next_start);
    signal state : StateType;

begin

    generation : process (clk, rst)
    begin
        if (rst = '1') then
            DAC_start_pulse <= '0';
            data <= (others => '0');
            data_valid <= '0';
            DAC_count <= 0;
            clk_count <= 0;
            address <= (others => '0');

        elsif(rising_edge(clk)) then
            case state is
                when wait_pulse =>
                    if(v0_pulse = '1') then
                        state <= clicked_0;
                    elsif (v1_pulse = '1') then
                        state <= clicked_1;
                    elsif (v2_pulse = '1') then
                        state <= clicked_2;
                    elsif (v3_pulse = '1') then
                        state <= clicked_3;
                    else 
                        state <= wait_pulse;
                    end if;
                when clicked_0 =>
                    -- We check that we don't overflow the max data
                    if((resize(unsigned(data), 17) + INCREMENT_0_1) > DATA_MAX_VALUE) then
                        data <= (others => '1');
                    else 
                        data <= std_logic_vector(unsigned(data) + INCREMENT_0_1);
                    end if;
                    state <= set_new_address;
                when clicked_1 =>
                    -- We check that we don't overflow the min data
                    if(((signed(resize(unsigned(data), 17))) - to_signed(INCREMENT_0_1, 17)) < to_signed(0, 17)) then
                        data <= (others => '0');
                    else 
                        data <= std_logic_vector(unsigned(data) - INCREMENT_0_1);
                    end if;
                    state <= set_new_address;
                when clicked_2 =>
                    -- We check that we don't overflow the max data
                    if((resize(unsigned(data), 17) + INCREMENT_2_3) > DATA_MAX_VALUE) then
                        data <= (others => '1');
                    else 
                        data <= std_logic_vector(unsigned(data) + INCREMENT_2_3);
                    end if;
                    state <= set_new_address;
                when clicked_3 =>
                    -- We check that we don't overflow the min data
                    if(((signed(resize(unsigned(data), 17))) - to_signed(INCREMENT_2_3, 17)) < to_signed(0, 17)) then
                        data <= (others => '0');
                    else 
                        data <= std_logic_vector(unsigned(data) - INCREMENT_2_3);
                    end if;
                    state <= set_new_address;
                when set_new_address =>
                    address <= std_logic_vector(to_unsigned(DAC_count, 2));
                    state <= gen_start_pulse;
                when gen_start_pulse =>
                    DAC_start_pulse <= '1';
                    data_valid <= '1';
                    state <= shut_down_start_pulse;
                when shut_down_start_pulse =>
                    DAC_start_pulse <= '0';
                    if(DAC_count = NUM_OF_DACS - 1) then -- We check if this was already the last address
                        DAC_count <= 0;
                        state <= wait_btn_down; 
                    else
                        DAC_count <= DAC_count + 1;
                        state <= wait_for_next_start;
                    end if;
                when wait_btn_down =>
                    if (v0_pulse = '0' and v1_pulse = '0' and v2_pulse = '0' and v3_pulse = '0') then
                        state <= wait_pulse;
                    else
                        state <= state;
                    end if;
                when wait_for_next_start =>
                    if(clk_count = DELAY_BETWEEN_STARTS) then
                        clk_count <= 0;
                        state <= set_new_address;
                    else -- We will wait for X amount of clk cycles before triggering the next start with the new address
                        clk_count <= clk_count + 1;
                        state <= wait_for_next_start;
                    end if;
                when others => 
                    state <= wait_pulse; -- We should never enter here
            end case;
        end if;
    end process;
    
    -- Address bits of the DAC
    parallel_data(17 downto 16) <= address;
    -- Voltage bits
    parallel_data(15 downto 0) <= data;

end Behavioral;
