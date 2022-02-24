library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

ENTITY SM_MemoryLoad_18bit IS
	PORT(	clk					: IN std_logic;
			rst				    : IN std_logic;
			gateFallEdgePulse	: IN std_logic;
			dataClkOutEdgePulse	: IN std_logic;
			valid				: IN std_logic;
			dataParallel		: IN std_logic_vector(17 downto 0);
			
			ready				: OUT std_logic;
			dataIn				: OUT std_logic;
			busy_flag			: IN std_logic
			);
END SM_MemoryLoad_18bit;


ARCHITECTURE behave OF SM_MemoryLoad_18bit IS

	TYPE StateType IS (INIT, REG_LOADED, WAIT_GATE, WAIT_FIRST_DATA_CLK_OUT, FIRST_BIT, WAIT_NEXT_DATA_CLK_OUT, NEXT_DATA, END_STREAM);
	SIGNAL State,NextState: StateType;
	SIGNAL count : UNSIGNED (4 downto 0);
	SIGNAL ready_signal : STD_LOGIC;
	SIGNAL reg_shift : STD_LOGIC_VECTOR (17 downto 0);
	SIGNAL gatearrived : STD_LOGIC := '1';
	
	SIGNAL dataClkOutEdgePulse_not_busy : STD_LOGIC;
	
	attribute mark_debug : string;
	attribute mark_debug of State 					: signal is "true";
	attribute mark_debug of count 					: signal is "true";
	attribute mark_debug of reg_shift 				: signal is "true";
	attribute mark_debug of ready_signal 		    : signal is "true";
	

BEGIN

dataClkOutEdgePulse_not_busy <= dataClkOutEdgePulse and (not busy_flag);

combinational: PROCESS (State,valid,count,gateFallEdgePulse,dataClkOutEdgePulse_not_busy,gatearrived, ready_signal)
-- Combinational logic describing next state
BEGIN
	NextState <= INIT;

	CASE State IS
		when INIT =>
			if valid = '1' and ready_signal = '1'  then 
				NextState <= REG_LOADED;
			else
				NextState <= INIT;
			end if;
		when REG_LOADED =>
			NextState <= WAIT_GATE;
		when WAIT_GATE =>
			if gatearrived = '1' then 
				NextState <= WAIT_FIRST_DATA_CLK_OUT;
			else
				NextState <= WAIT_GATE;
			end if;
		when WAIT_FIRST_DATA_CLK_OUT =>
			if dataClkOutEdgePulse_not_busy = '1' then
				NextState <= FIRST_BIT;
			else
				NextState <= WAIT_FIRST_DATA_CLK_OUT;
			end if;
		when FIRST_BIT =>
			NextState <= WAIT_NEXT_DATA_CLK_OUT;
		when WAIT_NEXT_DATA_CLK_OUT =>
			if count = "10001" then 
				NextState <= END_STREAM;
			elsif dataClkOutEdgePulse_not_busy = '1' then
				NextState <= NEXT_DATA;
			else
				NextState <= WAIT_NEXT_DATA_CLK_OUT;
			end if;
		when NEXT_DATA =>
			NextState <= WAIT_NEXT_DATA_CLK_OUT;
		when END_STREAM =>
			NextState <= INIT;
		when others =>
			NextState <= INIT;
	END CASE;
END PROCESS combinational;
	
sequential: PROCESS (clk, rst)
-- Clocked state transitions
BEGIN
	if rst = '1' then
		State 	<= INIT;
		count <= "00000";
		reg_shift <= "000000000000000000";
		ready_signal <= '0';
	elsif rising_edge(clk) then
		State <= NextState;
		
		CASE State IS
			when INIT =>
				ready_signal <= '1';
			when REG_LOADED =>
				ready_signal	<= '0';
				reg_shift(17 downto 0) <= dataParallel(17 downto 0);
			when WAIT_GATE =>
			when WAIT_FIRST_DATA_CLK_OUT =>
			when FIRST_BIT =>
				count	<= "00000";
				reg_shift <= reg_shift(18-2 downto 0) & '0';
			when WAIT_NEXT_DATA_CLK_OUT =>
			when NEXT_DATA =>
				count	<= count + 1;
				reg_shift <= reg_shift(18-2 downto 0) & '0';
			when END_STREAM =>
				count	<= "00000";
				ready_signal	<= '1';
			when others =>
		end case;
	end if;
END PROCESS sequential;
dataIn <= reg_shift(17);
ready <= ready_signal;

END behave;