----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 04/30/2022
-- Module Name: tb_test_uart.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to simulate the test_uart file

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
use concept.utils.all;

entity tb_test_uart is
end tb_test_uart;

architecture Behavioral of tb_test_uart is

    -- Constants
    constant T_HALF_CLK         : time := 5 ns;
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 100 ns;
    constant SIM_DURATION       : time := 200 ms;
    constant SEND_START         : time := 200 ns;

    -- Clock
    signal sys_clk  : std_logic := '0';
    signal sys_rst  : std_logic := '0';

    -- Send signal
    signal send : std_logic := '0';

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


    -- Send generation

    send_generation : process
    begin
        send <= '0';
        wait for SEND_START; 
        send <= '1';
        wait for RST_PULSE_LENGTH;
        send <= '0';
        wait for SIM_DURATION;
    end process;

    -- Test uart module
    test_uart_module : entity concept.test_uart
        port map(
            sys_clk                 => sys_clk,
            sys_rst                 => sys_rst,

            send                => send,
            uart_tx             => open
        );

end Behavioral;