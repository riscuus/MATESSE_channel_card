----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07/19/2022
-- Module Name: tb_clocked_ddr_input.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Testbench to test the clocjed ddr input module
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

entity tb_clocked_ddr_input is
end tb_clocked_ddr_input;

architecture behave of tb_clocked_ddr_input is

    signal sys_rst      : std_logic := '0'; 
    signal sys_clk_100  : std_logic := '0';
    signal sys_clk_200  : std_logic := '0';

    -- ADC signals
    signal ADC_SCK_signal : std_logic := '0';
    signal ADC_SDO_signal : std_logic := '0';
    signal ADC_CNV_signal : std_logic := '0';

    signal ADC_start_pulse : std_logic := '0';
    
    -- ddr signals
    signal parallel_ddr         : std_logic_vector(1 downto 0) := (others => '0');
    signal ddr_valid            : std_logic := '0';
    signal ddr_valid_stretched  : std_logic := '0';

begin

    rst_gen : process
    begin
        sys_rst <= '0';
        wait for 200 ps;
        sys_rst <= '1';
        wait for 37 ns;
        sys_rst <= '0';
        wait;
    end process;

    clk_200_gen : process
    begin
        sys_clk_200 <= '0';
        wait for 2500 ps;
        sys_clk_200 <= '1';
        wait for 2500 ps;
    end process;

    clk_100_gen : process
    begin
        sys_clk_100 <= '0';
        wait for 5 ns;
        sys_clk_100 <= '1';
        wait for 5 ns;
    end process;

    start_pulse_gen : process
    begin
        ADC_start_pulse <= '1';
        wait for 10 ns;
        ADC_start_pulse <= '0';
        wait for 190 ns;
    end process;


    ADC_gate_controller : entity concept.ADC_gate_controller
        generic map(
            NUM_OF_SCK_CYCLES => ADC_DATA_SIZE / 2
        )
        port map(
            clk             => sys_clk_100,
            rst             => sys_rst,

            cnv_len         => to_unsigned(2, ADC_PARAMS_WIDTH),
            sck_dly         => to_unsigned(2, ADC_PARAMS_WIDTH),
            sck_half_period => to_unsigned(1, ADC_PARAMS_WIDTH),

            start_pulse     => ADC_start_pulse,

            CNV             => ADC_CNV_signal,
            SCK             => ADC_SCK_signal
        );

    ADC_simulator : entity concept.ADC_simulator
       generic map(
            ADC_WORD_LENGTH => 16
       )
       port map( 
           clk     => sys_clk_100,
           rst     => sys_rst,
           nCNV    => ADC_CNV_signal,
           SCK     => ADC_SCK_signal,
           data    => x"1AB3",
           SDO     => ADC_SDO_signal
       );

    clocked_ddr_input : entity concept.clocked_ddr_input
        generic map(
            DLY_CYCLES_WIDTH => 2
        )
        port map( 
            rst             => sys_rst,
            clk             => sys_clk_200,
            dly_cycles      => to_unsigned(1, 2),
            serial_clk      => ADC_SCK_signal,
            serial_in       => ADC_SDO_signal,
            parallel_out    => parallel_ddr,
            parallel_valid  => ddr_valid
        );

    ddr_stretcher : entity concept.pulse_stretcher
        generic map (
            conversion_ratio    => 2,
            stretching_length   => 1
        )
        port map(
            clk             => sys_clk_200,
            rst             => sys_rst,

            fast_pulse      => ddr_valid,
            stretched_pulse => ddr_valid_stretched
        );
    
    input_shift_register : entity concept.input_shift_register
        generic map(
            ADC_WORD_LENGTH => 16,
            DDR_bits        => 2
        )
        port map( 
            clk             => sys_clk_100,
            rst             => sys_rst,
            ddr_parallel    => parallel_ddr,
            ddr_valid       => ddr_valid_stretched,
            ADC_word        => open,
            valid_word      => open
        );

end behave;