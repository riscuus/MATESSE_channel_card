----------------------------------------------------------------------
--	SM_MemoryLoad_18bit.vhd -- Data serializer for DACs
----------------------------------------------------------------------
-- Author:  Iban Ibanez, Albert Risco
----------------------------------------------------------------------
--
----------------------------------------------------------------------
-- Summary:
-- This component may be used to serialize the parallel data to be sent.  
-- to the DAC device.
-- 
-- Port Descriptions:
--
--                       clk - 100mhz clock
--                       rst - asynchronous reset
--           gate_fall_pulse - input signal that specifies when the CS signal for the DAC has been activated
--       data_clk_fall_pulse - input signal that specifies when the output clock falls
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

entity SM_MemoryLoad_18bit IS
    port(

            clk                     : IN std_logic;
            rst                     : IN std_logic;
            gate_fall_pulse         : IN std_logic;
            data_clk_fall_pulse     : IN std_logic;
            valid                   : IN std_logic;
            parallel_data           : IN std_logic_vector(17 downto 0);
            busy_flag               : IN std_logic;
            
            ready                   : OUT std_logic;
            serial_data             : OUT std_logic
            );
end SM_MemoryLoad_18bit;


architecture behave of SM_MemoryLoad_18bit is

    -- Machine states
    type StateType is (INIT, REG_LOADED, WAIT_GATE, WAIT_FIRST_DATA_CLK_OUT, FIRST_BIT, WAIT_NEXT_DATA_CLK_OUT, 
                       NEXT_DATA, end_STREAM);
    signal State, NextState: StateType;
    -- Counter to know when the 18 bits have been sent
    signal count : UNSIGNED (4 downto 0);
    -- Register for the ready signal
    signal ready_signal : STD_LOGIC;
    -- Shift register to store the parallel data
    signal reg_shift : STD_LOGIC_VECTOR (17 downto 0);
    -- TODO: Remove or undertand
    signal gatearrived : STD_LOGIC := '1';
    
----------------------------------------------------------------------
    -- vio debugging
    attribute mark_debug : string;
    attribute mark_debug of State                   : signal is "true";
    attribute mark_debug of count                   : signal is "true";
    attribute mark_debug of reg_shift               : signal is "true";
    attribute mark_debug of ready_signal            : signal is "true";
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
    end CASE;
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