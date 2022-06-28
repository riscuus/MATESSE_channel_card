----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.06.2022
-- Module Name: BRAM_dual_wrapper.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component wraps a BRAM_DUAL_MACRO instance. Working in WRITE_FIRST mode, means that when changing
--              the address, in the next clock the output_data already is valid. The same for writing

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

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use     UNIMACRO.vcomponents.all;

library concept;
use concept.utils.all;

entity BRAM_dual_wrapper is
    -- Not all generic combinations are possible, look at the table in Xilinx HDL Libraries Guide
    generic(
        DATA_WIDTH : natural;   -- (32)  1 <-> 72
        BRAM_SIZE : string;     -- ("18Kb")  "18Kb" or "36Kb"
        READ_DEPTH : natural;   -- (512)  512, 1024, 2048, 4096, 8192, 16384, 32768
        ADDR_WIDTH : natural;   -- (9)  9 <-> 15
        WE_WIDTH : natural      -- (4)  1, 2, 4, 8
    );
    port(
        clk                     : in std_logic; -- 5MHz clock                                                                           
        rst                     : in std_logic; -- Asynchronous reset

        write_address           : in unsigned(ADDR_WIDTH - 1 downto 0);   -- The address to write data
        write_data              : in std_logic_vector(DATA_WIDTH - 1 downto 0);    -- The data to be written
        write_pulse             : in std_logic; -- The write data enable pulse
        read_address            : in unsigned(ADDR_WIDTH - 1 downto 0);   -- The address to read data
        read_data               : out std_logic_vector(DATA_WIDTH - 1 downto 0)    -- The data read
    );

end BRAM_dual_wrapper;

architecture behave of BRAM_dual_wrapper is

signal write_address_vector : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');
signal write_en_vector      : std_logic_vector(WE_WIDTH - 1 downto 0) := (others => '0');
signal read_address_vector  : std_logic_vector(ADDR_WIDTH - 1 downto 0) := (others => '0');

begin

    write_address_vector    <= std_logic_vector(write_address);
    read_address_vector     <= std_logic_vector(read_address);
    write_en_vector         <= (others => write_pulse);
    
-- BRAM_SDP_MACRO: Simple Dual Port RAM
-- 7 Series
-- Xilinx HDL Libraries Guide, version 14.7
-- Note - This Unimacro model assumes the port directions to be "downto".
-- Simulation of this model with "to" in the port directions could lead to erroneous results.
----------------------------------------------------------------------------
-- READ_WIDTH   | BRAM_SIZE | READ Depth    | RDADDR Width  |             --
-- WRITE_WIDTH  |           | WRITE Depth   | WRADDR Width  | WE Width    --
-- ============ |===========|=============  |============== |============ --
-- 37-72        | "36Kb"    | 512           | 9-bit         | 8-bit       --
-- 19-36        | "36Kb"    | 1024          | 10-bit        | 4-bit       --
----------------------------------------------------------------------------
-- 19-36        | "18Kb"    | 512           | 9-bit         | 4-bit       --   <--
----------------------------------------------------------------------------
-- 10-18        | "36Kb"    | 2048          | 11-bit        | 2-bit       --
-- 10-18        | "18Kb"    | 1024          | 10-bit        | 2-bit       --
-- 5-9          | "36Kb"    | 4096          | 12-bit        | 1-bit       --
-- 5-9          | "18Kb"    | 2048          | 11-bit        | 1-bit       --
-- 3-4          | "36Kb"    | 8192          | 13-bit        | 1-bit       --
-- 3-4          | "18Kb"    | 4096          | 12-bit        | 1-bit       --
-- 2            | "36Kb"    | 16384         | 14-bit        | 1-bit       --
-- 2            | "18Kb"    | 8192          | 13-bit        | 1-bit       --
-- 1            | "36Kb"    | 32768         | 15-bit        | 1-bit       --
-- 1            | "18Kb"    | 16384         | 14-bit        | 1-bit       --
----------------------------------------------------------------------------

BRAM_SDP_MACRO_inst : BRAM_SDP_MACRO
    generic map (
        BRAM_SIZE => BRAM_SIZE,            -- Target BRAM, "18Kb" or "36Kb"
        DEVICE => "7SERIES",            -- Target device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6"
        DO_REG => 0,                    -- Optional output register (0 or 1)
        WRITE_WIDTH => DATA_WIDTH,   -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
        READ_WIDTH => DATA_WIDTH,    -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
        INIT_FILE => "NONE",
        SIM_COLLISION_CHECK => "ALL",   -- Collision check enable "ALL", "WARNING_ONLY",
                                        -- "GENERATE_X_ONLY" or "NONE"
        WRITE_MODE => "WRITE_FIRST"    -- Specify "READ_FIRST" for same clock or synchronous clocks
                                        -- Specify "WRITE_FIRST for asynchrononous clocks on ports
    )
    port map (
        DO => read_data,                -- Output read data port, width defined by READ_WIDTH parameter
        DI => write_data,               -- Input write data port, width defined by WRITE_WIDTH parameter
        RDADDR => read_address_vector,  -- Input read address, width defined by read port depth
        RDCLK => clk,                   -- 1-bit input read clock
        RDEN => '1',                    -- 1-bit input read port enable
        REGCE => '0',                   -- 1-bit input read output register enable
        RST => rst,                     -- 1-bit input reset
        WE => write_en_vector,          -- Input write enable, width defined by write port depth
        WRADDR => write_address_vector, -- Input write address, width defined by write port depth
        WRCLK => clk,                   -- 1-bit input write clock
        WREN => '1'                     -- 1-bit input write port enable
    );

end behave;
