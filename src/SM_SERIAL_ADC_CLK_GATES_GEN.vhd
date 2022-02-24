--	Filename:		SM_IOEXP_CTRL_Clk_GATES_GEN.vhd
--	Author:			I.Ibanez
--	Company:		NASA Goddard Space Flight Center
--	Date:			05/02/2020
--	Description:	Generation of the serial lines for controlling the ADC LTC2325-16
--	Sintax:			VHDL 2008
--
--	    ***********      ***********     ******  
--	        **               **         **	   * 
--	       **		        **	       **     ** 
--	      **               **         **     **
--	     **   	          **         **     **
--	***********  *	 *********  *   ****** *  
--
--	e-mail : iban.ibanezdomenech@nasa.gov
--                                                                                      
-- -------------------------------------------------------------------------------------
--	Reference :
--
-- ------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY SM_SERIAL_ADC_CLK_GATES_GEN IS
	PORT(	Clock					: IN std_logic; -- 100 MHz
			Reset					: IN std_logic;
			CNV					    : OUT std_logic;
			SERIAL_CLK			    : OUT std_logic;
			START_CONV_PULSE	    : IN std_logic
			);
END SM_SERIAL_ADC_CLK_GATES_GEN;


ARCHITECTURE behave OF SM_SERIAL_ADC_CLK_GATES_GEN IS

	
	SIGNAL SERIAL_CLK_reg : std_logic;
	SIGNAL CNV_reg : std_logic;
	SIGNAL CNV_counter : unsigned(4 downto 0); -- 
	SIGNAL START_CONV_PULSE_reg : std_logic;
	SIGNAL START_CONV_PULSE_reg_ff: std_logic;
	
	attribute mark_debug : string;
	
	attribute mark_debug of CNV_counter 		 : signal is "true";
	attribute mark_debug of START_CONV_PULSE_reg_ff 		: signal is "true";
	attribute mark_debug of SERIAL_CLK_reg 		: signal is "true";
	
	
BEGIN

SERIAL_CLK <= SERIAL_CLK_reg;
CNV <= CNV_reg;
START_CONV_PULSE_reg <= START_CONV_PULSE;

serial_clk_gates_gen: PROCESS (Clock, Reset)
-- Clocked state transitions
BEGIN
	if Reset = '1' then
		CNV_reg <= '0';
		SERIAL_CLK_reg <= '0';
		CNV_counter <= (others => '0');
		START_CONV_PULSE_reg_ff <= '0';
		
	elsif (rising_edge(Clock)) then
	--------------------------------------------------------
	-- SERIAL CLOCK and CNV signal GENERATION FOR ADC
	--------------------------------------------------------
		-- General Clock @ 100 MHz FPGA clock. SERIAL CLOCK FREQUENCY = 50 MHz and CNV
		

		if START_CONV_PULSE_reg = '1' then
			START_CONV_PULSE_reg_ff <= '1';
		end if;
		
		if ((START_CONV_PULSE_reg_ff = '1')  or  (CNV_counter = 1) or  (CNV_counter = 2)) then
			CNV_reg <= '1';
			START_CONV_PULSE_reg_ff <= '0';
			CNV_counter <= CNV_counter + 1;
		else
		    CNV_reg <= '0';
		end if;
		
		if CNV_counter > 0 then
		  CNV_counter <= CNV_counter + 1;
		end if;
		
		if ((CNV_counter > 3)  and  (CNV_counter < 20)) then
			SERIAL_CLK_reg <= not SERIAL_CLK_reg;
		end if;
		
	   if (CNV_counter = 19) then
			CNV_counter <= (others => '0');
		end if;

	end if;

END PROCESS serial_clk_gates_gen;

END behave;
