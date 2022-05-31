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
        param_size              : natural; -- Number of words that the param value occupies
        address                 : natural  -- The address of this parameter
    );
    port(
        clk             : in std_logic; -- 5mhz clock
        rst             : in std_logic; -- asynchronous reset

        update          : in std_logic; -- Pulse that is broadcasted indicate that the value has to be updated
        update_address  : in natural;   -- The address of the parameter that has to be updated
        update_data     : in t_packet_payload; -- The data to be updated
        param_data      : out t_param_array(0 to param_size - 1) -- The current data being provided to the connected block
    );

end param_buffer;

architecture behave of param_buffer is

    signal param_data_reg : t_param_array(0 to param_size - 1) := (others => (others => '0'));

begin

    param_data <= param_data_reg;

main_logic : process(clk, rst)
begin
    if (rst = '1') then
        param_data_reg <= (others => (others => '0'));

    elsif (rising_edge(clk)) then
        if (update = '1' and update_address = address) then
            for i in param_data'range loop
                param_data_reg(i) <= update_data(i);
            end loop;
        end if;
    end if;

end process;

end behave;