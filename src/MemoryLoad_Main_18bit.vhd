library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

ENTITY MemoryLoad_Main_18bit IS
	--GENERIC(<generic_const>	: <generic_type>);
	PORT(	clk					: IN std_logic;
			rst					: IN std_logic;
			gateRead			: IN std_logic;
			dataClkOut			: IN std_logic;
			valid				: IN std_logic;
			dataParallel		: IN std_logic_vector(17 downto 0);
			
			ready				: OUT std_logic;
			dataIn				: OUT std_logic;
			busy_flag           : IN std_logic
			);
END MemoryLoad_Main_18bit;


ARCHITECTURE behave OF MemoryLoad_Main_18bit IS

	SIGNAL gateEdgePulse_int : STD_LOGIC;
	SIGNAL dataClkOutEdgePulse_int : STD_LOGIC;
	
	SIGNAL gateEdgePulse_int_not_busy : STD_LOGIC;
	SIGNAL dataClkOutEdgePulse_int_not_busy : STD_LOGIC;
	
	attribute mark_debug : string;
	
	attribute mark_debug of gateEdgePulse_int			: signal is "true";

	
	COMPONENT FallEdgeDetector PORT ( clk  :IN std_logic;
									  rst :IN std_logic;
									  signal_in : IN std_logic;
									  signal_out : OUT std_logic);
	END COMPONENT;
	-- COMPONENT RiseEdgeDetector PORT ( clk  :IN std_logic;
									  -- rst :IN std_logic;
									  -- signal_in : IN std_logic;
									  -- signal_out : OUT std_logic
									  -- );
								  
	COMPONENT SM_MemoryLoad_18bit PORT(	clk					: IN std_logic;
									rst					: IN std_logic;
									gateFallEdgePulse	: IN std_logic;
									dataClkOutEdgePulse	: IN std_logic;
									valid				: IN std_logic;
									dataParallel		: IN std_logic_vector(17 downto 0);
									ready				: OUT std_logic;
									dataIn				: OUT std_logic;
									busy_flag			: IN std_logic
									);
	END COMPONENT;

BEGIN

gateEdgePulse_int_not_busy <= gateEdgePulse_int and (not busy_flag);
dataClkOutEdgePulse_int_not_busy <= dataClkOutEdgePulse_int and (not busy_flag);

edge_detector_gateRead : FallEdgeDetector PORT MAP ( clk => clk,
											 rst => rst,
											 signal_in => gateRead,
											 signal_out => gateEdgePulse_int);
edge_detector_dataClkOut : FallEdgeDetector PORT MAP ( clk => clk,
											 rst => rst,
											 signal_in => dataClkOut,
											 signal_out => dataClkOutEdgePulse_int);	
stateMachineMemoryLoad : SM_MemoryLoad_18bit PORT MAP ( clk => clk,
											 rst => rst,
											 gateFallEdgePulse => gateRead,
											 dataClkOutEdgePulse => dataClkOutEdgePulse_int_not_busy,
											 valid => valid,
											 dataParallel => dataParallel,
											 ready => ready,
											 dataIn => dataIn,
											 busy_flag => busy_flag
											 );											 

END behave;