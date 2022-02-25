----------------------------------------------------------------------
--	MemoryLoad_Main_18bit.vhd -- Wrapper for the SM_MemoryLoad_18bit component
----------------------------------------------------------------------
-- Author:  Iban Ibanez, Albert Risco
----------------------------------------------------------------------
--
----------------------------------------------------------------------
-- Summary:
-- This component may be used to correctly setup the signals for the SM_MemoryLoad_18bit component
-- 
-- Port Descriptions:
--
--                       clk - 100mhz clock
--                       rst - asynchronous reset
--      gate_fall_pulse - input signal that specifies when the CS signal for the DAC has been activated
--       data_clk_edge_pulse - input signal that specifies when the output clock falls
--                     valid - input signal that indicates that the parallel data is already valid
--             parallel_data - input vector with the data to be serialized. MSB are sent first. The first 2 bits must
--                             indicate the DAC address
--                 busy_flag - input signal that must be not active for the component to work
--                     ready - output signal that indicates that the component is ready to receive data
--               serial_data - output signal containing the serialized data
----------------------------------------------------------------------
library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

ENTITY MemoryLoad_Main_18bit IS
    PORT(   clk                 : in std_logic;
            rst                 : in std_logic;
            gate_read           : in std_logic;
            data_clk            : in std_logic;
            valid               : in std_logic;
            parallel_data       : in std_logic_vector(17 downto 0);
            busy_flag           : in std_logic;
            
            ready               : out std_logic;
            serial_data         : out std_logic
        );
end MemoryLoad_Main_18bit;


architecture behave of MemoryLoad_Main_18bit is

    signal gate_edge_pulse_int : STD_LOGIC;
    signal data_clk_fall_pulse_int : STD_LOGIC;
    
    signal gate_edge_pulse_int_not_busy : STD_LOGIC;
    signal data_clk_fall_pulse_not_busy: STD_LOGIC;

----------------------------------------------------------------------
    --  vio debugging
    attribute mark_debug : string;
    attribute mark_debug of gate_edge_pulse_int : signal is "true";
----------------------------------------------------------------------

    
    component FallEdgeDetector PORT ( clk           : in std_logic; 
                                      rst           : in std_logic;
                                      signal_in     : in std_logic;
                                      signal_out    : out std_logic);
    end component;
                                  
    component SM_MemoryLoad_18bit PORT( clk                     : in std_logic;
                                        rst                     : in std_logic;
                                        gate_fall_pulse         : in std_logic;
                                        data_clk_fall_pulse     : in std_logic;
                                        valid                   : in std_logic;
                                        parallel_data           : in std_logic_vector(17 downto 0);
                                        busy_flag               : in std_logic;
                                        ready                   : out std_logic;
                                        serial_data             : out std_logic);
    end component;

begin

gate_edge_pulse_int_not_busy <= gate_edge_pulse_int and (not busy_flag);
data_clk_fall_pulse_not_busy<= data_clk_fall_pulse_int and (not busy_flag);

edge_detector_gateRead : FallEdgeDetector port map ( clk => clk,
                                                     rst => rst,
                                                     signal_in => gate_read,
                                                     signal_out => gate_edge_pulse_int
                                                    );

edge_detector_dataClkOut : FallEdgeDetector port map ( clk => clk,
                                                       rst => rst,
                                                       signal_in => data_clk,
                                                       signal_out => data_clk_fall_pulse_int
                                                     );	

stateMachineMemoryLoad : SM_MemoryLoad_18bit port map ( clk => clk,
                                                        rst => rst,
                                                        gate_fall_pulse => gate_read,
                                                        data_clk_fall_pulse => data_clk_fall_pulse_not_busy,
                                                        valid => valid,
                                                        parallel_data => parallel_data,
                                                        ready => ready,
                                                        serial_data => serial_data,
                                                        busy_flag => busy_flag
                                                       );
                                             

end behave;