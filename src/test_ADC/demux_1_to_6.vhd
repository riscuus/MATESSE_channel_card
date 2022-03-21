----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 03.19.2020
-- Module Name: demux_1_to_6.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: Demultiplexer from 1 input to 4 outputs
--
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity demux_1_to_6 is
    port ( 
        sel : in std_logic_vector(2 downto 0);
        a   : in std_logic;
        b1  : out std_logic;
        b2  : out std_logic;
        b3  : out std_logic;
        b4  : out std_logic;
        b5  : out std_logic;
        b6  : out std_logic
    );
end demux_1_to_6;

architecture Behavioral of demux_1_to_6 is
    -- We define these registers to give a default value in case sel is undefined
    signal b1_signal   : std_logic := '0';
    signal b2_signal   : std_logic := '0';
    signal b3_signal   : std_logic := '0';
    signal b4_signal   : std_logic := '0';
    signal b5_signal   : std_logic := '0';
    signal b6_signal   : std_logic := '0';

begin

    b1_signal <= a when (sel = "000") else '0';
    b2_signal <= a when (sel = "001") else '0';
    b3_signal <= a when (sel = "010") else '0';
    b4_signal <= a when (sel = "011") else '0';
    b5_signal <= a when (sel = "100") else '0';
    b6_signal <= a when (sel = "101") else '0';
    
    b1 <= b1_signal;
    b2 <= b2_signal;
    b3 <= b3_signal;
    b4 <= b4_signal;
    b5 <= b5_signal;
    b6 <= b6_signal;

end Behavioral;
