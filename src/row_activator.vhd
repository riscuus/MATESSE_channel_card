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
    port(
        clk                 : in std_logic; -- 5mhz clock                                                                           
        rst                 : in std_logic; -- asynchronous reset

        new_row             : in std_logic;    -- Pulse that indicates that a new row has started
        row_num             : in natural;      -- Signal that indicates in which row we currently are
        acquisition_on      : in std_logic;    -- Signal that indicates that the acquisition is currently active
        on_bias             : in t_param_array(0 to MAX_ROWS - 1); -- Value to be set to the row when it is active
        off_bias            : in t_param_array(0 to MAX_ROWS - 1); -- Value to be set to the row when it is deactivated
        num_rows            : in natural; -- Num of rows that are going to be multiplexed
        update_off_value    : in std_logic;    -- Pulse used to set the off value to all DAC when acquisition is off
        DAC_start_pulse     : out std_logic; -- Signal to start the DAC_gate_controller logic
        DAC_sel             : out natural; -- From 0 to 2, to select one of the 3 dacs
        DAC_data            : out std_logic_vector(17 downto 0) -- 2 bits of address + 16 bits of voltage data
    );

end row_activator;

architecture behave of row_activator is

    constant DAC_DLY : positive := 10; -- Cycles we must wait between DAC start pulses

    type stateType is (idle, deactivate_current, wait_deactivation, activate_next, wait_activation,
                       deactivate_all);
    signal state : stateType;

    -- Signal used to activate the generation of the DAC_start_pulse
    signal gen_start_pulse : std_logic := '0'; 

    -- From 0 to num_rows - 1, in the following order. 0=U20A, 1=U20B, .. , 10=U22C, 11=U22D
    signal selected_row : natural := 0; 

    -- Used to set the selected row when acquisition is off
    signal selected_row_acq_off : natural := 0; 

    -- Used to set the selected row when acquisition is on
    signal selected_row_acq_on : natural := 0; 

    -- Allows to choose between DACs A,B,C,D. Depends exclusively on selected_row
    signal address : std_logic_vector(1 downto 0) := "00"; 

    -- Voltage data sent to the DAC
    signal v_data : std_logic_vector(15 downto 0) := (others => '0'); 

    -- Counter used to go from row 0 to row num_rows - 1 when acq is off and we need to update the off_bias value
    signal row_counter : natural := 0;

    -- Signal used to know when to launch the start_DAC_pulses (one every DAC_DLY cycles)
    signal clk_counter : natural := 0;



begin


main_logic : process(clk, rst)
begin
    if (rst = '1') then
        row_counter <= 0;
        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                if (new_row = '1') then
                    state <= deactivate_current;
                elsif (acquisition_on = '0' and update_off_value = '1') then
                    state <= deactivate_all;
                else
                    state <= state;
                end if;
            
            when deactivate_current =>
                state <= wait_deactivation;

            when wait_deactivation =>
                if (clk_counter = DAC_DLY) then
                    state <= activate_next;
                else
                    state <= state;
                end if;

            when activate_next =>
                state <= wait_activation;

            when wait_activation =>
                if (clk_counter = DAC_DLY) then
                    state <= idle;
                else
                    state <= state;
                end if;

            when deactivate_all =>
                if (clk_counter = DAC_DLY) then
                    if (row_counter = num_rows - 1) then
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
        clk_counter <= 0;
    elsif (rising_edge(clk)) then
        if (gen_start_pulse = '1') then -- If remains active, this continuously generates start pulses each DAC_DLY
            if (clk_counter = 0) then
                clk_counter <= clk_counter + 1;
            elsif (clk_counter = DAC_DLY) then
                clk_counter <= 0;
            else
                clk_counter <= clk_counter + 1;
            end if;
        else
            clk_counter <= 0;
        end if;
    end if;
end process;

-- Combinatory assignments

gen_start_pulse <= '1' when state = deactivate_current or
                            state = wait_deactivation or
                            state = activate_next or
                            state = wait_activation or
                            state = deactivate_all else
                   '0';

selected_row <= selected_row_acq_off when state = deactivate_all else
                selected_row_acq_on;

selected_row_acq_on <= num_rows - 1 when row_num = 0  and (state = deactivate_current or state = wait_deactivation) else
                       row_num - 1  when row_num /= 0 and (state = deactivate_current or state = wait_deactivation) else
                       row_num      when state = activate_next or state = wait_activation else
                       0;

selected_row_acq_off <= row_counter;

address <= "00" when selected_row = 0 or selected_row = 4 or selected_row = 8 else -- DAC A
           "01" when selected_row = 1 or selected_row = 5 or selected_row = 9 else -- DAC B
           "10" when selected_row = 2 or selected_row = 6 or selected_row = 10 else -- DAC C
           "11"; -- DAC D

v_data <= on_bias(selected_row)(15 downto 0)   when state = activate_next or state = wait_activation else
          off_bias(selected_row)(15 downto 0)  when state = deactivate_current or state = wait_deactivation or state = deactivate_all else
          (others => '0');

DAC_sel <= 0 when selected_row < 4 else
           1 when selected_row >= 4 and selected_row < 8 else
           2;

DAC_data <= address & v_data;

DAC_start_pulse <= '1' when clk_counter = 0 and gen_start_pulse = '1' else
                   '0';


end behave;