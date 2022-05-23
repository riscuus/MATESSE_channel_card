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
    type t_packet_payload is array(0 to 66) of t_word; -- Max payload that any packet will have. 2 cols * 12 rows + 43 header words
    type t_cmd_payload is array(0 to CMD_REPLY_MAX_SIZE - 1) of t_word; -- Fixed size of 58 words. Defined by MCE. Also max size for reply packet
    type t_max_reply_payload is array(0 to CMD_REPLY_MAX_SIZE - 1) of t_word;

    type t_packet_type is (cmd_rb, cmd_wb, cmd_go, cmd_st, cmd_rs, reply, data, undefined);

    type t_param_id is (row_len, 
                        num_rows,
                        ret_dat_s,
                        sa_bias,
                        ret_data,
                        servo_mode,
                        ramp_dly,
                        ramp_amp,
                        ramp_step,
                        fb_const,
                        sample_dly,
                        sample_num,
                        fb_dly,
                        fltr_rst,
                        fltr_coeff,
                        flux_fb,
                        bias,
                        row_order,
                        on_bias,
                        off_bias
                       );
    
    subtype t_param_id_address is natural range 0 to PARAM_ID_RAM_DEPTH - 1;
    
    type t_param_address_ram is array(0 to PARAM_ID_RAM_DEPTH - 1) of t_param_id; 

    ----------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------

    -- Basic constraints
    constant MAX_CHANNELS       : natural := 2; -- Max channels that the daughter board can handle
    constant MAX_ROWS           : natural := 8; -- Max rows that the daughter board can handle
    constant IIR_FILTER_POLES   : natural := 4; -- This will define the depth of the buffers and the size of the coef arrays

    -- Packet constants
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

    constant CMD_REPLY_MAX_SIZE : natural := 58;

    -- This card ID
    constant DAUGHTER_CARD_ID : t_half_word := x"ffff";

    -- Max number a param id address can have
    constant PARAM_ID_RAM_DEPTH : natural := 256;

    -- The addresses of each param id
    constant ROW_LEN_ADDR       : t_param_id_address := x"30"; -- Affects row_selector (how many pulses to spend on each row)
    constant NUM_ROWS_ADDR      : t_param_id_address := x"31"; -- Affects row_selector (to cycle #num_rows)
    constant RET_DATA_S_ADDR    : t_param_id_address := x"53"; -- Affects the data_frame_builder (num in header)
    constant SA_BIAS_ADDR       : t_param_id_address := x"10"; -- Affects bias_setter (SA bias)
    constant RET_DAT_ADDR       : t_param_id_address := x"16"; -- Start Acquisition
    constant SERVO_MODE_ADDR    : t_param_id_address := x"1B"; -- Affects feedback_setter (can get values from feedback calculator, constant, or ramp)
    constant RAMP_DLY_ADDR      : t_param_id_address := x"1C"; -- Affects ramp_generator
    constant RAMP_AMP_ADDR      : t_param_id_address := x"1D"; -- Affects ramp_generator
    constant RAMP_STEP_ADDR     : t_param_id_address := x"1E"; -- Affects ramp_generator
    constant FB_CONST_ADDR      : t_param_id_address := x"1f"; -- Affects the feedback_setter. The values for constant feedback. SQ1??
    constant SAMPLE_DLY_ADDR    : t_param_id_address := x"32"; -- Affects sample_selector
    constant SAMPLE_NUM_ADDR    : t_param_id_address := x"33"; -- Affects sample_selector
    constant FB_DLY_ADDR        : t_param_id_address := x"34"; -- Affects feedback_setter
    constant FLTR_RST_ADDR      : t_param_id_address := x"14"; -- Affects butterworth_filter (direct). NOT IMPLEMENTED
    constant FILTR_COEFF_ADDR   : t_param_id_address := x"1a"; -- Affects butterworth_filter
    constant FLUX_FB_ADDR       : t_param_id_address := x"20"; -- Affects feedback_setter. SA feedback
    constant BIAS_ADDR          : t_param_id_address := x"21"; -- Affects bias_setter (TES bias)
    constant ROW_ORDER_ADDR     : t_param_id_address := x"01"; -- Affects row_selector
    constant ON_BIAS_ADDR       : t_param_id_address := x"02"; -- Affects row_activator
    constant OFF_BIAS_ADDR      : t_param_id_address := x"03"; -- Affects row_activator

    -- Number of words that the parameter occupies in the RAM memory
    constant PARAM_ID_TO_SIZE : array(0 to 255) of natural :=
        (
            ROW_LEN_ADDR        => 1,
            NUM_ROWS_ADDR       => 1,
            RET_DATA_S_ADDR     => 2,
            SA_BIAS_ADDR        => MAX_CHANNELS,
            SERVO_MODE_ADDR     => MAX_CHANNELS,
            RAMP_DLY_ADDR       => 1,
            RAMP_AMP_ADDR       => 1,
            RAMP_STEP_ADDR      => 1,
            FB_CONST_ADDR       => MAX_CHANNELS,
            SAMPLE_DLY_ADDR     => 1,
            SAMPLE_NUM_ADDR     => 1,
            FB_DLY_ADDR         => 1,
            FILTR_COEFF_ADDR    => IIR_FILTER_POLES * 2,
            FLUX_FB_ADDR        => MAX_ROWS,
            BIAS_ADDR           => MAX_CHANNELS,
            ROW_ORDER_ADDR      => MAX_ROWS,
            ON_BIAS_ADDR        => MAX_ROWS,
            OFF_BIAS_ADDR       => MAX_ROWS,
            (others => 0)
        );

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

    function get_param_id_from_half_word(param_id_h_word : t_half_word) return t_param_id is


end package body;
