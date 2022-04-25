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
    -- Necessary ??
    type T_SIGNED_ARRAY_DATA is array(1 to 8) of signed(15 downto 0);
    type T_SIGNED_ARRAY_COEFFICIENTS is array(0 to 3) of signed(15 downto 0);
    type T_SIGNED_ARRAY_BUFFER is array(1 to 4) of signed(15 downto 0);

        -- TODO: Parameterize these "magic numbers"
    -- Data structures for packets 
    subtype t_byte is std_logic_vector(7 downto 0);
    subtype t_half_word is std_logic_vector(15 downto 0); -- Used in some parameters of some packets
    subtype t_word is std_logic_vector(31 downto 0);
    type t_packet_payload is array(0 to 555) of t_word; -- 2 cols * 256 rows + 43 header words

    type t_packet_type is (cmd_rb, cmd_wb, cmd_go, cmd_st, cmd_rs, reply, data);


    -- Constants 
    constant PREAMBLE_1 : t_word := x"A5A5A5A5";
    constant PREAMBLE_2 : t_word := x"5A5A5A5A";

    constant CMD_RB_TYPE : t_word := x"20205242"; -- ASCII: "__RB"
    constant CMD_WB_TYPE : t_word := x"20205742"; -- ASCII: "__WB"
    constant CMD_GO_TYPE : t_word := x"2020474F"; -- ASCII: "__GO"
    constant CMD_ST_TYPE : t_word := x"20205354"; -- ASCII: "__ST"
    constant CMD_RS_TYPE : t_word := x"20205253"; -- ASCII: "__RS"
    constant REPLY_TYPE  : t_word := x"20205250"; -- ASCII: "__RP"
    constant DATA_TYPE   : t_word := x"20204441"; -- ASCII: "__DA"

    constant RB_ASCII : t_half_word := x"5242"; -- ASCII: "RB"
    constant WB_ASCII : t_half_word := x"5742"; -- ASCII: "WB"
    constant GO_ASCII : t_half_word := x"474F"; -- ASCII: "GO"
    constant ST_ASCII : t_half_word := x"5354"; -- ASCII: "ST"
    constant RS_ASCII : t_half_word := x"5253"; -- ASCII: "RS"

    constant OK_ASCII : t_half_word := x"4F4B"; -- ASCII : "OK"
    constant ER_ASCII : t_half_word := x"4552"; -- ASCII : "ER"

    constant CMD_PAYLOAD_FIXED_SIZE : natural := 58;


    -- Data structures for frames
    type t_frame_header is array(0 to 42) of t_word;
    type t_frame_data_col is array(0 to 255) of t_word;
    type t_frame_data is array(0 to 1) of t_frame_data_col;

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
