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
        DAC_start_pulse         : in std_logic; -- Pulse indicating that a new DAC cycle must start
        cs_fall_pulse           : in std_logic; -- Pulse indicating that the CS has fallen
        data_clk_fall_pulse     : in std_logic; -- input signal that specifies when the output clock falls
        valid                   : in std_logic; -- input signal that indicates that the parallel data is already valid
        parallel_data           : in std_logic_vector(17 downto 0); -- input vector with the data to be serialized. 
                                                                    -- MSB are sent first. The first 2 bits must indicate the DAC address

        serial_data             : out std_logic --output signal containing the serialized data
    );
end data_serializer;


architecture behave of data_serializer is

    -- Machine states
    type StateType is (INIT, REG_LOADED, WAIT_GATE, WAIT_FIRST_DATA_CLK_OUT, FIRST_BIT, WAIT_NEXT_DATA_CLK_OUT, 
                       NEXT_DATA, END_STREAM);
    signal state : StateType;

    -- Counter to know when the 18 bits have been sent
    signal counter : natural range 0 to 17;

    -- Shift register to store the parallel data
    signal reg_shift : std_logic_vector(17 downto 0);
    
    -- Signals that will be added to debug
    attribute keep : string;
    attribute keep of state       : signal is "true";
    --attribute keep of reg_shift   : signal is "true";

----------------------------------------------------------------------
    -- vio debugging
--  attribute mark_debug : string;
--  attribute mark_debug of State                   : signal is "true";
--  attribute mark_debug of counter                   : signal is "true";
--  attribute mark_debug of reg_shift               : signal is "true";
--  attribute mark_debug of ready_signal            : signal is "true";
----------------------------------------------------------------------

begin

-- The change of state must be sequential

state_change_logic : process(clk, rst)
begin
    if (rst = '1') then
        state <= INIT;
    elsif (rising_edge(clk)) then
        case state is
            when INIT =>
                counter <= 0;
                reg_shift <= (others => '0');
                if valid = '1' and DAC_start_pulse = '1' then 
                    state <= REG_LOADED;
                end if;
            when REG_LOADED =>
                reg_shift(17 downto 0) <= parallel_data(17 downto 0);
                state <= WAIT_GATE;
            when WAIT_GATE => 
                if cs_fall_pulse = '1' then
                    state <= WAIT_FIRST_DATA_CLK_OUT;
                end if;
            when WAIT_FIRST_DATA_CLK_OUT =>
                if data_clk_fall_pulse = '1' then
                    state <= FIRST_BIT;
                end if;
            when FIRST_BIT => 
                counter <= 0;
                reg_shift <= reg_shift(18-2 downto 0) & '0';
                state <= WAIT_NEXT_DATA_CLK_OUT;
            when WAIT_NEXT_DATA_CLK_OUT =>
                if counter = 17 then
                    state <= END_STREAM;
                elsif data_clk_fall_pulse = '1' then
                    reg_shift <= reg_shift(18-2 downto 0) & '0';
                    state <= NEXT_DATA;
                else
                    state <= WAIT_NEXT_DATA_CLK_OUT;
                end if;
            when NEXT_DATA =>
                counter <= counter + 1;
                state <= WAIT_NEXT_DATA_CLK_OUT;
            when END_STREAM =>
                counter <= 0;
                state <= INIT;
            when others =>
                state <= INIT;
        end case;
    end if;
end process;
    

serial_data <= reg_shift(17);

end behave;