----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.08.2022
-- Module Name: biquad.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is the wrapper around the biquad_core to connect the ram modules.

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

entity biquad is
    generic(
        COEFF_WIDTH     : natural; -- := 15;
        TRUNC_WIDTH     : natural; -- := 5;
        ROW_WIDTH       : natural; -- := 4;
        RAM_DATA_WIDTH  : natural; -- := 32; (This also defines the data_width of the input and output data of the filter)
        RAM_BRAM_SIZE   : string;  -- := 18kb
        RAM_READ_DEPTH  : natural; -- := 512
        RAM_ADDR_WIDTH  : natural; -- := 9
        RAM_WRITE_MODE  : string; -- := READ_FIRST
        RAM_WE_WIDTH    : natural  -- := 4
    );
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;

        b1                  : in signed(COEFF_WIDTH - 1 downto 0);
        b2                  : in signed(COEFF_WIDTH - 1 downto 0);
        k                   : in unsigned(TRUNC_WIDTH - 1 downto 0);
        x                   : in signed(RAM_DATA_WIDTH - 1 downto 0);
        x_row               : in unsigned(ROW_WIDTH - 1 downto 0);
        x_valid             : in std_logic;

        y                   : out signed(RAM_DATA_WIDTH - 1 downto 0);
        y_row               : out unsigned(ROW_WIDTH - 1 downto 0);
        y_valid             : out std_logic
    );

end biquad;

architecture behave of biquad is

    signal ram_0_write_data    : std_logic_vector(RAM_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ram_0_read_data     : std_logic_vector(RAM_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ram_1_write_data    : std_logic_vector(RAM_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ram_1_read_data     : std_logic_vector(RAM_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ram_write_en        : std_logic := '0';
    signal ram_write_addr      : unsigned(RAM_ADDR_WIDTH  - 1 downto 0) := (others => '0');

begin

    biquad_core_module : entity concept.biquad_core
        generic map(
            COEFF_WIDTH     => COEFF_WIDTH,
            TRUNC_WIDTH     => TRUNC_WIDTH,
            DATA_WIDTH      => RAM_DATA_WIDTH,
            ROW_WIDTH       => ROW_WIDTH,
            RAM_ADDR_WIDTH  => RAM_ADDR_WIDTH
        )
        port map(               
            clk                 => clk,
            rst                 => rst,
                                   
            b1                  => b1,
            b2                  => b2,
            k                   => k,
            x                   => x,
            x_row               => x_row,
            x_valid             => x_valid,

            ram_0_write_data    => ram_0_write_data,
            ram_0_read_data     => ram_0_read_data,
            ram_1_write_data    => ram_1_write_data,
            ram_1_read_data     => ram_1_read_data,
            ram_write_en        => ram_write_en,
            ram_write_addr      => ram_write_addr,

            y                   => y,
            y_row               => y_row,
            y_valid             => y_valid
        );

    BRAM_single_wrapper_module_0 : entity concept.BRAM_single_wrapper
        generic map(
            DATA_WIDTH   =>  RAM_DATA_WIDTH,
            BRAM_SIZE    =>  RAM_BRAM_SIZE,
            READ_DEPTH   =>  RAM_READ_DEPTH,
            ADDR_WIDTH   =>  RAM_ADDR_WIDTH,
            WRITE_MODE   =>  RAM_WRITE_MODE,
            WE_WIDTH     =>  RAM_WE_WIDTH
        )                     
        port map(
            clk                     => clk, 
            rst                     => rst,

            address                 => ram_write_addr,
            write_data              => ram_0_write_data,
            write_pulse             => ram_write_en,
            read_data               => ram_0_read_data
        );

    BRAM_single_wrapper_module_1 : entity concept.BRAM_single_wrapper
        generic map(
            DATA_WIDTH   => WORD_WIDTH, -- (32)  1 <-> 72
            BRAM_SIZE    => "18Kb", -- ("18Kb")  "18Kb" or "36Kb"
            READ_DEPTH   => 512,-- (512)  512, 1024, 2048, 4096, 8192, 16384, 32768
            ADDR_WIDTH   => 9, -- (9)  9 <-> 15
            WRITE_MODE   => "READ_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
            WE_WIDTH     => 4 -- (4)  1, 2, 4, 8
        )
        port map(
            clk                     => clk, 
            rst                     => rst,

            address                 => ram_write_addr,
            write_data              => ram_1_write_data,
            write_pulse             => ram_write_en,
            read_data               => ram_1_read_data
        );

end behave;