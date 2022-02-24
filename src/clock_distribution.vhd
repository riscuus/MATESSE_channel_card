----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/20/2020 01:56:25 PM
-- Design Name: 
-- Module Name: clock_distribution - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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

library UNISIM;
use     UNISIM.vcomponents.all;

library concept;
use concept.utils.all;

entity clock_distribution is
	--generic (
	--    CLOCK_IN_FREQUENCY : ???? := ???
	--);
	port (
		clock_in   :  in std_logic;
		clock_005  : out std_logic;
		clock_100  : out std_logic;
		locked     : out std_logic
	);
end clock_distribution;

architecture RTL of clock_distribution is

	signal mmcm_clock_in     : std_logic;
	signal mmcm_feedback_in  : std_logic;
	signal mmcm_feedback_out : std_logic;
	signal mmcm_clock_out0   : std_logic;
	signal mmcm_clock_out1   : std_logic;
	
	attribute mark_debug : string;

begin

	--TODO input BUFG
	input_BUFG_inst : BUFG
		port map (
			I => clock_in,     -- 1-bit input: Clock input
			O => mmcm_clock_in -- 1-bit output: Clock output
		);

	-- Main MMCM managing all clocks
	main_MMCM_inst : MMCME2_ADV
		generic map (
			BANDWIDTH            => "OPTIMIZED", -- Jitter programming (OPTIMIZED, HIGH, LOW)
			CLKFBOUT_MULT_F      => 6.000,         -- Multiply value for all CLKOUT (2.000-64.000).
			CLKFBOUT_PHASE       => 0.0,         -- Phase offset in degrees of CLKFB (-360.000-360.000).
			-- CLKIN_PERIOD: Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
			CLKIN1_PERIOD        => 10.0, -- 100 ns (10 MHz)
			CLKIN2_PERIOD        => 0.0,
			-- CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for CLKOUT (1-128)
			CLKOUT1_DIVIDE       => 120, -- 10MHz * 10 / 20 = 5 MHz
			CLKOUT2_DIVIDE       =>  1, 
			CLKOUT3_DIVIDE       =>  1,
			CLKOUT4_DIVIDE       =>  1,
			CLKOUT5_DIVIDE       =>  1,
			CLKOUT6_DIVIDE       =>  1,
			CLKOUT0_DIVIDE_F     => 6.0, -- 10MHz * 10 / 1 = 100 MHz
			-- CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for CLKOUT outputs (0.01-0.99).
			CLKOUT0_DUTY_CYCLE   => 0.5,
			CLKOUT1_DUTY_CYCLE   => 0.5,
			CLKOUT2_DUTY_CYCLE   => 0.5,
			CLKOUT3_DUTY_CYCLE   => 0.5,
			CLKOUT4_DUTY_CYCLE   => 0.5,
			CLKOUT5_DUTY_CYCLE   => 0.5,
			CLKOUT6_DUTY_CYCLE   => 0.5,
			-- CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for CLKOUT outputs (-360.000-360.000).
			CLKOUT0_PHASE        => 0.0,
			CLKOUT1_PHASE        => 0.0,
			CLKOUT2_PHASE        => 0.0,
			CLKOUT3_PHASE        => 0.0,
			CLKOUT4_PHASE        => 0.0,
			CLKOUT5_PHASE        => 0.0,
			CLKOUT6_PHASE        => 0.0,
			CLKOUT4_CASCADE      =>   FALSE, -- Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
			COMPENSATION         => "ZHOLD", -- ZHOLD, BUF_IN, EXTERNAL, INTERNAL
			DIVCLK_DIVIDE        =>   1,     -- Master division value (1-106)
			-- REF_JITTER: Reference input jitter in UI (0.000-0.999).
			REF_JITTER1          => 0.0,
			REF_JITTER2          => 0.0,
			STARTUP_WAIT         => FALSE, -- Delays DONE until MMCM is locked (FALSE, TRUE)
			-- Spread Spectrum: Spread Spectrum Attributes
			SS_EN                =>       "FALSE", -- Enables spread spectrum (FALSE, TRUE)
			SS_MODE              => "CENTER_HIGH", -- CENTER_HIGH, CENTER_LOW, DOWN_HIGH, DOWN_LOW
			SS_MOD_PERIOD        =>         10000, -- Spread spectrum modulation period (ns) (VALUES)
			-- USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
			CLKFBOUT_USE_FINE_PS => FALSE,
			CLKOUT0_USE_FINE_PS  => FALSE,
			CLKOUT1_USE_FINE_PS  => FALSE,
			CLKOUT2_USE_FINE_PS  => FALSE,
			CLKOUT3_USE_FINE_PS  => FALSE,
			CLKOUT4_USE_FINE_PS  => FALSE,
			CLKOUT5_USE_FINE_PS  => FALSE,
			CLKOUT6_USE_FINE_PS  => FALSE
		)
		port map (
			-- Clock Outputs: 1-bit (each) output: User configurable clock outputs
			CLKOUT0      => mmcm_clock_out0, -- 1-bit output: CLKOUT0
			CLKOUT0B     => open, -- 1-bit output: Inverted CLKOUT0
			CLKOUT1      => mmcm_clock_out1, -- 1-bit output: CLKOUT1
			CLKOUT1B     => open, -- 1-bit output: Inverted CLKOUT1
			CLKOUT2      => open, -- 1-bit output: CLKOUT2
			CLKOUT2B     => open, -- 1-bit output: Inverted CLKOUT2
			CLKOUT3      => open, -- 1-bit output: CLKOUT3
			CLKOUT3B     => open, -- 1-bit output: Inverted CLKOUT3
			CLKOUT4      => open, -- 1-bit output: CLKOUT4
			CLKOUT5      => open, -- 1-bit output: CLKOUT5
			CLKOUT6      => open, -- 1-bit output: CLKOUT6
			-- DRP Ports: 16-bit (each) output: Dynamic reconfiguration ports
			DO           => open, -- 16-bit output: DRP data
			DRDY         => open, -- 1-bit output: DRP ready
			-- Dynamic Phase Shift Ports: 1-bit (each) output: Ports used for dynamic phase shifting of the outputs
			PSDONE       => open, -- 1-bit output: Phase shift done
			-- Feedback Clocks: 1-bit (each) output: Clock feedback ports
			CLKFBOUT     => mmcm_feedback_out, -- 1-bit output: Feedback clock
			CLKFBOUTB    => open, -- 1-bit output: Inverted CLKFBOUT
			-- Status Ports: 1-bit (each) output: MMCM status ports
			CLKFBSTOPPED => open, -- 1-bit output: Feedback clock stopped
			CLKINSTOPPED => open, -- 1-bit output: Input clock stopped
			LOCKED       => locked, -- 1-bit output: LOCK
			-- Clock Inputs: 1-bit (each) input: Clock inputs
			CLKIN1       => mmcm_clock_in, -- 1-bit input: Primary clock
			CLKIN2       => '0', -- 1-bit input: Secondary clock
			-- Control Ports: 1-bit (each) input: MMCM control ports
			CLKINSEL     => '1', -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
			PWRDWN       => '0', -- 1-bit input: Power-down
			RST          => '0', -- 1-bit input: Reset
			-- DRP Ports: 7-bit (each) input: Dynamic reconfiguration ports
			DADDR        => (others => '0'), -- 7-bit input: DRP address
			DCLK         => '0', -- 1-bit input: DRP clock
			DEN          => '0', -- 1-bit input: DRP enable
			DI           => (others => '0'), -- 16-bit input: DRP data
			DWE          => '0', -- 1-bit input: DRP write enable
			-- Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
			PSCLK        => '0', -- 1-bit input: Phase shift clock
			PSEN         => '0', -- 1-bit input: Phase shift enable
			PSINCDEC     => '0', -- 1-bit input: Phase shift increment/decrement
			-- Feedback Clocks: 1-bit (each) input: Clock feedback ports
			CLKFBIN      => mmcm_feedback_in -- 1-bit input: Feedback clock
		);

	-- TODO Output BUFG Feedback
	feedback_BUFG_inst : BUFG
		port map (
			I => mmcm_feedback_out, -- 1-bit input: Clock input
			O => mmcm_feedback_in   -- 1-bit output: Clock output
		);

	-- TODO Output BUFG CLK1
	output0_BUFG_inst : BUFG
		port map (
			I => mmcm_clock_out0, -- 1-bit input: Clock input
			O => clock_100  -- 1-bit output: Clock output
		);

	-- TODO Output BUFG CLK2
	output1_BUFG_inst : BUFG
		port map (
			I => mmcm_clock_out1, -- 1-bit input: Clock input
			O => clock_005  -- 1-bit output: Clock output
		);

end architecture;
