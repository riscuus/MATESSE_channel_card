----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.30.2022
-- Module Name: row_activator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of physically activating the current active row
--              When acquisition is off, if the update_off_value pulse is activated, logic is applied to set the bias_off to all DACS
--              When acquisition is on, when new_row starts we deactivate the current DAC (set its value to bias_off) 
--              and activate the next one

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

entity row_activator is
    generic(
        MAX_DAC_MODULES_ROW_ACTIVATOR   : positive; -- The number of DAC modules (each modules includes 4 dacs) connected to to set the row active voltage. 
        DAC_DLY                         : positive; -- The number of clk cycles that this modules waits to update the next dac voltage
        MAX_NUM_ROWS                    : positive; -- The max number of rows 
        VOLTAGE_SIZE                    : positive; -- The bits for the dac voltage
        ADDR_SIZE                       : positive  -- The bits for the dac addr
    );
    port(
        clk                 : in std_logic; -- 5mhz clock                                                                           
        rst                 : in std_logic; -- asynchronous reset

        -- param buffers
        on_bias             : in t_param_array(0 to PARAM_ID_TO_SIZE(to_integer(ON_BIAS_ID)) - 1); -- Value to be set to the row when it is active
        off_bias            : in t_param_array(0 to PARAM_ID_TO_SIZE(to_integer(OFF_BIAS_ID)) - 1); -- Value to be set to the row when it is deactivated
        num_rows            : in unsigned(bits_req(MAX_NUM_ROWS) - 1 downto 0); -- Num of rows that are going to be multiplexed

        new_row             : in std_logic;    -- Pulse that indicates that a new row has started
        row_num             : in unsigned(bits_req(MAX_NUM_ROWS - 1) - 1 downto 0);      -- Signal that indicates in which row we currently are
        acquisition_on      : in std_logic;    -- Signal that indicates that the acquisition is currently active
        update_off_value    : in std_logic;    -- Pulse used to set the off value to all DAC when acquisition is off

        DAC_start_pulse     : out std_logic; -- Signal to start the DAC_gate_controller logic
        DAC_sel             : out unsigned(bits_req(MAX_DAC_MODULES_ROW_ACTIVATOR) - 1 downto 0); -- From 0 to 2, to select one of the 3 dacs
        DAC_data            : out std_logic_vector(VOLTAGE_SIZE + ADDR_SIZE - 1 downto 0) -- 2 bits of address + 16 bits of voltage data
    );

end row_activator;

architecture behave of row_activator is

    type stateType is (idle, wait_deactivation, wait_activation, deactivate_all);
    signal state : stateType;

    -- Signal used to activate the generation of the DAC_start_pulse
    signal gen_start_signal : std_logic := '0'; 

    -- From 0 to num_rows - 1, in the following order. 0=U20A, 1=U20B, .. , 10=U22C, 11=U22D
    signal selected_row : unsigned(row_num'range) := (others => '0'); 

    -- Used to set the selected row when acquisition is off
    signal selected_row_acq_off : unsigned(row_num'range) := (others => '0'); 

    -- Used to set the selected row when acquisition is on
    signal selected_row_acq_on : unsigned(row_num'range) := (others => '0'); 

    -- Allows to choose between DACs A,B,C,D. Depends exclusively on selected_row
    signal address : std_logic_vector(ADDR_SIZE - 1 downto 0) := (others => '0'); 

    -- Voltage data sent to the DAC
    signal v_data : std_logic_vector(VOLTAGE_SIZE - 1 downto 0) := (others => '0'); 

    -- Counter used to go from row 0 to row num_rows - 1 when acq is off and we need to update the off_bias value
    signal row_counter : unsigned(row_num'range) := (others => '0');

    -- Signal used to know when to launch the start_DAC_pulses (one every DAC_DLY cycles)
    signal clk_counter : unsigned(bits_req(DAC_DLY - 1) - 1 downto 0) := (others => '0');



begin


main_logic : process(clk, rst)
begin
    if (rst = '1') then
        row_counter <= (others => '0');
        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                if (new_row = '1') then
                    gen_start_signal <= '1';
                    state <= wait_deactivation;
                elsif (acquisition_on = '0' and update_off_value = '1') then
                    gen_start_signal <= '1';
                    state <= deactivate_all;
                else
                    state <= state;
                end if;
            
            when wait_deactivation =>
                if (clk_counter = DAC_DLY - 1) then
                    state <= wait_activation;
                else
                    state <= state;
                end if;

            when wait_activation =>
                if (clk_counter = DAC_DLY - 1) then
                    gen_start_signal <= '0';
                    state <= idle;
                else
                    state <= state;
                end if;

            when deactivate_all =>
                if (clk_counter = DAC_DLY - 1) then
                    if (row_counter = num_rows - 1) then
                        gen_start_signal <= '0';
                        state <= idle;
                    else
                        row_counter <= row_counter + 1;
                        state <= deactivate_all;
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
        clk_counter <= (others => '0');
    elsif (rising_edge(clk)) then
        if (gen_start_signal = '1') then -- If remains active, this continuously generates start pulses each DAC_DLY
            if (clk_counter = 0) then
                clk_counter <= clk_counter + 1;
            elsif (clk_counter = DAC_DLY - 1) then
                clk_counter <= (others => '0');
            else
                clk_counter <= clk_counter + 1;
            end if;
        else
            clk_counter <= (others => '0');
        end if;
    end if;
end process;

-- Combinatory assignments

selected_row_acq_on <= resize(num_rows - 1, row_num'length) when row_num = 0  and state = wait_deactivation else
                       row_num - 1  when row_num /= 0 and state = wait_deactivation else
                       row_num      when state = wait_activation else
                       (others => '0');

selected_row_acq_off <= row_counter;

selected_row <= selected_row_acq_off when state = deactivate_all else
                selected_row_acq_on;

address <= "00" when selected_row = 0 or selected_row = 4 or selected_row = 8 else -- DAC A
           "01" when selected_row = 1 or selected_row = 5 or selected_row = 9 else -- DAC B
           "10" when selected_row = 2 or selected_row = 6 or selected_row = 10 else -- DAC C
           "11"; -- DAC D

v_data <= on_bias(to_integer(selected_row))(VOLTAGE_SIZE - 1 downto 0)   when state = wait_activation else
          off_bias(to_integer(selected_row))(VOLTAGE_SIZE - 1 downto 0)  when state = wait_deactivation or state = deactivate_all else
          (others => '0');

DAC_sel <= to_unsigned(0, DAC_sel'length) when selected_row < 4 else
           to_unsigned(1, DAC_sel'length) when selected_row >= 4 and selected_row < 8 else
           to_unsigned(2, DAC_sel'length);

DAC_data <= address & v_data;

DAC_start_pulse <= '1' when clk_counter = 0 and gen_start_signal = '1' else
                   '0';


end behave;