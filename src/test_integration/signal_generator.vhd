----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.15.2022
-- Module Name: signal_generator.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of generating a triangular function contaminated with a high frequency 
--              triangular function following the parameters given

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

entity signal_generator is
    generic(
        NUM_CYCLES_WIDTH        : natural; -- := 8
        CYCLES_MULTPLR_WIDTH    : natural; -- := 8
        K_GAIN_WIDTH            : natural; -- := 16
        DATA_WIDTH              : natural; -- output data width (16 bit DAC)
        M                       : natural -- Number of samples to go from 0 to 1 = 2^M
    );
    port(
        clk                 : in std_logic; -- 5MHz clk
        rst                 : in std_logic; -- async reset

        enable_slow         : in std_logic; -- We only trigger if enable is active high
        enable_fast         : in std_logic; -- We only trigger if enable is active high
        n_cycles            : in unsigned(NUM_CYCLES_WIDTH - 1 downto 0); -- Num clk cycles for each sample of the slow signal. Defines freq of slow signal
        cycles_multplr      : in unsigned(CYCLES_MULTPLR_WIDTH - 1 downto 0); -- Num_cycles_fast = n_cycles * cycles_multplr. Defines freq of fast signal

        k_gain              : in unsigned(K_GAIN_WIDTH - 1 downto 0); -- Gain of the signal. We consider we have an initial signal from 0 to 1. we multiply by 2^K
        offset              : in unsigned(DATA_WIDTH - 1 downto 0); -- Offset applied to the amplified signal

        data                : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- Output data to be sent to the DAC
        data_valid          : out std_logic -- Pulse indicating that the signal is valid
    );

end signal_generator;

architecture behave of signal_generator is

    signal n_cycles_slow   : unsigned(NUM_CYCLES_WIDTH + CYCLES_MULTPLR_WIDTH - 1 downto 0) := (others => '0');
    signal new_sample_slow : std_logic := '0';
    signal new_sample_fast : std_logic := '0';
    signal signal_slow     : unsigned(M - 1 downto 0) := (others => '0');
    signal signal_fast     : unsigned(M - 1 downto 0) := (others => '0');
    signal slow_valid      : std_logic := '0';
    signal fast_valid      : std_logic := '0';
    signal signals_valid   : std_logic := '0';

begin
    
    n_cycles_slow <= n_cycles * cycles_multplr;
    signals_valid <= slow_valid or fast_valid;

    generator_triggerer_slow : entity concept.samples_triggerer
        generic map(
            NUM_CYCLES_WIDTH => NUM_CYCLES_WIDTH + CYCLES_MULTPLR_WIDTH
        )
        port map(
            clk                 => clk,
            rst                 => rst,

            enable              => enable_slow,
            num_cycles          => n_cycles_slow,

            new_sample          => new_sample_slow
        );

    triangular_samples_generator_slow : entity concept.triangular_samples_generator
        generic map(
            M => M
        )
        port map(
            clk                 => clk,
            rst                 => rst,

            next_sample         => new_sample_slow,

            data                => signal_slow,
            data_valid          => slow_valid
        );

    generator_triggerer_fast : entity concept.samples_triggerer
        generic map(
            NUM_CYCLES_WIDTH => NUM_CYCLES_WIDTH
        )
        port map(
            clk                 => clk,
            rst                 => rst,

            enable              => enable_fast,
            num_cycles          => n_cycles,

            new_sample          => new_sample_fast
        );

    triangular_samples_generator_fast : entity concept.triangular_samples_generator
        generic map(
            M => M
        )
        port map(
            clk                 => clk,
            rst                 => rst,

            next_sample         => new_sample_fast,

            data                => signal_fast,
            data_valid          => fast_valid
        );

    signal_adder : entity concept.signal_adder
    generic map(
        K_GAIN_WIDTH    => K_GAIN_WIDTH,
        DATA_WIDTH      => DATA_WIDTH,
        M               => M
    )
    port map(
        clk                 => clk,
        rst                 => rst,

        signal_0            => signal_slow,
        signal_1            => signal_fast,
        signals_valid       => signals_valid,

        k_gain              => k_gain,
        offset              => offset,

        data                => data,
        data_valid          => data_valid
    );

end behave;