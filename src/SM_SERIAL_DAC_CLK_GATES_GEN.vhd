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

ENTITY SM_SERIAL_DAC_CLK_GATES_GEN IS
	PORT(	Clock					: IN std_logic;
			Reset					: IN std_logic;
			CS					    : OUT std_logic;
			CLK      			    : OUT std_logic;
			LD                      : OUT std_logic;
			START_CONV_PULSE	    : IN std_logic
			);
END SM_SERIAL_DAC_CLK_GATES_GEN;


ARCHITECTURE behave OF SM_SERIAL_DAC_CLK_GATES_GEN IS

	
	SIGNAL CLK_reg : std_logic;
	SIGNAL CS_reg : std_logic;
	SIGNAL CLK_COUNTER : unsigned(4 downto 0); 
	SIGNAL START_CONV_PULSE_reg : std_logic;
	SIGNAL CYCLE_ON_reg : std_logic;
	SIGNAL CS_ON : std_logic;
	SIGNAL LDAC_reg: std_logic;
	SIGNAL BIT_COUNTER: unsigned(5 downto 0);
	SIGNAL GATE_COUNTER: unsigned(1 downto 0);
	SIGNAL GATE_CLK_COUNTING: std_logic;
	
	attribute mark_debug : string;
	
	--attribute mark_debug of CNV_counter 		: signal is "true";
	
	
BEGIN

CLK <= CLK_reg;
CS <= CS_reg;
LD <= LDAC_reg;
START_CONV_PULSE_reg <= START_CONV_PULSE;

serial_clk_gates_gen: PROCESS (Clock, Reset)
-- Clocked state transitions
BEGIN
	if Reset = '1' then
		CS_reg <= '1';
		CLK_reg <= '0';
		CYCLE_ON_reg <= '0';
		CLK_COUNTER <= (others => '0');
		BIT_COUNTER <= (others => '0');
		CS_ON <= '0';
		LDAC_reg <= '1';
		GATE_CLK_COUNTING <= '0';
				
	elsif (rising_edge(Clock)) then
	--------------------------------------------------------
	-- SERIAL CLOCK and CNV signal GENERATION FOR ADC
	--------------------------------------------------------
		-- General Clock @ 50 MHz FPGA clock. SERIAL CLOCK FREQUENCY = 50 MHz and CNV
		
		if START_CONV_PULSE_reg = '1' then
			CYCLE_ON_reg <= '1';
		end if;
		
		if CYCLE_ON_reg = '1' and CS_ON = '0' then
			CS_reg <= '0';
		end if;
		
		if CS_reg = '0' and GATE_CLK_COUNTING = '0' then
		    CS_ON <= '1';
		end if;
		
		if CYCLE_ON_reg = '1' and BIT_COUNTER < 36 then
		  CLK_COUNTER <= CLK_COUNTER + 1; -- 3 clock cycles is 30ns.
		end if;
		
		if CLK_COUNTER = 3 and GATE_CLK_COUNTING = '0' then -- CNV signal to 40ns high. Minimum is 30ns high.
			CLK_reg <= not CLK_reg;
			CLK_COUNTER <= (others => '0');
			BIT_COUNTER <= BIT_COUNTER + 1; 
		end if;		
		
		if (BIT_COUNTER = 36) then
			CYCLE_ON_reg <= '0';
			CS_ON <= '0';
			BIT_COUNTER <= (others => '0');
			GATE_CLK_COUNTING <= '1';
		end if;
		
		if GATE_CLK_COUNTING = '1' then
		    CLK_COUNTER <= CLK_COUNTER + 1;
		    if CLK_COUNTER = 2 then
		      CS_reg <= '1';
		    end if;
		    if CLK_COUNTER = 4 then
		      LDAC_reg <= '0';
		    end if;
		    if CLK_COUNTER = 6 then
		      LDAC_reg <= '1';
		    end if;  
		    if CLK_COUNTER = 10 then
		      GATE_CLK_COUNTING <= '0';
		      CLK_COUNTER <= (others => '0');	      
		    end if;
		end if;
	end if;

END PROCESS serial_clk_gates_gen;

END behave;
