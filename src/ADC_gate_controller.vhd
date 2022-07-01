----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 05.02.2020
-- Module Name: ADC_gate_controller.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Generation of the serial lines for controlling the ADC LTC2325-16. 
--              General requirements for the controller:
--                  - The CNV is triggered after the start_pulse and must be a pulse signal of at least 30ns
--                  - A minimum delay of 20 ns must exist between the falling edge of the CNV signal and the first 
--                    cycle of the serial clock => We will use 2 cycles of the 100Mhz clock
--                  - The serial clock must have a period of at least 18.2 ns => 2 cycles of the 100Mhz clock
--                  - The serial clock must output exactly 8 pulses
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library concept;
use concept.utils.all;

entity ADC_gate_controller is
    generic(
        NUM_OF_SCK_CYCLES : positive
    );
    port(
        clk             : in std_logic; -- 100MHz clock
        rst             : in std_logic; -- Async reset

        cnv_len         : in unsigned(ADC_PARAMS_WIDTH - 1 downto 0);
        sck_dly         : in unsigned(ADC_PARAMS_WIDTH - 1 downto 0);
        sck_half_period : in unsigned(ADC_PARAMS_WIDTH - 1 downto 0);

        start_pulse     : in std_logic; -- Input pulse that indicates that a new conversion must start

        CNV             : out std_logic; -- Output CNV pulse 30ns min high
        SCK             : out std_logic -- Serial output clock, min period 18.2 ns
    );
end ADC_gate_controller;


architecture behave OF ADC_gate_controller is


    signal CNV_counter : unsigned(cnv_len'range)            := (others => '0');
    signal wait_SCK_counter : unsigned(sck_dly'range)       := (others => '0');
    signal SCK_counter : unsigned(sck_half_period'range)    := (others => '0');
    signal SCK_cycles_counter : unsigned(bits_req(NUM_OF_SCK_CYCLES - 1) - 1 downto 0) := (others => '0');

    type StateType is (init, wait_start_pulse, CNV_active, wait_serial_clk, SCK_active, SCK_non_active);
    signal state : StateType;
    
--  attribute mark_debug : string;
--  attribute mark_debug of start_pulse_reg_ff      : signal is "true";
    
    
begin

    adc_gates_generation : process (clk, rst)
    begin
        if rst = '1' then
            state <= init;
        elsif (rising_edge(clk)) then
            case state is
                when init =>
                    CNV_counter         <= (others => '0');
                    wait_SCK_counter    <= (others => '0');
                    SCK_counter         <= (others => '0');
                    SCK_cycles_counter  <= (others => '0');
                    CNV <= '0';
                    SCK <= '0';

                    state <= wait_start_pulse;
                when wait_start_pulse =>
                    if(start_pulse = '1') then
                        CNV <= '1';
                        state <= CNV_active;
                    else
                        state <= state;
                    end if;
                when CNV_active =>
                    if(CNV_counter = cnv_len - 1) then
                        CNV <= '0';
                        CNV_counter <= (others => '0');
                        state <= wait_serial_clk;
                    else
                        CNV_counter <= CNV_counter + 1;
                        state <= state;
                    end if;
                when wait_serial_clk =>
                    if(wait_SCK_counter = sck_dly - 1) then
                        SCK <= '1';
                        wait_SCK_counter <= (others => '0');
                        state <= SCK_active;
                    else
                        wait_SCK_counter <= wait_SCK_counter + 1;
                        state <= state;
                    end if;
                when SCK_active => 
                    if(SCK_counter = sck_half_period - 1) then 
                        SCK_counter <= (others => '0');
                        SCK <= '0';
                        state <= SCK_non_active;
                    else 
                        SCK_counter <= SCK_counter + 1;
                        state <= state;
                    end if;
                when SCK_non_active =>
                    if(SCK_counter = sck_half_period - 1) then
                        SCK_counter <= (others => '0');
                        if(SCK_cycles_counter = NUM_OF_SCK_CYCLES - 1) then
                            SCK_cycles_counter <= (others => '0');
                            if (start_pulse = '1') then
                                CNV <= '1';
                                state <= CNV_active;
                            else
                                state <= wait_start_pulse;
                            end if;
                        else
                            SCK_cycles_counter <= SCK_cycles_counter + 1;
                            SCK <= '1';
                            state <= SCK_active;
                        end if;
                    else
                        SCK_counter <= SCK_counter + 1;
                        state <= state;
                    end if;
                when others =>
                    state <= init;
            end case;
        end if;

    end process adc_gates_generation;

end behave;
