----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 05.29.2022
-- Module Name: row_selector.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of specifying when a new row starts and specifying which row.

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

entity row_selector is
    generic(
        MAX_NUM_ROWS    : natural;
        MAX_ROW_LEN     : natural
    );
    port(
        clk                     : in std_logic; -- 5mhz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        sync_frame              : in std_logic; -- Pulse that indicates when a new frame must start
        acquisition_on          : in std_logic; -- Signal that indicates that we can accept sync_frame pulses
        num_rows                : in unsigned(bits_req(MAX_NUM_ROWS) - 1 downto 0);   -- Parameter that indicates how many rows do we have to select
        row_len                 : in unsigned(bits_req(MAX_ROW_LEN) - 1 downto 0);   -- Parameter that indicates how much time do we spend on each row, in 5Mhz clocks

        new_row                 : out std_logic;    -- Pulse that indicates that a new row has started
        row_num                 : out unsigned(bits_req(MAX_NUM_ROWS - 1) - 1 downto 0);      -- Signal that indicates in which row we currently are
        frame_active            : out std_logic     -- Signal that is active until the acquisition is off and the frame is over
    );

end row_selector;

architecture behave of row_selector is

    type stateType is (idle, wait_sync_frame, wait_next_row);
    signal state : stateType;

    signal row_num_reg : unsigned(row_num'range) := (others => '0');
    signal clk_counter : natural := 0;

begin

row_num <= row_num_reg;
frame_active <= '1' when state = wait_next_row else
                '0';

main_logic : process(clk, rst)
begin
    if (rst = '1') then
        state <= idle;
    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                row_num_reg <= (others => '0');
                new_row <= '0';

                if (acquisition_on = '1') then
                    state <= wait_sync_frame;
                else
                    state <= state;
                end if;

            when wait_sync_frame =>
                if (sync_frame = '1') then
                    new_row <= '1';

                    state <= wait_next_row;
                else
                    state <= state;
                end if;

            when wait_next_row =>
                new_row <= '0';
                if (clk_counter = row_len - 1) then -- End of a row
                    clk_counter <= 0;
                    if (row_num_reg = num_rows - 1) then -- Check if this row was the last one
                        if (acquisition_on = '1') then -- Continue with next frame
                            row_num_reg <= (others => '0');
                            state <= wait_sync_frame;
                        else -- Return to idle
                            state <= idle;
                        end if;
                    else -- Row was not the last one, continue with next row
                        new_row <= '1';
                        row_num_reg <= row_num_reg + 1;
                    end if;
                else
                    clk_counter <= clk_counter + 1;
                    state <= state;
                end if;

            when others =>
                state <= idle;
        end case;
    end if;

end process;

end behave;