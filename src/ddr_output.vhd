library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library UNISIM;
use     UNISIM.vcomponents.all;

library concept;
use     concept.utils.all;

entity ddr_output is
	port (
		clock        : in  std_logic;
		reset        : in  std_logic := '0'; -- optional reset
		input_en     : in  std_logic := '1'; -- optional output enable, defaults to always enable if unused
		parallel_in  : in  std_logic_vector(1 downto 0);
		ddr_out      : out std_logic
	);
end entity ddr_output;

architecture RTL of ddr_output is
begin
	IDDR_inst : ODDR
		generic map(
			DDR_CLK_EDGE => "OPPOSITE_EDGE",
			INIT         => '0',
			SRTYPE       => "SYNC"
		)
		port map (
			Q  => ddr_out,
			C  => clock,
			CE => input_en,
			D1 => parallel_in(0),
			D2 => parallel_in(1),
			R  => reset,
			S  => '0'
		);
end architecture RTL;