----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.18.2022
-- Module Name: BRAM_single_wrapper.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component wraps a BRAM_SINGLE_MACRO instance. Working in WRITE_FIRST mode, mean that when changing
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

library concept;
use concept.utils.all;

entity BRAM_single_wrapper is
    port(
        clk                     : in std_logic; -- 5MHz clock                                                                           
        rst                     : in std_logic; -- Asynchronous reset

        address                 : in t_param_id_address;
        write_data              : in t_word;
        write_pulse             : in std_logic;
        read_data               : out t_word
    );

end BRAM_single_wrapper;

architecture behave of BRAM_single_wrapper is
    signal address_expande
begin
    -- BRAM_SINGLE_MACRO: Single Port RAM
    -- 7 Series
    -- Xilinx HDL Libraries Guide, version 2012.2
    -- Note - This Unimacro model assumes the port directions to be "downto".
    -- Simulation of this model with "to" in the port directions could lead to erroneous results.
    ---------------------------------------------------------------------
    -- READ_WIDTH  | BRAM_SIZE | READ Depth  | ADDR Width | --
    -- WRITE_WIDTH |           | WRITE Depth |            | WE Width --
    -- ============|===========|=============|============|============--
    -- 37-72       | "36Kb"    | 512         | 9-bit      | 8-bit --
    -- 19-36       | "36Kb"    | 1024        | 10-bit     | 4-bit --
    -----------------------------------------------------------------
    -- 19-36 (32)  | "18Kb"    | 512         | 9-bit      | 4-bit --
    -----------------------------------------------------------------
    -- 10-18       | "36Kb"    | 2048        | 11-bit     | 2-bit --
    -- 10-18       | "18Kb"    | 1024        | 10-bit     | 2-bit --
    -- 5-9         | "36Kb"    | 4096        | 12-bit     | 1-bit --
    -- 5-9         | "18Kb"    | 2048        | 11-bit     | 1-bit --
    -- 3-4         | "36Kb"    | 8192        | 13-bit     | 1-bit --
    -- 3-4         | "18Kb"    | 4096        | 12-bit     | 1-bit --
    -- 2           | "36Kb"    | 16384       | 14-bit     | 1-bit --
    -- 2           | "18Kb"    | 8192        | 13-bit     | 1-bit --
    -- 1           | "36Kb"    | 32768       | 15-bit     | 1-bit --
    -- 1           | "18Kb"    | 16384       | 14-bit     | 1-bit --
    ---------------------------------------------------------------------
    BRAM_SINGLE_MACRO_inst : BRAM_SINGLE_MACRO
    generic map (

        BRAM_SIZE => "18Kb",                                -- Target BRAM, "18Kb" or "36Kb"
        DEVICE => "7SERIES",                                -- Target Device: "VIRTEX5", "7SERIES", "VIRTEX6, "SPARTAN6"
        DO_REG => 0,                                        -- Optional output register (0 or 1)
        INIT => X"000000000",                               -- Initial values on output port
        INIT_FILE => "NONE",
        WRITE_WIDTH => t_word'length,                       -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
        READ_WIDTH => t_word'length,                        -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
        SRVAL => X"000000000",                              -- Set/Reset value for port output
        WRITE_MODE => "WRITE_FIRST",                        -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE"
    )
    port map (
        DO => output_data,                                  -- Output data, width defined by READ_WIDTH parameter
        ADDR => std_logic_vector(to_unsigned(address, 9)),  -- Input address, width defined by read/write port depth
        CLK => clk,                                         -- 1-bit input clock
        DI => write_data,                                   -- Input data port, width defined by WRITE_WIDTH parameter
        EN => '1',                                          -- 1-bit input RAM enable
        REGCE => open,                                      -- 1-bit input output register enable
        RST => rst,                                         -- 1-bit input reset
        WE => (others => write_enable)                      -- Input write enable, width defined by write port depth
    );

end behave;
