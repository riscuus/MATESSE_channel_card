----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 07.07.2022
-- Module Name: biquad_core.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is the main logic behind generic butterworth biquad.

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

entity biquad_core is
    generic(
        COEFF_WIDTH     : natural := 32;
        TRUNC_WIDTH     : natural := 5;
        DATA_WIDTH      : natural := 32;
        ROW_WIDTH       : natural := 4;
        RAM_ADDR_WIDTH  : natural := 9
    );
    port(
        clk                 : in std_logic;
        rst                 : in std_logic;

        b1                  : in signed(COEFF_WIDTH - 1 downto 0);
        b2                  : in signed(COEFF_WIDTH - 1 downto 0);
        k                   : in signed(TRUNC_WIDTH - 1 downto 0);
        x                   : in signed(DATA_WIDTH - 1 downto 0);
        x_row               : in unsigned(ROW_WIDTH - 1 downto 0);
        x_valid             : in std_logic;

        ram_0_write_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        ram_0_read_data     : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        ram_1_write_data    : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        ram_1_read_data     : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        ram_write_en        : out std_logic;
        ram_write_addr      : out unsigned(RAM_ADDR_WIDTH - 1 downto 0);

        y                   : out signed(DATA_WIDTH - 1 downto 0);
        y_row               : out unsigned(ROW_WIDTH - 1 downto 0);
        y_valid             : out std_logic
    );

end biquad_core;

architecture behave of biquad_core is
    constant INT_SIG_WIDTH : natural := 64;
    constant M : natural := 14; -- Number of decimal bits
    constant BUFFER_DEPTH : natural := 2;

    type stateType is (idle, write_ram, set_output_valid);
    type t_delay_buffer is array(0 to BUFFER_DEPTH - 1) of std_logic_vector(INT_SIG_WIDTH - 1 downto 0);

    signal state                : stateType := idle;

    signal delay_buffer_in      : t_delay_buffer := (others => (others => '0'));
    signal delay_buffer_out     : t_delay_buffer := (others => (others => '0'));

    signal x_reg                : signed(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal y_reg                : signed(DATA_WIDTH - 1 downto 0) := (others => '0');

    signal address_reg          : unsigned(ROW_WIDTH - 1 downto 0);

    signal x_n                  : signed(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal y_n                  : signed(DATA_WIDTH - 1 downto 0) := (others => '0');

    signal b2_prod              : signed(INT_SIG_WIDTH - 1 downto 0) := (others => '0');
    signal b1_prod              : signed(INT_SIG_WIDTH - 1 downto 0) := (others => '0');
    signal a1_prod              : signed(INT_SIG_WIDTH - 1 downto 0) := (others => '0');

    signal ram_0_write_data_reg : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ram_1_write_data_reg : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

begin

    -- 32
    x_n <= x_reg;
    -- 32 = max(32,32)
    y_n <= x_n + signed(delay_buffer_out(1)(DATA_WIDTH - 1 downto 0));

    -- 64 = 32 + 32
    b2_prod <= shift_right(y_n * b2, M); -- To maintain M fixed point we need to shift right to truncate the least significant bits
    -- 64 = max(32, 64)
    --delay_buffer_in(0) <= std_logic_vector(shift_right(x_n - b2_prod, COEFF_WIDTH - 1));
    delay_buffer_in(0) <= std_logic_vector(x_n - b2_prod);

    -- 64 = 32 + 32
    b1_prod <= shift_right(y_n * b1, M);

    -- 64 = 32 * 32
    a1_prod <= 2 * x_n; -- Bc the way numeric_std treats the integer multiplication shifting is not needed
    -- 64 = max(64, 64, 64)
    delay_buffer_in(1) <= std_logic_vector(a1_prod - b1_prod + signed(delay_buffer_out(0)));
    
    y <= y_reg;
    y_row <= address_reg;
    ram_write_addr <= resize(address_reg, ram_write_addr'length);

    ram_0_write_data <= delay_buffer_in(0)(DATA_WIDTH - 1 downto 0);
    ram_1_write_data <= delay_buffer_in(1)(DATA_WIDTH - 1 downto 0);

    delay_buffer_out(0)(DATA_WIDTH - 1 downto 0) <= ram_0_read_data;
    delay_buffer_out(1)(DATA_WIDTH - 1 downto 0) <= ram_1_read_data;

    main_logic : process(clk, rst)
    begin
        if (rst = '1') then
            ram_0_write_data_reg    <= (others => '0');
            ram_1_write_data_reg    <= (others => '0');
            address_reg             <= (others => '0');
            ram_write_en            <= '0';
            y_reg                   <= (others => '0');
            y_valid                 <= '0';

        elsif (rising_edge(clk)) then
            case state is
                when idle =>
                    if (x_valid = '1') then
                        x_reg <= x;
                        address_reg <= x_row;
                        ram_write_en <= '1';

                        state <= write_ram;
                    end if;
                when write_ram =>
                    ram_write_en <= '0';


                    y_reg <= y_n;
                    y_valid <= '1';

                    state <= set_output_valid;

                when set_output_valid =>
                    y_valid <= '0';

                    state <= idle;
                    
                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end behave;