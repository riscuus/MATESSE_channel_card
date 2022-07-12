----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.11.2022
-- Module Name: butterworth_filter_cascade.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component acts as the 4 pole butterworth filter implemented as a cascade of two biquads

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

entity butterworth_filter_cascade is
    generic(
        COEFF_WIDTH     : natural; -- := 15;
        TRUNC_WIDTH     : natural; -- := 5;
        ROW_WIDTH       : natural; -- := 4;
        RAM_DATA_WIDTH  : natural; -- := 32; (This also defines the data_width of the input and output data of the filter)
        RAM_BRAM_SIZE   : string;  -- := 18kb
        RAM_READ_DEPTH  : natural; -- := 512
        RAM_ADDR_WIDTH  : natural; -- := 9
        RAM_WRITE_MODE  : string;  -- := READ_FIRST
        RAM_WE_WIDTH    : natural  -- := 4
    );
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;

        filtr_coeff        : in t_param_array(0 to PARAM_ID_TO_SIZE(FILTR_COEFF_ID) - 1);
        x                   : in signed(RAM_DATA_WIDTH - 1 downto 0);
        x_row               : in unsigned(ROW_WIDTH - 1 downto 0);
        x_valid             : in std_logic;

        y                   : out signed(RAM_DATA_WIDTH - 1 downto 0);
        y_row               : out unsigned(ROW_WIDTH - 1 downto 0);
        y_valid             : out std_logic
    );

end butterworth_filter_cascade;

architecture behave of butterworth_filter_cascade is

    signal b11  : signed(COEFF_WIDTH - 1 downto 0) := (others => '0');
    signal b12  : signed(COEFF_WIDTH - 1 downto 0) := (others => '0');
    signal b21  : signed(COEFF_WIDTH - 1 downto 0) := (others => '0');
    signal b22  : signed(COEFF_WIDTH - 1 downto 0) := (others => '0');
    signal k1   : unsigned(TRUNC_WIDTH - 1 downto 0) := (others => '0');
    signal k2   : unsigned(TRUNC_WIDTH - 1 downto 0) := (others => '0');

    signal y_inter          : signed(RAM_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal y_row_inter      : unsigned(ROW_WIDTH - 1 downto 0) := (others => '0');
    signal y_valid_inter    : std_logic := '0';
begin

    b11 <=   signed(filtr_coeff(0)(COEFF_WIDTH - 1 downto 0));
    b12 <=   signed(filtr_coeff(1)(COEFF_WIDTH - 1 downto 0));
    b21 <=   signed(filtr_coeff(2)(COEFF_WIDTH - 1 downto 0));
    b22 <=   signed(filtr_coeff(3)(COEFF_WIDTH - 1 downto 0));
    k1  <= unsigned(filtr_coeff(4)(TRUNC_WIDTH - 1 downto 0));
    k2  <= unsigned(filtr_coeff(5)(TRUNC_WIDTH - 1 downto 0));


    biquad_0 : entity concept.biquad
    generic map(
        COEFF_WIDTH    => COEFF_WIDTH,
        TRUNC_WIDTH    => TRUNC_WIDTH,
        ROW_WIDTH      => ROW_WIDTH,
        RAM_DATA_WIDTH => RAM_DATA_WIDTH,
        RAM_BRAM_SIZE  => RAM_BRAM_SIZE,
        RAM_READ_DEPTH => RAM_READ_DEPTH,
        RAM_ADDR_WIDTH => RAM_ADDR_WIDTH,
        RAM_WRITE_MODE => RAM_WRITE_MODE,
        RAM_WE_WIDTH   => RAM_WE_WIDTH
    )
    port map(
        clk                 => clk,
        rst                 => rst,

        b1                  => b11,
        b2                  => b12,
        k                   => k1,
        x                   => x,
        x_row               => x_row,
        x_valid             => x_valid,

        y                   => y_inter,
        y_row               => y_row_inter,
        y_valid             => y_valid_inter
    );

    biquad_1 : entity concept.biquad
    generic map(
        COEFF_WIDTH    => COEFF_WIDTH,
        TRUNC_WIDTH    => TRUNC_WIDTH,
        ROW_WIDTH      => ROW_WIDTH,
        RAM_DATA_WIDTH => RAM_DATA_WIDTH,
        RAM_BRAM_SIZE  => RAM_BRAM_SIZE,
        RAM_READ_DEPTH => RAM_READ_DEPTH,
        RAM_ADDR_WIDTH => RAM_ADDR_WIDTH,
        RAM_WRITE_MODE => RAM_WRITE_MODE,
        RAM_WE_WIDTH   => RAM_WE_WIDTH
    )
    port map(
        clk                 => clk,
        rst                 => rst,

        b1                  => b21,
        b2                  => b22,
        k                   => k2,
        x                   => y_inter,
        x_row               => y_row_inter,
        x_valid             => y_valid_inter,

        y                   => y,
        y_row               => y_row,
        y_valid             => y_valid
    );

end behave;