----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 04/23/2020 07:15:51 PM
-- Design Name: 
-- Module Name: Top_TB - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
library concept;
use concept.utils.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity Top_TB is
--	generic (
--		COLUMS_NUM     : positive := 8;
--		ROWS_NUM       : positive := 1
--	);
--	port (
--		Sys_Clock      : in  std_logic;
--		Sys_Reset      : in  std_logic;

--		col_sync       : in  std_logic;

--		-- dummy ports for signals

--		Dummy_Data_in   : in  T_SIGNED_ARRAY(1 to COLUMS_NUM)(15 downto 0);
--		Dummy_Valid_in  : in  std_logic_vector(1 to COLUMS_NUM);

--		Dummy_Data_out  : out T_SIGNED_ARRAY(1 to COLUMS_NUM)(15 downto 0);
--		Dummy_Valid_out : out std_logic_vector(1 to COLUMS_NUM);

--		b_coefficients  : in  T_SIGNED_ARRAY(0 to 3)(15 downto 0);
--		a_coefficients  : in  T_SIGNED_ARRAY(0 to 3)(15 downto 0)

--	);
end Top_TB;

architecture RTL of Top_TB is

signal clk_signal_100mhz			:  	std_logic;
signal rst_signal					:  	std_logic;

constant Tclk_100mhz				: TIME	 := 10 ns;
constant Tclk_halfperiod_100mhz		: TIME	 := 5 ns;
constant COLUMNS_NUM                : POSITIVE := 8;
constant ROWS_NUM                   : POSITIVE := 256;

signal col_sync_signal              : std_logic;
--signal Dummy_Data_in_signal         : T_SIGNED_ARRAY_DATA;
--signal Dummy_Data_out_signal        : T_SIGNED_ARRAY_DATA;
--signal Dummy_Valid_in_signal        : std_logic_vector (COLUMNS_NUM-1 downto 0);
--signal Dummy_Valid_out_signal       : std_logic_vector (COLUMNS_NUM-1 downto 0);
signal b_coefficients_signal        : T_SIGNED_ARRAY_COEFFICIENTS;
signal a_coefficients_signal        : T_SIGNED_ARRAY_COEFFICIENTS;

signal CNV_IO0_signal : std_logic; -- A->D conversion, normally high, pull for 30 ns to start conversion
signal SCK_IO1_signal : std_logic; -- A->D clock, 16 counts for 16 bits
signal SDO_CH_signal : std_logic_vector (1 to 8); -- A->D Data input Channel (Serial data from the external sources, one per col)

signal LD_IO3_signal: std_logic; -- D->A conversion, time critical as it defines the new pixels must match D
signal CS_IO4_signal: std_logic; -- D->A Chip Select. Active Low
signal CK_IO5_signal: std_logic; -- D->A Clock. Active low, 18 pulses for 18 bits		
signal SDI_CH_signal: std_logic_vector (1 to 8); -- D->A Data Output Channel (data input for the DAC)
 
     --- Row Operations --- 
signal LD_IO7_signal: std_logic; -- D->A, time critical as it defines the new pixel must match D 
signal CS_IO8_signal: std_logic; -- D->A, Chip Select active low (chip 1)
signal CS_IO9_signal: std_logic; -- D->A, Chip Select active low (chip 2)
signal CS_IO10_signal: std_logic; -- D->A, Chip Select active low (chip 3)
signal CK_IO11_signal: std_logic; -- D->A Clock. 18 pulses for 18 bits
signal SDI_IO12_signal: std_logic; -- D->A Data

     --- Bias Operations ---
signal LD_IO13: std_logic; -- D->A, time critical as it defines the new pixel
signal CK_IO27: std_logic; -- D->A, Chip Select active low
signal CS_IO26: std_logic; -- D->A Chip Serial Clock for the channel D->A active low
signal SDI_IO28: std_logic; -- D->A Data
        
signal START_CONV_ADC_CH_PULSE_signal  : std_logic;
signal START_CONV_DAC_CH_PULSE_signal  : std_logic;

signal valid_DAC_signal: std_logic;
signal DAC_data_Parallel_signal: std_logic_vector (17 downto 0);

signal sw_signal: std_logic_vector(3 downto 0);
signal LED_signal: std_logic_vector(5 downto 0);

begin

    top_entity : entity concept.top_entity
    generic map(
                COLUMS_NUM  => COLUMNS_NUM,
                ROWS_NUM  => ROWS_NUM
            )
    Port map (
        Sys_Clock => clk_signal_100mhz,
        Sys_Reset_in => rst_signal,
        row_sync  => col_sync_signal,

        -- dummy ports for signals
        
        --b_coefficients  =>  b_coefficients_signal,
        --a_coefficients  =>  a_coefficients_signal,
        
        --- Channel Operations ---
        CNV_IO0 =>   CNV_IO0_signal,
        SCK_IO1 =>   SCK_IO1_signal,
        SDO_CH =>  SDO_CH_signal,
        
        LD_IO3 =>    LD_IO3_signal,
        CS_IO4 =>    CS_IO4_signal,
        CK_IO5 =>	 CK_IO5_signal,
        SDI_CH =>    SDI_CH_signal,
        
        --- Row Operations --- 
        LD_IO7 =>    LD_IO7_signal,
        CS_IO8 =>    CS_IO8_signal,
        CS_IO9 =>    CS_IO9_signal,
        CS_IO10 =>   CS_IO10_signal,
        CK_IO11 =>   CK_IO11_signal,
        SDI_IO12 =>  SDI_IO12_signal,
        
        --- Bias Operations ---
        LD_IO13 =>   LD_IO13,
        CK_IO27 =>   CK_IO27,
        CS_IO26 =>   CS_IO26,
        SDI_IO28 =>  SDI_IO28,
        
        START_CONV_ADC_CH_PULSE => START_CONV_ADC_CH_PULSE_signal,
        START_CONV_DAC_CH_PULSE => START_CONV_DAC_CH_PULSE_signal,
        
        valid_DAC => valid_DAC_signal,
        --DAC_data_Parallel => DAC_data_Parallel_signal,
        
        sw => sw_signal,
        LED => LED_signal
    );
        

    b_coefficients_signal(0)(15 downto 0) <= X"0000";
    b_coefficients_signal(1)(15 downto 0) <= X"0000";
    b_coefficients_signal(2)(15 downto 0) <= X"0000";
    b_coefficients_signal(3)(15 downto 0) <= X"0000";
    a_coefficients_signal(0)(15 downto 0) <= X"0000";
    a_coefficients_signal(1)(15 downto 0) <= X"0000";
    a_coefficients_signal(2)(15 downto 0) <= X"0000";
    a_coefficients_signal(3)(15 downto 0) <= X"0000";

-----------------------------------------------------------------------------------------------------------------------												
-- Col Sync Signal PROCESS ------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------		
-- Row sync !! This shifts each row every 500*10ns = 5us
data_in: PROCESS
BEGIN
    col_sync_signal <= '0';
    wait for Tclk_100mhz*123;
    
    for i in 1 to 10000 loop
        col_sync_signal <= '1';
        wait for Tclk_100mhz;
        col_sync_signal <= '0';
        wait for Tclk_100mhz*499;
    end loop;
    
    wait for 2000 ms;
    
END PROCESS data_in;	

-----------------------------------------------------------------------------------------------------------------------
-- ADC CONVERSION TRIGGER ---------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
ADC_CH_conv_trigger: PROCESS
BEGIN
    START_CONV_ADC_CH_PULSE_signal <= '0';
    wait for 1100 ns;
    
    for i in 0 to 30000 loop
        START_CONV_ADC_CH_PULSE_signal <= '1';
        SDO_CH_signal(1) <= '1';
        wait for 10 ns;

        START_CONV_ADC_CH_PULSE_signal <= '0';
        wait for 390 ns;

    end loop;

END PROCESS ADC_CH_conv_trigger;

DAC_CH_conv_trigger: PROCESS
BEGIN
    START_CONV_DAC_CH_PULSE_signal <= '0';
    valid_DAC_signal <= '0';
    DAC_data_Parallel_signal <= "000000000000000000";
    
    wait for 2000 ns;
    
    for i in 0 to 50 loop
        DAC_data_Parallel_signal <= "000111111111111111";
        wait for 20ns;
        valid_DAC_signal <= '1';
        wait for 20ns;
        START_CONV_DAC_CH_PULSE_signal <= '1';
        wait for 10 ns;
        START_CONV_DAC_CH_PULSE_signal <= '0';
        wait for 3990 ns;
    end loop;

END PROCESS DAC_CH_conv_trigger;

-----------------------------------------------------------------------------------------------------------------------												
-- RESET PROCESS ------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------		
rst: PROCESS
BEGIN
    rst_signal <= '1';
    wait for 1000 ns;
    rst_signal <= '0';
         wait for 50 ms;
         rst_signal <= '1';
         wait for 1000 ns;
         rst_signal <= '0';
    wait for 2000 ms;
    
END PROCESS rst;

-----------------------------------------------------------------------------------------------------------------------												
-- 100 MHZ CLOCK SIMULATION----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------		
clk100mhz : PROCESS
BEGIN
    clk_signal_100mhz <= '1';
    wait for Tclk_halfperiod_100mhz;
    clk_signal_100mhz <= '0';
    wait for Tclk_halfperiod_100mhz;
END PROCESS clk100mhz;


end RTL;
