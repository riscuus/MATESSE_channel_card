----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 27.02.2022
-- Module Name: ADC_simulator
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Module to simulate the ADC behaviour. Only used for testing
-- 
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


entity ADC_simulator is
    generic (
        ADC_WORD_LENGTH : natural -- 16
    );
    port ( 
        clk     : in std_logic; -- 100Mhz clock
        rst     : in std_logic; -- Async reset
        nCNV    : in std_logic; -- CNV signal active low for the ADC
        SCK     : in std_logic; -- Serial clock for the ADC
        data    : in std_logic_vector(ADC_WORD_LENGTH - 1 downto 0); -- Data to be sent through the serial output
        SDO     : out std_logic -- Serial data output
    );
end ADC_simulator;

architecture Behavioral of ADC_simulator is
    -- Register that stores the data at the moment of capture
    signal data_reg     : std_logic_vector(ADC_WORD_LENGTH - 1 downto 0) := (others => '0');
    -- Keeps track of the bit that has to be sent
    signal counter : unsigned(bits_req(ADC_WORD_LENGTH - 1) - 1 downto 0) := (others => '0');

    type stateType is (idle, wait_nCNV_low, wait_SCK_high, wait_SCK_low);
    signal state : stateType := idle;

begin

    SDO <= data_reg(to_integer((ADC_WORD_LENGTH - 1) - counter));

    main_logic : process(rst, clk)
    begin
        if(rst = '1') then
            data_reg <= (others => '0');
            counter <= (others => '0');

            state <= idle;

        elsif(rising_edge(clk)) then
            case state is
                when idle =>
                    if (nCNV = '1') then
                        state <= wait_nCNV_low;
                    end if;
                when wait_nCNV_low =>
                    if (nCNV = '0') then
                        data_reg <= data;
                        state <= wait_SCK_high;
                    end if;
                
                when wait_SCK_high =>
                    if (SCK = '1') then
                        counter <= counter + 1;
                        state <= wait_SCK_low;
                    end if;
                
                when wait_SCK_low =>
                    if (SCK = '0') then
                        counter <= counter + 1;
                        if (counter = ADC_WORD_LENGTH - 1) then
                            counter <= (others => '0');
                            state <= idle;
                        else
                            state <= wait_SCK_high;
                        end if;
                    end if;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;


end Behavioral;
