library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

Library UNISIM;
use     UNISIM.vcomponents.all;

Library UNIMACRO;
use     UNIMACRO.vcomponents.all;

library concept;
use     concept.utils.all;



entity IIR_transposed is
	generic (
		BUFF_ELEMENTS  : positive := 256;
		MAX_BUF_BITS     : positive       := 64 -- TODO fixit make constant calculated for sum_TRUNC_CONFIG maxima
	);
	port (
		Clock          : in  std_logic;
		Reset          : in  std_logic;
		-- Filter input, buffer selection is done via Userbits
		IIR_in_m2s     : in  T_AXIS_signed_m2s;
		-- Filter output
		IIR_out_m2s    : out T_AXIS_signed_m2s;
		-- coefficients input
		b_coefficients : in  T_SIGNED_ARRAY_COEFFICIENTS;
		a_coefficients : in  T_SIGNED_ARRAY_COEFFICIENTS
		
	);
end entity;



architecture RTL of IIR_transposed is
	-- Vivado 2018.3 workaround to get bit widths
	constant IIR_in_m2s_DATA_BITS  : natural := IIR_in_m2s.Data'length; 
	constant IIR_in_m2s_USER_BITS  : natural := IIR_in_m2s.User'length;
	constant IIR_out_m2s_DATA_BITS : natural := IIR_out_m2s.Data'length;
	constant IIR_out_m2s_USER_BITS : natural := IIR_out_m2s.User'length;
	constant a_coefficients_ELEM   : natural := a_coefficients'length(1);
	constant b_coefficients_ELEM   : natural := b_coefficients'length(1);

	
	-- buffer needs to be as deep as the maximum number of coefficients set
	-- constant BUFFERS_DEPTH         : natural := maximum(a_coefficients_ELEM, b_coefficients_ELEM) - 1;
    constant BUFFERS_DEPTH         : natural := a_coefficients_ELEM;
	-- input buffer signals
	signal input_buf               : signed(IIR_in_m2s_DATA_BITS - 1 downto 0);
	signal input_valid             : std_logic;

	-- delay buffers array:
	signal delay_buffer_in         : T_SIGNED_ARRAY_BUFFER;
	signal delay_buffer_out        : T_SIGNED_ARRAY_BUFFER;

	signal buffer_address          : unsigned(IIR_in_m2s_USER_BITS - 1 downto 0);
	signal x_n                     : signed(IIR_in_m2s_DATA_BITS - 1 downto 0);
	signal y_n                     : signed(IIR_in_m2s_DATA_BITS - 1 downto 0);
	signal filter_shift            : std_logic;

begin
	-- sanity checks for easyer debugging:
--	assert (not (IIR_in_m2s_DATA_BITS = IIR_out_m2s_DATA_BITS)) 
--		report "width mismatch on Data width, IN: "& to_string(IIR_in_m2s_DATA_BITS) & " OUT: "& to_string(IIR_out_m2s_DATA_BITS)
--		severity FAILURE;
--	assert (not (IIR_in_m2s_USER_BITS = IIR_out_m2s_USER_BITS)) 
--		report "width mismatch on Data width, IN: "& to_string(IIR_in_m2s_USER_BITS) & " OUT: "& to_string(IIR_out_m2s_USER_BITS)
--		severity FAILURE;
--	assert (not (a_coefficients_ELEM = b_coefficients_ELEM)) 
--		report "The current implementation does not support different coeffient numbers. A: "& to_string(a_coefficients_ELEM) & " B: "& to_string(b_coefficients_ELEM)
--		severity FAILURE;


	----------------------------------------------------------------------------
	-- Filter Math -------------------------------------------------------------
	----------------------------------------------------------------------------

	-- x_n assignment
	x_n <= input_buf;

	-- y_n calculation
	y_n <= x_n + delay_buffer_out(1);

	-- filter in combinatorial:
	accumulate: for i in 1 to BUFFERS_DEPTH-1 generate
		-- for each element in buffer: z-i <= x_n * b_i-1 + y_n * -a_i-1 + z-i+1
		-- delay_buffer_in(i) <= (x_n * b_coefficients(i-1)) + (y_n * (- a_coefficients(i-1))) + delay_buffer_out(i+1);
		delay_buffer_in(i) <= (x_n) + (y_n) + delay_buffer_out(i+1);
	end generate;
	-- highest element: z-max <= x_n * b_max + y_n * -a_max
	-- delay_buffer_in(BUFFERS_DEPTH) <= (x_n * b_coefficients(BUFFERS_DEPTH-1)) + (y_n * (- a_coefficients(BUFFERS_DEPTH-1)));
	delay_buffer_in(BUFFERS_DEPTH) <= (x_n) + (y_n);

	----------------------------------------------------------------------------
	-- Filter data flow control ------------------------------------------------
	----------------------------------------------------------------------------

	process(Clock) is
	begin
		if rising_edge(Clock) then
			if(Reset = '1') then
				input_valid       <= '0';
				buffer_address    <= (others => '0');
				input_buf         <= (others => '0');
				filter_shift      <= '0';
				IIR_out_m2s.Valid <= '0';
			else

				-- run only on valid:
				if(IIR_in_m2s.Valid = '1') then
					-- get buffer address from user bits of input data:
					buffer_address <= IIR_in_m2s.User;
					input_buf      <= IIR_in_m2s.Data;
					input_valid    <= '1';
				else
					input_valid    <= '0';
				end if;

				filter_shift   <= input_valid;

				if(filter_shift = '1') then
					IIR_out_m2s.Valid <= '1';
					IIR_out_m2s.User  <= buffer_address;
					IIR_out_m2s.Data  <= y_n;
				else
					IIR_out_m2s.Valid <= '0';
				end if;
			end if;
		end if;
	end process;

	   -----------------------------------------------------------------------
	   --  READ_WIDTH | BRAM_SIZE | READ Depth  | RDADDR Width |            --
	   -- WRITE_WIDTH |           | WRITE Depth | WRADDR Width |  WE Width  --
	   -- ============|===========|=============|==============|============--
	   --    37-72    |  "36Kb"   |      512    |     9-bit    |    8-bit   --
	   --    19-36    |  "36Kb"   |     1024    |    10-bit    |    4-bit   --
	   --    19-36    |  "18Kb"   |      512    |     9-bit    |    4-bit   --
	   --    10-18    |  "36Kb"   |     2048    |    11-bit    |    2-bit   --
	   --    10-18    |  "18Kb"   |     1024    |    10-bit    |    2-bit   --
	   --     5-9     |  "36Kb"   |     4096    |    12-bit    |    1-bit   --
	   --     5-9     |  "18Kb"   |     2048    |    11-bit    |    1-bit   --
	   --     3-4     |  "36Kb"   |     8192    |    13-bit    |    1-bit   --
	   --     3-4     |  "18Kb"   |     4096    |    12-bit    |    1-bit   --
	   --       2     |  "36Kb"   |    16384    |    14-bit    |    1-bit   --
	   --       2     |  "18Kb"   |     8192    |    13-bit    |    1-bit   --
	   --       1     |  "36Kb"   |    32768    |    15-bit    |    1-bit   --
	   --       1     |  "18Kb"   |    16384    |    14-bit    |    1-bit   --
	   -----------------------------------------------------------------------

	-- BRAM for buffers:
	delay_buf_gen : for i in 1 to BUFFERS_DEPTH generate
		constant buffer_address_BITS   : positive := get_BRAM_ADDR_BITS(IIR_in_m2s_DATA_BITS); -- Address bits are adjusted with the get_BRAM_ADDR_BITS function
		constant write_enable_BITS     : positive := get_BRAM_write_enable_BITS(IIR_in_m2s_DATA_BITS);

		signal delay_buffer_out_slv : std_logic_vector(IIR_in_m2s_DATA_BITS - 1 downto 0);
		signal buffer_address_slv   : std_logic_vector( buffer_address_BITS - 1 downto 0);
		signal write_enable         : std_logic_vector(   write_enable_BITS - 1 downto 0);
	begin
		delay_buffer_out(i)                                   <= signed(delay_buffer_out_slv);
		buffer_address_slv(buffer_address_BITS - 1 downto IIR_in_m2s_USER_BITS) <= (others => '0');
		buffer_address_slv(IIR_in_m2s_USER_BITS - 1 downto 0) <= std_logic_vector(buffer_address);
		write_enable                                          <= (others => filter_shift);
		BRAM_SDP_MACRO_inst : BRAM_SDP_MACRO
			generic map (
				BRAM_SIZE    => "18Kb",                          -- Target BRAM, "18Kb" or "36Kb" 
				DEVICE       => "7SERIES",                       -- Target device: "VIRTEX5", "VIRTEX6", "7SERIES", "SPARTAN6" 
				WRITE_WIDTH  => IIR_in_m2s_DATA_BITS,            -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
				READ_WIDTH   => IIR_in_m2s_DATA_BITS,            -- Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
				DO_REG       => 0,                               -- Optional output register (0 or 1)
				WRITE_MODE   => "READ_FIRST"                     -- Specify "READ_FIRST" for same clock or synchronous clocks
			)
			port map (
				DO     => delay_buffer_out_slv,                  -- Output read data port, width defined by READ_WIDTH parameter
				DI     => std_logic_vector(delay_buffer_in(i)),  -- Input write data port, width defined by WRITE_WIDTH parameter
				RDADDR => buffer_address_slv,                    -- Input read address, width defined by read port depth
				RDCLK  => Clock,                                 -- 1-bit input read clock
				RDEN   => '1',                                   -- 1-bit input read port enable
				REGCE  => '1',                                   -- 1-bit input read output register enable
				RST    => Reset,                                 -- 1-bit input reset 
				WE     => write_enable,                          -- Input write enable, width defined by write port depth
				WRADDR => buffer_address_slv,                    -- Input write address, width defined by write port depth
				WRCLK  => Clock,                                 -- 1-bit input write clock
				WREN   => '1'                                    -- 1-bit input write port enable
			);
	end generate;

end architecture;




