library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

package utils is

    -- Basic constraints
    constant MAX_CHANNELS           : natural := 2; -- Max channels that the daughter board can handle
    constant MAX_ROWS               : natural := 12; -- Max rows that the daughter board can handle
    constant IIR_FILTER_POLES       : natural := 4; -- This will define the depth of the buffers and the size of the coef arrays
    constant DATA_PKT_HEADER_LENGTH : natural := 43;
    
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

    constant CMD_REPLY_MAX_SIZE : natural := 58;

    type t_packet_type is (cmd_rb, cmd_wb, cmd_go, cmd_st, cmd_rs, reply, data, undefined);

    -- Data structures for ADC reading
    subtype t_adc_sample is std_logic_vector(15 downto 0);

    -- Data structure for param buffers
    type t_param_array is array(natural range<>) of t_word;
    
    -- Channel data record (reduced for usecase)
    type t_channel_record is record
        value   : t_word;
        row_num : natural range 0 to MAX_ROWS;
        valid   : std_logic;
    end record;

    type t_channel_record_array is array(0 to MAX_CHANNELS - 1) of t_channel_record;

    ----------------------------------------------------------------
    -- Constants
    ----------------------------------------------------------------



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


    -- This card ID
    constant DAUGHTER_CARD_ID : t_half_word := x"ffff";


    -- The params id (MCE based)
    constant ROW_ORDER_ID       : natural := 1;  -- (0x01) Affects row_selector
    constant ON_BIAS_ID         : natural := 2;  -- (0x02) Affects row_activator
    constant OFF_BIAS_ID        : natural := 3;  -- (0x03) Affects row_activator
    constant SA_BIAS_ID         : natural := 16; -- (0x10) Affects channels controller (SA bias)
    constant FLTR_RST_ID        : natural := 20; -- (0x14) Affects butterworth_filter (direct). NOT IMPLEMENTED
    constant RET_DATA_ID        : natural := 22; -- (0x16) Start Acquisition
    constant DATA_MODE_ID       : natural := 23; -- (0x17) Affects channels controller
    constant FILTR_COEFF_ID     : natural := 26; -- (0x1A) Affects butterworth_filter
    constant SERVO_MODE_ID      : natural := 27; -- (0x1B) Affects channels controlller (can get values from feedback calculator, constant, or ramp)
    constant RAMP_DLY_ID        : natural := 28; -- (0x1C) Affects ramp_generator
    constant RAMP_AMP_ID        : natural := 29; -- (0x1D) Affects ramp_generator
    constant RAMP_STEP_ID       : natural := 30; -- (0x1E) Affects ramp_generator
    --constant FB_CONST_ID        : natural := 31; -- (0x1F) Affects channels controller (SQ1 FB)
    --constant FLUX_FB_ID         : natural := 32; -- (0x20) Affects channels controller. SF, SB, FF, FB
    constant BIAS_ID            : natural := 33; -- (0x21) Affects bias_setter (TES bias)
    constant ROW_LEN_ID         : natural := 48; -- (0x30) Affects row_selector (how many pulses to spend on each row)
    constant NUM_ROWS_ID        : natural := 49; -- (0x31) Affects row_selector (to cycle #num_rows)
    constant SAMPLE_DLY_ID      : natural := 50; -- (0x32) Affects sample_selector
    constant SAMPLE_NUM_ID      : natural := 51; -- (0x33) Affects sample_selector
    constant FB_DLY_ID          : natural := 52; -- (0x34) Affects feedback_setter
    constant RET_DATA_S_ID      : natural := 83; -- (0x53) Affects the data_frame_builder (num in header)
    constant ADC_OFFSET_0_ID    : natural := 104; -- (0x68) ADC offset for column 0 (different gain for each row)
    constant ADC_OFFSET_1_ID    : natural := 105; -- (0x68) ADC offset for column 1 (different gain for each row)
    constant GAIN_0_ID          : natural := 120; -- (0x78) Gain for column 0 (different gain for each row)
    constant GAIN_1_ID          : natural := 121; -- (0x78) Gain for column 1 (different gain for each row)
    constant DATA_RATE_ID       : natural := 160; -- (0xA0) Affects the data_frame_builder
    constant NUM_COLS_REP_ID    : natural := 173; -- (0xAD) Affects frame builder. (num of columns to be reported)
    -- Custom params
    constant SA_FB_ID           : natural := 249; -- (0xF9) Affects channels controller (CUSTOM)
    constant SQ1_BIAS_ID        : natural := 250; -- (0xFA) Affects channels controller (CUSTOM)
    constant SQ1_FB_ID          : natural := 251; -- (0xFB) Affects channels controller (CUSTOM)
    constant CNV_LEN_ID         : natural := 252; -- (0xFC) Affects ADC gate controller (CUSTOM)
    constant SCK_DLY_ID         : natural := 253; -- (0xFD) Affects ADC gate controller (CUSTOM)
    constant SCK_HALF_PERIOD_ID : natural := 254; -- (0xFE) Affects ADC gate controller (CUSTOM)


    -- Number of words that the parameter occupies in the RAM memory
    type t_param_id_to_size is array (0 to 255) of natural;
    constant PARAM_ID_TO_SIZE : t_param_id_to_size :=
     (
            ROW_ORDER_ID        => MAX_ROWS,
            ON_BIAS_ID          => MAX_ROWS,
            OFF_BIAS_ID         => MAX_ROWS,
            SA_BIAS_ID          => MAX_CHANNELS,
            FLTR_RST_ID         => 1,
            RET_DATA_ID         => 1,
            DATA_MODE_ID        => 1,
            FILTR_COEFF_ID      => IIR_FILTER_POLES * 2,
            SERVO_MODE_ID       => MAX_CHANNELS,
            RAMP_DLY_ID         => 1,
            RAMP_AMP_ID         => 1,
            RAMP_STEP_ID        => 1,
            --FB_CONST_ID       => MAX_CHANNELS,
            --FLUX_FB_ID        => MAX_ROWS,
            BIAS_ID             => 4,
            ROW_LEN_ID          => 1,
            NUM_ROWS_ID         => 1,
            SAMPLE_DLY_ID       => 1,
            SAMPLE_NUM_ID       => 1,
            FB_DLY_ID           => 1,
            RET_DATA_S_ID       => 2,
            ADC_OFFSET_0_ID     => MAX_ROWS,
            ADC_OFFSET_1_ID     => MAX_ROWS,
            GAIN_0_ID           => MAX_ROWS,
            GAIN_1_ID           => MAX_ROWS,
            DATA_RATE_ID        => 1,
            NUM_COLS_REP_ID     => 1,
            SA_FB_ID            => MAX_CHANNELS,
            SQ1_BIAS_ID         => MAX_CHANNELS,
            SQ1_FB_ID           => MAX_CHANNELS,
            CNV_LEN_ID          => 1,
            SCK_DLY_ID          => 1,
            SCK_HALF_PERIOD_ID  => 1,
            others              => 0
        );

    -- Addresses of the params in the RAM
    type t_param_id_to_addr is array (0 to 255) of natural;
    constant PARAM_ID_TO_ADDR : t_param_id_to_addr :=
    (
        ROW_ORDER_ID        => 0  * MAX_ROWS,
        ON_BIAS_ID          => 1  * MAX_ROWS,
        OFF_BIAS_ID         => 2  * MAX_ROWS,
        SA_BIAS_ID          => 3  * MAX_ROWS,
        FLTR_RST_ID         => 4  * MAX_ROWS,
        RET_DATA_ID         => 5  * MAX_ROWS,
        FILTR_COEFF_ID      => 6  * MAX_ROWS,
        SERVO_MODE_ID       => 7  * MAX_ROWS,
        RAMP_DLY_ID         => 8  * MAX_ROWS,
        RAMP_AMP_ID         => 9  * MAX_ROWS,
        RAMP_STEP_ID        => 10 * MAX_ROWS,
        --FB_CONST_ID       => 0 * MAX_ROWS,
        --FLUX_FB_ID        => 0 * MAX_ROWS,
        BIAS_ID             => 11 * MAX_ROWS,
        ROW_LEN_ID          => 12 * MAX_ROWS,
        NUM_ROWS_ID         => 13 * MAX_ROWS,
        SAMPLE_DLY_ID       => 14 * MAX_ROWS,
        SAMPLE_NUM_ID       => 15 * MAX_ROWS,
        FB_DLY_ID           => 16 * MAX_ROWS,
        RET_DATA_S_ID       => 17 * MAX_ROWS,
        ADC_OFFSET_0_ID     => 18 * MAX_ROWS,
        ADC_OFFSET_1_ID     => 19 * MAX_ROWS,
        GAIN_0_ID           => 20 * MAX_ROWS,
        GAIN_1_ID           => 21 * MAX_ROWS,
        DATA_RATE_ID        => 22 * MAX_ROWS,
        NUM_COLS_REP_ID     => 23 * MAX_ROWS,
        SA_FB_ID            => 24 * MAX_ROWS,
        SQ1_BIAS_ID         => 25 * MAX_ROWS,
        SQ1_FB_ID           => 26 * MAX_ROWS,
        CNV_LEN_ID          => 27 * MAX_ROWS,
        SCK_DLY_ID          => 28 * MAX_ROWS,
        SCK_HALF_PERIOD_ID  => 29 * MAX_ROWS,
        others              => 0
    );

-- Default values for params
    constant ON_BIAS_DEF            : t_param_array(0 to PARAM_ID_TO_SIZE(ON_BIAS_ID) - 1) := (others => (others => '1'));
    constant OFF_BIAS_DEF           : t_param_array(0 to PARAM_ID_TO_SIZE(OFF_BIAS_ID) - 1) := (others => (others => '0'));
    constant SA_BIAS_DEF            : t_param_array(0 to PARAM_ID_TO_SIZE(SA_BIAS_ID) - 1) := (others => (others => '0'));
    constant ROW_LEN_DEF            : t_param_array(0 to PARAM_ID_TO_SIZE(ROW_LEN_ID) - 1) := (0 => std_logic_vector(to_unsigned(50, t_word'length)));
    constant NUM_ROWS_DEF           : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_ROWS_ID) - 1) := (0 => std_logic_vector(to_unsigned(MAX_ROWS, t_word'length)));
    constant SAMPLE_DLY_DEF         : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_DLY_ID) - 1) := (0 => std_logic_vector(to_unsigned(25, t_word'length)));
    constant SAMPLE_NUM_DEF         : t_param_array(0 to PARAM_ID_TO_SIZE(SAMPLE_NUM_ID) - 1) := (0 => std_logic_vector(to_unsigned(15, t_word'length)));
    constant FB_DLY_DEF             : t_param_array(0 to PARAM_ID_TO_SIZE(FB_DLY_ID) - 1) := (0 => std_logic_vector(to_unsigned(23, t_word'length)));
    constant GAIN_0_DEF             : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_0_ID) - 1) := (others => std_logic_vector(to_signed(-3, t_word'length)));
    constant GAIN_1_DEF             : t_param_array(0 to PARAM_ID_TO_SIZE(GAIN_1_ID) - 1) := (others => std_logic_vector(to_signed(-2, t_word'length)));
    constant DATA_RATE_DEF          : t_param_array(0 to PARAM_ID_TO_SIZE(DATA_RATE_ID) - 1) := (0 => std_logic_vector(to_unsigned(2, t_word'length)));
    constant NUM_COLS_REP_DEF       : t_param_array(0 to PARAM_ID_TO_SIZE(NUM_COLS_REP_ID) - 1) := (0 => std_logic_vector(to_unsigned(1, t_word'length)));
    constant CNV_LEN_DEF            : t_param_array(0 to PARAM_ID_TO_SIZE(CNV_LEN_ID) - 1) := (0 => std_logic_vector(to_unsigned(3, t_word'length)));
    constant SCK_DLY_DEF            : t_param_array(0 to PARAM_ID_TO_SIZE(SCK_DLY_ID) - 1) := (0 => std_logic_vector(to_unsigned(1, t_word'length)));
    constant SCK_HALF_PERIOD_DEF    : t_param_array(0 to PARAM_ID_TO_SIZE(SCK_HALF_PERIOD_ID) - 1) := (0 => std_logic_vector(to_unsigned(1, t_word'length)));


    -- The possible servo modes
    constant SERVO_MODE_CONST   : natural := 0;
    constant SERVO_MODE_RAMP    : natural := 2;
    constant SERVO_MODE_PID     : natural := 3;

    -- The possible data modes
    constant DATA_MODE_ERROR    : natural := 0;
    constant DATA_MODE_FB       : natural := 1;
    constant DATA_MODE_FILT_FB  : natural := 2;
    constant DATA_MODE_RAW      : natural := 3;

    -- The possible reply errors
    constant ERROR_GO_WITH_NO_SETUP     : t_word := x"00000001";
    constant ERROR_INCORRECT_PARAM_ID   : t_word := x"00000002";
    constant ERROR_INCORRECT_PARAM_SIZE : t_word := x"00000003";
    constant ERROR_ST_WITH_NO_ACQ       : t_word := x"00000004";

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
