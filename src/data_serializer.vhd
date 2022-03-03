----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 27.02.2022
-- Module Name: data_serializer_wrapper.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component may be used to serialize the parallel data to be sent to the SM_MemoryLoad_18bit component

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

entity data_serializer is
    port(
        clk                     : in std_logic; -- 100mhz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset
        gate_fall_pulse         : in std_logic; -- input signal that specifies when the CS signal for the DAC has been activated
        data_clk_fall_pulse     : in std_logic; -- input signal that specifies when the output clock falls
        valid                   : in std_logic; -- input signal that indicates that the parallel data is already valid
        parallel_data           : in std_logic_vector(17 downto 0); -- input vector with the data to be serialized. 
                                                                    -- MSB are sent first. The first 2 bits must indicate the DAC address

        busy_flag               : in std_logic; --input signal that must be not active for the component to work
        ready                   : out std_logic; --output signal that indicates that the component is ready to receive data
        serial_data             : out std_logic --output signal containing the serialized data
    );
end data_serializer;


architecture behave of data_serializer is

    -- Machine states
    type StateType is (INIT, REG_LOADED, WAIT_GATE, WAIT_FIRST_DATA_CLK_OUT, FIRST_BIT, WAIT_NEXT_DATA_CLK_OUT, 
                       NEXT_DATA, end_STREAM);
    signal State, NextState: StateType;
    -- Counter to know when the 18 bits have been sent
    signal count : unsigned (4 downto 0);
    -- Register for the ready signal
    signal ready_signal : std_logic;
    -- Shift register to store the parallel data
    signal reg_shift : std_logic_vector(17 downto 0);
    -- TODO: Remove or undertand
    signal gatearrived : std_logic := '1';
    
----------------------------------------------------------------------
    -- vio debugging
--  attribute mark_debug : string;
--  attribute mark_debug of State                   : signal is "true";
--  attribute mark_debug of count                   : signal is "true";
--  attribute mark_debug of reg_shift               : signal is "true";
--  attribute mark_debug of ready_signal            : signal is "true";
----------------------------------------------------------------------

begin

combinational: process (State, valid, count, gate_fall_pulse, data_clk_fall_pulse, gatearrived, ready_signal)
-- Combinational logic describing machine states
begin
    NextState <= INIT;

    case State is
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
            if data_clk_fall_pulse = '1' then
                NextState <= FIRST_BIT;
            else
                NextState <= WAIT_FIRST_DATA_CLK_OUT;
            end if;
        when FIRST_BIT =>
            NextState <= WAIT_NEXT_DATA_CLK_OUT;
        when WAIT_NEXT_DATA_CLK_OUT =>
            if count = "10001" then 
                NextState <= end_STREAM;
            elsif data_clk_fall_pulse = '1' then
                NextState <= NEXT_DATA;
            else
                NextState <= WAIT_NEXT_DATA_CLK_OUT;
            end if;
        when NEXT_DATA =>
            NextState <= WAIT_NEXT_DATA_CLK_OUT;
        when end_STREAM =>
            NextState <= INIT;
        when others =>
            NextState <= INIT;
    end case;
end process combinational;
    

-- Logic for each state 
sequential: process (clk, rst)
begin
    if rst = '1' then
        State 	<= INIT;
        count <= "00000";
        reg_shift <= "000000000000000000";
        ready_signal <= '0';
    elsif rising_edge(clk) then
        State <= NextState;
        
        case State is
            when INIT =>
                ready_signal <= '1';
            when REG_LOADED =>
                ready_signal	<= '0';
                reg_shift(17 downto 0) <= parallel_data(17 downto 0);
            when WAIT_GATE =>
            when WAIT_FIRST_DATA_CLK_OUT =>
            when FIRST_BIT =>
                count	<= "00000";
                reg_shift <= reg_shift(18-2 downto 0) & '0';
            when WAIT_NEXT_DATA_CLK_OUT =>
            when NEXT_DATA =>
                count	<= count + 1;
                reg_shift <= reg_shift(18-2 downto 0) & '0';
            when end_STREAM =>
                count	<= "00000";
                ready_signal	<= '1';
            when others =>
        end case;
    end if;
end process sequential;
serial_data <= reg_shift(17);
ready <= ready_signal;

end behave;