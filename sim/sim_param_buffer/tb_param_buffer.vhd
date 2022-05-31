----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/31/2022
-- Module Name: tb_param_buffer.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the param_buffer module
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

entity tb_param_buffer is
end tb_param_buffer;

architecture behave of tb_param_buffer is

    -- Constants
    constant T_HALF_CLK         : time := 100 ns; -- 5MHz clock
    constant RST_START          : time := 300 ns;
    constant RST_PULSE_LENGTH   : time := 400 ns;
    constant UPDATE_DLY         : time := 3 us;
    constant SIM_DURATION       : time := 100 ms;

    -- Clock
    signal sys_clk  : std_logic;
    signal sys_rst  : std_logic;

    -- Generics for the module
    signal address : natural := RET_DATA_S_ADDR;
    signal param_size : natural := PARAM_ID_TO_SIZE(RET_DATA_S_ADDR);

    -- Signals for the module
    signal update           : std_logic := '0';
    signal update_address   : natural := 0;
    signal update_data      : t_packet_payload := (others => (others => '0'));
    signal param_data       : t_param_array(0 to param_size - 1) := (others => (others => '0'));


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

    update_gen : process
    begin
        wait for RST_START + RST_PULSE_LENGTH + 300 ns;
        -- #1 -> Wrong address
        update <= '1';
        update_address <= ROW_LEN_ADDR;
        update_data <= (0 => x"F0F0F000",
                        1 => x"F0F0F001",
                        others => (others => '0'));
        wait for 2 * T_HALF_CLK;
        update <= '0';
        wait for UPDATE_DLY;

        -- #2 -> good
        update <= '1';
        update_address <= RET_DATA_S_ADDR;
        update_data <= (0 => x"F0F0F000",
                        1 => x"F0F0F001",
                        2 => x"F0F0F002",
                        others => (others => '0'));
        wait for 2 * T_HALF_CLK;
        update <= '0';
        wait for UPDATE_DLY;
    end process;

    -- Module
    param_buffer_module : entity concept.param_buffer
        generic map(
            address         => RET_DATA_S_ADDR,
            param_size      => PARAM_ID_TO_SIZE(RET_DATA_S_ADDR)
        )
        port map(
            clk             => sys_clk,
            rst             => sys_rst,

            update          => update,
            update_address  => update_address,
            update_data     => update_data,
            param_data      => param_data
        );

end behave;

