----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 27.02.2022
-- Module Name: data_serializer_wrapper.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component may be used to correctly setup the signals for the SM_MemoryLoad_18bit component

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

entity data_serializer_wrapper is
    port(   
        clk                 : in std_logic; --100mhz clock
        rst                 : in std_logic; --asynchronous reset
        gate_read           : in std_logic; --input signal that specifies when the CS signal for the DAC has been activated
        data_clk            : in std_logic; --input signal that specifies when the output clock falls
        valid               : in std_logic; --input signal that indicates that the parallel data is already valid
        parallel_data       : in std_logic_vector(17 downto 0); --input vector with the data to be serialized. 
                                                                -- MSB are sent first. The first 2 bits must
                                                                -- indicate the DAC address
        busy_flag           : in std_logic; --input signal that must be not active for the component to work
        ready               : out std_logic; -- output signal that indicates that the component is ready to receive data
        serial_data         : out std_logic --output signal containing the serialized data                                          
    );
end data_serializer_wrapper;


architecture behave of data_serializer_wrapper is

    signal gate_edge_pulse_int : std_logic;
    signal data_clk_fall_pulse_int : std_logic;
    
    signal gate_edge_pulse_int_not_busy : std_logic;
    signal data_clk_fall_pulse_not_busy: std_logic;

----------------------------------------------------------------------
    --  vio debugging
--  attribute mark_debug : string;
--  attribute mark_debug of gate_edge_pulse_int : signal is "true";
----------------------------------------------------------------------

begin

gate_edge_pulse_int_not_busy <= gate_edge_pulse_int and (not busy_flag);
data_clk_fall_pulse_not_busy <= data_clk_fall_pulse_int and (not busy_flag);

    edge_detector_gateRead : entity concept.FallEdgeDetector 
        port map ( 
            clk         => clk,
            rst         => rst,
            signal_in   => gate_read,
            signal_out  => gate_edge_pulse_int
        );

    edge_detector_dataClkOut : entity concept.FallEdgeDetector 
        port map ( 
            clk         => clk,
            rst         => rst,
            signal_in   => data_clk,
            signal_out  => data_clk_fall_pulse_int
        );

    stateMachineMemoryLoad : entity concept.data_serializer 
        port map ( 
            clk                     => clk,
            rst                     => rst,
            data_clk_fall_pulse     => data_clk_fall_pulse_not_busy,
            valid                   => valid,
            parallel_data           => parallel_data,
            ready                   => ready,
            serial_data             => serial_data
        );

end behave;