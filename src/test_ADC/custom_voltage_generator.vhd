----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03.19.2020
-- Module Name: custom_voltage_generator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Component that allows the user to set a custom data to be sent to the DACs components
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


entity custom_voltage_generator is
    port (
        clk : in std_logic; -- 100Mhz clk
        rst : in std_logic; -- Asynchronous active high reset
        address : in std_logic_vector(1 downto 0); -- Address of the DAC
        voltage : in std_logic_vector(15 downto 0); -- Voltage as a binary of 16 bits
        send_pulse : in std_logic; -- When data has been set, an active high pulse of this signal will trigger the execution
        parallel_data : out std_logic_vector(17 downto 0); 
        data_valid : out std_logic;
        DAC_start_pulse : out std_logic
     );
end custom_voltage_generator;

architecture Behavioral of custom_voltage_generator is
    -- Specifies how many clk cycles have to pass between iterations. (This is done in order to let enough time to pass)
    constant DELAY_BETWEEN_STARTS : positive := 160;
    
    -- States of the state machine
    type StateType is (init, wait_send_pulse, set_data_valid, trigger_start_pulse, untrigger_start_pulse,
                       wait_next_iteration);
    signal state : StateType;

    -- clk count to know when to accept next value
    signal clk_count : natural range 0 to DELAY_BETWEEN_STARTS := 0;
begin

    parallel_data(17 downto 16) <= address;
    parallel_data(15 downto 0)  <= voltage;

    generation : process (clk, rst)
    begin
        if (rst = '1') then
            data_valid <= '0';
            DAC_start_pulse <= '0';

        elsif(rising_edge(clk)) then
            case state is
                when init =>
                    clk_count <= 0;
                    data_valid <= '0';
                    DAC_start_pulse <= '0';
                    state <= wait_send_pulse;

                when wait_send_pulse =>
                    if (send_pulse = '1') then
                        state <= set_data_valid;
                    else
                        state <= state;
                    end if;
                when set_data_valid =>
                    data_valid <= '1';
                    state <= trigger_start_pulse;

                when trigger_start_pulse => 
                    DAC_start_pulse <= '1';
                    state <= untrigger_start_pulse;

                when untrigger_start_pulse =>
                    DAC_start_pulse <= '0';
                    state <= wait_next_iteration;

                when wait_next_iteration =>
                    if (clk_count = DELAY_BETWEEN_STARTS - 1) then
                        if(send_pulse = '0') then -- We will only accept a new iteration when the send_pulse has finsihed
                            state <= init;
                        else
                            state <= state;
                        end if;
                    else 
                        clk_count <= clk_count + 1;
                        state <= state;
                    end if;

                when others =>
                    state <= init;
            end case;
        end if;
    end process generation;
end Behavioral;
