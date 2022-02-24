library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

package utils is
	-- AXI Stream Record (reduced for usecase)
	type T_AXIS_signed_m2s is record
		Data  : signed(15 downto 0);
		Valid : std_logic;
		User  : unsigned(7 downto 0);
	end record;
	type T_AXIS_signed_m2s_ARRAY_COLUMNS is array(1 to 8) of T_AXIS_signed_m2s;
	
	-- signed integer array
	type T_SIGNED_ARRAY_DATA is array(1 to 8) of signed(15 downto 0);
    type T_SIGNED_ARRAY_COEFFICIENTS is array(0 to 3) of signed(15 downto 0);
    type T_SIGNED_ARRAY_BUFFER is array(1 to 4) of signed(15 downto 0);
    type T_FRAME_HEADER is array(0 to 42) of std_logic_vector(31 downto 0);
    type T_FRAME_DATA_COLUMN is array(0 to 255) of std_logic_vector(31 downto 0);
    type T_FRAME_DATA is array(0 to 7) of T_FRAME_DATA_COLUMN;
	-- Buffer array
	type T_BUFF_ARRAY is array(INTEGER range 0 to 255) of T_SIGNED_ARRAY_BUFFER;
	
	-- Postive array, for generic
	type T_POSITIVE_ARRAY is array(natural range <>) of positive;

    function get_BRAM_ADDR_BITS(DATA_BITS : positive) return positive;
	function get_BRAM_write_enable_BITS(DATA_BITS : positive) return positive;


end package;

package body utils is

	--   -----------------------------------------------------------------------
	--   --  READ_WIDTH | BRAM_SIZE | READ Depth  | RDADDR Width |            --
	--   -- WRITE_WIDTH |           | WRITE Depth | WRADDR Width |  WE Width  --
	--   -- ============|===========|=============|==============|============--
	--   --    37-72    |  "36Kb"   |      512    |     9-bit    |    8-bit   --
	--   --    19-36    |  "36Kb"   |     1024    |    10-bit    |    4-bit   --
	--   --    19-36    |  "18Kb"   |      512    |     9-bit    |    4-bit   --
	--   --    10-18    |  "36Kb"   |     2048    |    11-bit    |    2-bit   --
	--   --    10-18    |  "18Kb"   |     1024    |    10-bit    |    2-bit   --
	--   --     5-9     |  "36Kb"   |     4096    |    12-bit    |    1-bit   --
	--   --     5-9     |  "18Kb"   |     2048    |    11-bit    |    1-bit   --
	--   --     3-4     |  "36Kb"   |     8192    |    13-bit    |    1-bit   --
	--   --     3-4     |  "18Kb"   |     4096    |    12-bit    |    1-bit   --
	--   --       2     |  "36Kb"   |    16384    |    14-bit    |    1-bit   --
	--   --       2     |  "18Kb"   |     8192    |    13-bit    |    1-bit   --
	--   --       1     |  "36Kb"   |    32768    |    15-bit    |    1-bit   --
	--   --       1     |  "18Kb"   |    16384    |    14-bit    |    1-bit   --
	--   -----------------------------------------------------------------------
	function get_BRAM_ADDR_BITS(DATA_BITS : positive) return positive is
	begin
		if(DATA_BITS >= 19) then
			return  9;
		elsif (DATA_BITS >= 10) then 
			return 10;
		elsif (DATA_BITS >=  5) then 
			return 11;
		elsif (DATA_BITS >=  3) then 
			return 12;
		elsif (DATA_BITS  =  2) then 
			return 13;               
		end if;
		return 14;
	end function;
	function get_BRAM_write_enable_BITS(DATA_BITS : positive) return positive is
	begin
		if (DATA_BITS >= 19) then 
			return  4;
		elsif (DATA_BITS >= 10) then 
			return  2;   
		end if;
		return 1;
	end function;

end package body;
