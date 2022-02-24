library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library UNISIM;
use     UNISIM.vcomponents.all;

library concept;
use     concept.utils.all;

entity ddr_input is
	port (
		clock        : in  std_logic;
		reset        : in  std_logic := '0'; -- optional reset
		output_en    : in  std_logic := '1'; -- optional output enable, defaults to always enable if unused
		ddr_in       : in  std_logic;
		parallel_out : out std_logic_vector(1 downto 0)
	);
end entity ddr_input;

architecture RTL of ddr_input is
begin
	IDDR_inst : IDDR
		generic map (
			DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE", "SAME_EDGE" or "SAME_EDGE_PIPELINED"
			INIT_Q1      => '0', -- Initial value of Q1: '0' or '1'
			INIT_Q2      => '0', -- Initial value of Q2: '0' or '1'
			SRTYPE       => "SYNC" -- Synchronous Reset
		)
		port map (
			Q1 => parallel_out(0), -- 1-bit output for positive edge of clock 
			Q2 => parallel_out(1), -- 1-bit output for negative edge of clock
			C  => clock,           -- 1-bit primary clock input
			CE => output_en,       -- 1-bit clock enable input
			D  => ddr_in,          -- 1-bit DDR data input
			R  => reset,           -- 1-bit reset
			S  => '0'              -- 1-bit set
		);
end architecture RTL;