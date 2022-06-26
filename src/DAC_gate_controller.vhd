----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 06/26/2020
-- Module Name: DAC_gate_controller
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Generation of the serial lines for controlling the ADC LTC2325-16

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

entity DAC_gate_controller is
    generic(
        SCLK_TOTAL_PULSES   : positive := DAC_DATA_SIZE + DAC_ADDR_SIZE; -- The total number of serial clock pulses
        SCLK_HALF_PERIOD    : positive := 3; -- The half period of the serial clock. In clk cycles
        LDAC_SETUP          : positive := 1; -- The setup time for the LDAC signal in clk cycles
        LDAC_WIDTH          : positive := 3; -- The number of clk cycles that the LDAC must remain active
        LDAC_HOLD           : positive := 3 -- The time that LDAC must remain deactivated until a new cycle can start
    );
    port(
        clk                     : in std_logic; -- 100MHz clk
        rst                     : in std_logic; -- Async active high rst

        start_conv_pulse        : in std_logic; -- Indicates the start of a new cycle
        CS                      : out std_logic; -- CS active low
        SCLK                    : out std_logic; -- Serial clock
        LDAC                    : out std_logic -- LDAC active low
    );
end DAC_gate_controller;


architecture behave of DAC_gate_controller is

    type state_type is (idle, activate_CS, SCLK_gen, wait_deactivate_CS, wait_activate_LDAC, wait_deactivate_LDAC, wait_LDAC_hold);
    signal state : state_type := idle;

    signal SCLK_reg : std_logic := '0';

    signal SCLK_counter         : unsigned(bits_req(SCLK_HALF_PERIOD) - 1 downto 0) := (others => '0');
    signal half_pulses_counter  : unsigned(bits_req(2 * SCLK_TOTAL_PULSES) - 1 downto 0) := (others => '0');
    signal LDAC_setup_counter   : unsigned(bits_req(LDAC_SETUP) -1 downto 0) := (others => '0');
    signal LDAC_width_counter   : unsigned(bits_req(LDAC_WIDTH) -1 downto 0) := (others => '0');
    signal LDAC_hold_counter    : unsigned(bits_req(LDAC_HOLD) -1 downto 0) := (others => '0');

begin

SCLK <= SCLK_reg; 

SCK_generation: process (clk, rst)
begin
    if rst = '1' then
        SCLK_reg    <= '0';
        CS          <= '1';
        LDAC        <= '1';

        SCLK_counter        <= (others => '0');
        half_pulses_counter <= (others => '0');
        LDAC_setup_counter  <= (others => '0');

    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                if (start_conv_pulse = '1') then
                    CS <= '0';
                    state <= activate_CS;
                end if;

            when activate_CS =>
                SCLK_reg <= '1';
                state <= SCLK_gen;

            when SCLK_gen =>
                if (SCLK_counter = SCLK_HALF_PERIOD - 1) then
                    SCLK_reg <= not SCLK_reg;
                    SCLK_counter <= (others => '0');

                    if (half_pulses_counter = 2 * SCLK_TOTAL_PULSES - 1) then
                        SCLK_reg <= '0';
                        CS <= '1';
                        half_pulses_counter <= (others => '0');

                        state <= wait_activate_LDAC;
                    else
                        half_pulses_counter <= half_pulses_counter + 1;
                    end if;
                else
                    SCLK_counter <= SCLK_counter + 1;
                end if;
            
            when wait_activate_LDAC =>
                if (LDAC_setup_counter = LDAC_SETUP - 1) then
                    LDAC <= '0';
                    LDAC_setup_counter <= (others => '0');
                    state <= wait_deactivate_LDAC;
                else

                    LDAC_setup_counter <= LDAC_setup_counter + 1;
                end if;

            when wait_deactivate_LDAC =>
                if (LDAC_width_counter = LDAC_WIDTH - 1) then
                    LDAC <= '1';
                    LDAC_width_counter <= (others => '0');
                    state <= wait_LDAC_hold;
                else
                    LDAC_width_counter <= LDAC_width_counter + 1;
                end if;
            
            when wait_LDAC_hold =>
                if (LDAC_hold_counter = LDAC_HOLD - 1) then
                    LDAC_hold_counter <= (others => '0');
                    state <= idle;
                else
                    LDAC_hold_counter <= LDAC_hold_counter + 1;
                end if;
            
            when others =>
                state <= idle;
        end case;
    end if;

end process SCK_generation;

end behave;
