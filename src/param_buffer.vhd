----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.31.2022
-- Module Name: param_buffer.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of storing and providing a parameter value to the connected module

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

entity param_buffer is
    generic(
        PARAM_SIZE          : natural; -- Number of words that the param value occupies
        PARAM_ID            : unsigned(bits_req(MAX_PARAM_IDS) - 1 downto 0)  -- The id of this parameter
    );
    port(
        clk                 : in std_logic; -- 5mhz clock
        rst                 : in std_logic; -- asynchronous reset

        update              : in std_logic; -- Pulse that is broadcasted indicate that the value has to be updated
        param_id_to_update  : in unsigned(PARAM_ID'range);   -- The id of the parameter that has to be updated
        update_data         : in t_packet_payload; -- The data to be updated
        default_value       : in t_param_array(0 to PARAM_SIZE - 1); -- The initial value that this param should have
        param_data          : out t_param_array(0 to PARAM_SIZE - 1) -- The current data being provided to the connected block
    );

end param_buffer;

architecture behave of param_buffer is

begin


main_logic : process(clk, rst)
begin
    if (rst = '1') then
        param_data <= default_value;

    elsif (rising_edge(clk)) then
        if (update = '1' and param_id_to_update = PARAM_ID) then
            for i in param_data'range loop
                param_data(i) <= update_data(i);
            end loop;
        end if;
    end if;

end process;

end behave;