----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03/15/2022
-- Module Name: tb_test_ADC.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench for testing the ADC functionality. This test bench includes an ADC simulator

-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library concept;
use concept.all;

entity tb_test_ADC is
end tb_test_ADC;

architecture Behavioral of tb_test_ADC is

    -- Constants
    constant T_HALF_CLK         : time := 5 ns;
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 100 ns;
    constant START_TIME_DAC     : time := 403 ns;
    constant START_TIME_ADC     : time := 512 ns;
    constant BTN_0              : time := 10 us;
    constant BTN_1              : time := 5 us;
    constant BTN_2              : time := 10 us;
    constant BTN_3              : time := 20 us;
    constant BTN_LENGTH         : time := 3 us;
    constant SIM_DURATION       : time := 10 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- Enbling signals
    signal DAC_enabled  : std_logic;
    signal ADC_enabled  : std_logic;

    -- Buttons signals
    signal btn0_signal : std_logic := '0';
    signal btn1_signal : std_logic := '0';
    signal btn2_signal : std_logic := '0';
    signal btn3_signal : std_logic := '0';

    -- ADC simulator signals
    signal ADC_CNV_signal   : std_logic;
    signal ADC_SCK_signal   : std_logic;
    signal ADC_SDO_signal   : std_logic;
    signal simulation_data  : std_logic_vector(15 downto 0) := "1001101100100110"; -- Which should be the equivalent of 2V

begin

    -- CLK generation
    clk_generation : process 
    begin
        sys_clk <= '1';
        wait for T_HALF_CLK; 
        sys_clk <= '0';
        wait for T_HALF_CLK;
    end process;

    -- Reset generation
    rst_generation : process
    begin
        sys_rst <= '0';
        wait for RST_START; 
        sys_rst <= '1';
        wait for RST_PULSE_LENGTH;
        sys_rst <= '0';
        wait for SIM_DURATION;
    end process;

    -- Enable DAC switch
    enable_DAC_generation : process
    begin
        DAC_enabled <= '0';
        wait for START_TIME_DAC;
        DAC_enabled <= '1';
        wait for SIM_DURATION;
    end process;

    -- Enable ADC switch
    enable_ADC_generation : process
    begin
        ADC_enabled <= '0';
        wait for START_TIME_ADC;
        ADC_enabled <= '1';
        wait for SIM_DURATION;
    end process;

    btn0 : process
    begin
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn2_signal <= '1';
        wait for BTN_LENGTH;
        btn2_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for BTN_0; 
        btn3_signal <= '1';
        wait for BTN_LENGTH;
        btn3_signal <= '0';
        wait for SIM_DURATION;
    end process;

--    btn1 : process
--    begin
--        btn1_signal <= '0';
--        wait for BTN_1; 
--        btn1_signal <= '1';
--        wait for BTN_LENGTH;
--        btn1_signal <= '0';
--        wait for SIM_DURATION;
--    end process;
--    btn2 : process
--    begin
--        btn2_signal <= '0';
--        wait for BTN_2; 
--        btn2_signal <= '1';
--        wait for BTN_LENGTH;
--        btn2_signal <= '0';
--        wait for SIM_DURATION;
--    end process;
--    btn3 : process
--    begin
--        btn3_signal <= '0';
--        wait for BTN_3; 
--        btn3_signal <= '1';
--        wait for BTN_LENGTH;
--        btn3_signal <= '0';
--        wait for SIM_DURATION;
--    end process;

    -- Data generator

    -- ADC simulator
    ADC_simulator : entity concept.ADC_simulator
        port map(
            clk     => sys_clk,
            nrst    => sys_rst,
            nCNV    => ADC_CNV_signal,
            SCK     => ADC_SCK_signal,
            SDO     => ADC_SDO_signal,
            data    => simulation_data
        );
        
    -- test_ADC module

    test_ADC_module : entity concept.test_ADC
        port map(
            sys_clk         => sys_clk,
            sys_rst         => sys_rst,
            -- Enabling
            DAC_enabled     => DAC_enabled,
            ADC_enabled     => ADC_enabled,
            --buttons
            btn0            => btn0_signal,
            btn1            => btn1_signal,
            btn2            => btn2_signal,
            btn3            => btn3_signal,
            -- DAC control
            DAC_SDI_IO28    => open,
            DAC_LD_IO13     => open,
            DAC_CS_IO26     => open,
            DAC_CK_IO27     => open,
            -- ADC control
            ADC_CNV_IO0     => ADC_CNV_signal,
            ADC_SCK_IO1     => ADC_SCK_signal,
            ADC_SDO_IO2     => ADC_SDO_signal
        );

end Behavioral;
