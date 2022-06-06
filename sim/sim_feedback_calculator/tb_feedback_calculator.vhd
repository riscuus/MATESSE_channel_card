----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05/31/2022
-- Module Name: tb_feedback_calculator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the feedback_calculator module
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

entity tb_feedback_calculator is
end tb_feedback_calculator;

architecture Behavioral of tb_feedback_calculator is

    -- Constants
    constant T_HALF_CLK_100     : time := 5 ns; -- 100 MHz clk
    constant T_HALF_CLK_5       : time := 100 ns; -- 5 MHz clk
    constant RST_START          : time := 32 ns;
    constant RST_PULSE_LENGTH   : time := 300 ns;
    constant FIVE_MHZ_PERIOD    : time := 200 ns;
    constant NEW_ROW_DLY        : time := 20 * FIVE_MHZ_PERIOD;
    constant SIM_DURATION       : time := 200 ms;

    -- Clock
    signal sys_clk_5    : std_logic;
    signal sys_clk_100  : std_logic;
    signal sys_rst      : std_logic;

    -- Sample selector signals
    signal sample_dly       : natural := 3;
    signal sample_num       : natural := 5;
    signal new_row          : std_logic := '0';
    signal valid_word       : std_logic := '0';
    signal parallel_data    : t_adc_sample := (others => '0');

    -- Sample_accumulator signals
    signal row_num          : natural := 0;

    -- sample_selector -> sample_accumulator
    signal valid_sample     : std_logic := '0';
    signal sample_data      : t_adc_sample := (others => '0');

    -- pulse stretcher
    signal acc_sample_valid     : std_logic := '0';
    signal acc_sample_valid_str : std_logic := '0';

    -- sample_accumulator -> feedback_calculator
    signal acc_sample       : t_word := (others => '0');
    signal acc_sample_row   : natural := 0;
    signal sa_fb_gain       : natural := 10;


begin

    -- 100 CLK generation
    clk_generation_100 : process 
    begin
        sys_clk_100 <= '1';
        wait for T_HALF_CLK_100; 
        sys_clk_100 <= '0';
        wait for T_HALF_CLK_100;
    end process;

    -- 5 CLK generation
    clk_generation_5 : process 
    begin
        sys_clk_5 <= '1';
        wait for T_HALF_CLK_5; 
        sys_clk_5 <= '0';
        wait for T_HALF_CLK_5;
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

    -- new_row generation
    new_row_gen : process
    begin
        new_row <= '1';
        wait for FIVE_MHZ_PERIOD;
        new_row <= '0';
        wait for NEW_ROW_DLY;
    end process;

    -- row_num generation
    row_num_gen : process
    begin
        wait for 12 * FIVE_MHZ_PERIOD;
        row_num <= row_num + 1;
    end process;

    -- Test cases generation
    words_generation : process
    begin
        wait for RST_START + RST_PULSE_LENGTH + 120 ns;
        -- Sample #1
        valid_word <= '1';
        parallel_data <= x"0001";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #2
        valid_word <= '1';
        parallel_data <= x"0002";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #3
        valid_word <= '1';
        parallel_data <= x"0003";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #4
        valid_word <= '1';
        parallel_data <= x"0004";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #5
        valid_word <= '1';
        parallel_data <= x"0005";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #6
        valid_word <= '1';
        parallel_data <= x"0006";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #7
        valid_word <= '1';
        parallel_data <= x"0007";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #8
        valid_word <= '1';
        parallel_data <= x"0008";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #9
        valid_word <= '1';
        parallel_data <= x"0009";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
        -- Sample #10
        valid_word <= '1';
        parallel_data <= x"0010";
        wait for 2 * T_HALF_CLK_100;
        valid_word <= '0';
        wait for FIVE_MHZ_PERIOD - 2 * T_HALF_CLK_100;
    end process;

    -- Sample selector module, we include it to test sample_accumulator
    sample_selector_module : entity concept.sample_selector
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            sample_dly      => sample_dly,
            sample_num      => sample_num,
            new_row         => new_row,
            valid_word      => valid_word,
            parallel_data   => parallel_data,
            valid_sample    => valid_sample,
            sample_data     => sample_data
        );

    -- Module
    sample_accumulator_module : entity concept.sample_accumulator
        port map(
            clk                 => sys_clk_100,
            rst                 => sys_rst,

            sample_num          => sample_num,
            valid_sample        => valid_sample,
            sample              => sample_data,
            row_num             => row_num,
            acc_sample          => acc_sample,
            acc_sample_valid    => acc_sample_valid,
            acc_sample_row      => acc_sample_row
        );
    
    pulse_stretcher : entity concept.pulse_stretcher
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            fast_pulse      => acc_sample_valid,
            stretched_pulse => acc_sample_valid_str
        );


    -- Module
    feedback_calculator_module : entity concept.feedback_calculator
        port map(
            clk                 => sys_clk_5,
            rst                 => sys_rst,

            acc_sample          => acc_sample,
            acc_sample_valid    => acc_sample_valid_str,
            acc_sample_row      => acc_sample_row,
            sa_fb_gain          => sa_fb_gain,
            write_row_num       => open,
            write_en            => open,
            calc_fb             => open
        );

end Behavioral;
