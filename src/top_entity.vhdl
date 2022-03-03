library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library concept;
use concept.utils.all;

entity top_entity is
    generic (
        COLUMS_NUM     : positive := 8;
        ROWS_NUM       : positive := 25
    );
    port (
        Sys_Clock      : in  std_logic;
        Sys_Reset_in   : in  std_logic;
        
        row_sync        : in  std_logic;

--		b_coefficients  : in T_SIGNED_ARRAY_COEFFICIENTS;
--		a_coefficients  : in  T_SIGNED_ARRAY_COEFFICIENTS;
        
        --- Channel Operations ---
        CNV_IO0 : out std_logic; -- A->D conversion, normally high, pull for 30 ns to start conversion
        SCK_IO1 : out std_logic; -- A->D clock, 16 counts for 16 bits
        SDO_CH : in std_logic_vector(1 to COLUMS_NUM); -- A->D Data Input Channel 1 to 8
        
        LD_IO3: out std_logic; -- D->A conversion, time critical as it defines the new pixels must match D
        CS_IO4: out std_logic; -- D->A Chip Select. Active Low
        CK_IO5: out std_logic; -- D->A Clock. Active low, 18 pulses for 18 bits		
        SDI_CH: out std_logic_vector(1 to COLUMS_NUM); -- D->A Data Output Channel 1 to 8
        
        --- Row Operations --- 
        LD_IO7: out std_logic; -- D->A, time critical as it defines the new pixel must match D 
        CS_IO8: out std_logic; -- D->A, Chip Select active low (chip 1)
        CS_IO9: out std_logic; -- D->A, Chip Select active low (chip 2)
        CS_IO10: out std_logic; -- D->A, Chip Select active low (chip 3)
        CK_IO11: out std_logic; -- D->A Clock. 18 pulses for 18 bits
        SDI_IO12: out std_logic; -- D->A Data
        
        --- Bias Operations ---
        LD_IO13: out std_logic; -- D->A, time critical as it defines the new pixel
        CK_IO27: out std_logic; -- D->A, Chip Select active low
        CS_IO26: out std_logic; -- D->A Chip Clock for the channel D->A active low
        SDI_IO28: out std_logic; -- D->A Data
        
        START_CONV_ADC_CH_PULSE: in std_logic;
        START_CONV_DAC_CH_PULSE: in std_logic;
        
        valid_DAC: in std_logic;
        --DAC_data_Parallel: in std_logic_vector(17 downto 0);
        
        sw: in std_logic_vector(3 downto 0);
        LED: in std_logic_vector(5 downto 0);
        
        START_CONV_ADC_CH_PULSE_emulation: out std_logic;
        
        Clock_5mhz: out std_logic;
        Clock_100mhz: out std_logic;
        
        UART_TX: out std_logic		
     );
end entity;


architecture RTL of top_entity is
    
    signal row_num     : unsigned(7 downto 0) := (others => '0'); -- TODO FIXIT make width based on ROWS_NUM!
    signal cycle_num   : unsigned(7 downto 0);

    signal IIR_in_m2s  : T_AXIS_signed_m2s_ARRAY_COLUMNS;
    signal IIR_out_m2s : T_AXIS_signed_m2s_ARRAY_COLUMNS;
    signal START_CONV_ADC_CH_PULSE_reg : std_logic;
    
    signal START_CONV_DAC_CH_PULSE_CHANNELS_reg : std_logic;
    signal START_CONV_DAC_CH_PULSE_ROWSELECT_reg : std_logic;
    signal row_select : std_logic_vector(1 downto 0);
    signal START_CONV_DAC_CH_PULSE_TESBIAS_reg : std_logic;
    signal START_CONV_DAC_CH_PULSE_reg : std_logic;
    
    signal Sys_Clock_5mhz: std_logic;
    signal Sys_Clock_100mhz: std_logic;
    signal Sys_Clock_locked: std_logic;
    
    --- Channel Operations --- 
    signal CNV_IO0_signal : std_logic;   -- A->D conversion, normally high, pull for 30 ns to start conversion
    signal SCK_IO1_signal : std_logic;   -- A->D clock, 16 counts for 16 bits                                 
    signal SDO_CH_signal : std_logic_vector(1 to COLUMS_NUM);  -- A->D Data Output Channel                                
                                                                     
    signal CS_CHANNELS:  std_logic; -- D->A Chip Select. Active Low
    signal CK_CHANNELS:  std_logic; -- D->A Clock. Active low, 18 pulses for 18 bits	
    signal LD_CHANNELS:  std_logic;-- D->A conversion, time critical as it defines the new pixels must match D
    
    signal SDI_CH_signal: std_logic_vector(1 to COLUMS_NUM);  -- A->D Data Input Channel
    
    --- Row Operations --- 
    signal CS_ROWSELECT:  std_logic; -- D->A Chip Select. Active Low
    signal CK_ROWSELECT:  std_logic; -- D->A Clock. Active low, 18 pulses for 18 bits	
    signal LD_ROWSELECT:  std_logic;-- D->A conversion, time critical as it defines the new pixels must match D	                  
    signal SDI_IO12_signal: std_logic; -- D->A Data
    
    --- Bias Operations ---
    signal CS_TESBIAS:  std_logic; -- D->A Chip Select. Active Low
    signal CK_TESBIAS:  std_logic; -- D->A Clock. Active low, 18 pulses for 18 bits	
    signal LD_TESBIAS:  std_logic;-- D->A conversion, time critical as it defines the new pixels must match D  
    signal SDI_IO28_signal: std_logic; -- D->A Data
    
    type parallel_out_iddr_type is array(COLUMS_NUM downto 1) of std_logic_vector(1 downto 0);
    signal parallel_out_iddr: parallel_out_iddr_type;
    signal parallel_out_iddr_buffered: parallel_out_iddr_type;
    signal output_en: std_logic_vector(COLUMS_NUM downto 1);
    signal valid_bit_IDDR : std_logic_vector(COLUMS_NUM downto 1);
    signal valid_word_IDDR : std_logic_vector(COLUMS_NUM downto 1);
    type input_word_iddr_type is array(COLUMS_NUM downto 1) of std_logic_vector(15 downto 0);
    signal input_word_iddr: input_word_iddr_type; 
    type bits_counter_type is array(COLUMS_NUM downto 1) of unsigned(4 downto 0);
    signal bits_counter : bits_counter_type;
    
    signal b_coefficients : T_SIGNED_ARRAY_COEFFICIENTS;
    signal a_coefficients : T_SIGNED_ARRAY_COEFFICIENTS;
    
    signal counter_clocks : unsigned(7 downto 0);
    
    signal SEND_UART_signal: std_logic;    
    signal DATA_UART_signal: std_logic_vector(7 downto 0);     
    signal READY_UART_signal: std_logic;  
    signal UART_TX_UART_signal: std_logic;
    
    signal FRAME_STATUS_BIT4_ACTIVECLOCK_signal: std_logic;
    signal FRAME_STATUS_BIT16TO19_NUMCOLS_signal: std_logic_vector(3 downto 0);
    signal FRAME_STATUS_BIT20_DATATIMINGERROR_signal: std_logic;
    signal FRAME_HEADER_WORD2_ROWLEN_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_WORD3AND9_NUMROWS_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_WORD4_DATARATE_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_WORD5_CCARZCOUNTER_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_WORD6_HEADERVERSION_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_WORD7_RAMPVALUE_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_WORD8_RAMPCARD_ADDR_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_WORD12_USER_WORD_signal: std_logic_vector(31 downto 0);
    signal FRAME_HEADER_ERRNO_1_signal: std_logic_vector(31 downto 0);
    signal FRAME_FPGA_TEMP_signal: std_logic_vector(31 downto 0);
    signal FRAME_FIELDS_VALID_signal: std_logic;
    signal FRAME_DATA_signal: T_FRAME_DATA;   
    
    signal READY_signal: std_logic;
    
    signal valid_DAC_CHANNELS: std_logic;
    signal valid_DAC_ROWSELECT: std_logic;
    signal valid_DAC_TESBIAS: std_logic;
    
    signal sw_signal: std_logic_vector(3 downto 0);
    
    signal busy_flag_signal: std_logic;
    
    signal data_DAC_signal : std_logic_vector(17 downto 0);
    signal ready_DAC_signal_CHANNELS: std_logic;
    signal ready_DAC_signal_ROWSELECT: std_logic;
    signal ready_DAC_signal_TESBIAS: std_logic;       
    
    signal CS_ROWSELECTED1: std_logic;
    signal CS_ROWSELECTED2: std_logic;
    signal CS_ROWSELECTED3: std_logic;
    
    signal Sys_Reset_buf : std_logic;
    signal Sys_Reset : std_logic;
    
    signal conv_started : std_logic_vector(COLUMS_NUM downto 1);

    signal ADC_sim_SDO : std_logic;
                
--    attribute mark_debug : string;
--    attribute mark_debug of CNV_IO0_signal 		        : signal is "true";
--    attribute mark_debug of SCK_IO1_signal 		        : signal is "true";
--    attribute mark_debug of SDO_CH_signal 		        : signal is "true";
--    attribute mark_debug of START_CONV_ADC_CH_PULSE_reg : signal is "true";
--    attribute mark_debug of START_CONV_DAC_CH_PULSE_CHANNELS_reg : signal is "true";
--    attribute mark_debug of START_CONV_DAC_CH_PULSE_ROWSELECT_reg : signal is "true";
--    attribute mark_debug of START_CONV_DAC_CH_PULSE_TESBIAS_reg : signal is "true";
                                                    
--    --attribute mark_debug of SDI_CH_signal               : signal is "true";
--    --attribute mark_debug of SDO_CH_signal               : signal is "true";
    
--    attribute mark_debug of parallel_out_iddr           : signal is "true";
--    attribute mark_debug of parallel_out_iddr_buffered  : signal is "true";
    
--    attribute mark_debug of input_word_iddr             : signal is "true";
--    attribute mark_debug of bits_counter                : signal is "true";
--    attribute mark_debug of valid_word_IDDR             : signal is "true";
--    attribute mark_debug of valid_bit_IDDR              : signal is "true";
    
--    attribute mark_debug of IIR_in_m2s                  : signal is "true";
--    attribute mark_debug of IIR_out_m2s                 : signal is "true";
--    attribute mark_debug of Sys_Clock_100mhz            : signal is "true";
--    attribute mark_debug of Sys_Clock_5mhz              : signal is "true";
--    attribute mark_debug of row_num                     : signal is "true";
    
--    attribute mark_debug of SEND_UART_signal            : signal is "true";
--    attribute mark_debug of DATA_UART_signal            : signal is "true";
--    attribute mark_debug of READY_UART_signal           : signal is "true";
--    attribute mark_debug of UART_TX_UART_signal         : signal is "true";
    
--    COMPONENT vio_DAC IS
--        PORT (
--        clk : IN STD_LOGIC;
--        probe_out0 : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
--        );
--    END COMPONENT;

             
begin
    SDO_CH_signal <= SDO_CH;
    CNV_IO0 <= CNV_IO0_signal;
    SCK_IO1 <= SCK_IO1_signal;
    Clock_5mhz <= Sys_Clock_5mhz;
    Clock_100mhz <= Sys_Clock_100mhz;
    UART_TX <= UART_TX_UART_signal;
    
    CS_IO8 <= CS_ROWSELECTED1;
    CS_IO9 <= CS_ROWSELECTED2;
    CS_IO10 <= CS_ROWSELECTED3;
    
    CK_IO11 <= CK_ROWSELECT;
    SDI_IO12 <= SDI_IO12_signal;
    LD_IO7 <= LD_CHANNELS;

    LD_IO3 <= LD_CHANNELS;
    CS_IO4 <= CS_CHANNELS;
    CK_IO5 <= CK_CHANNELS;		
    SDI_CH <= SDI_CH_signal;
    
    LD_IO13 <= LD_TESBIAS;
    CK_IO27 <= CK_TESBIAS;
    CS_IO26 <= CS_TESBIAS;
    SDI_IO28 <= SDI_IO28_signal;
    
    START_CONV_DAC_CH_PULSE_CHANNELS_reg <= START_CONV_DAC_CH_PULSE_reg;
    START_CONV_DAC_CH_PULSE_ROWSELECT_reg <= START_CONV_DAC_CH_PULSE_reg;
    START_CONV_DAC_CH_PULSE_TESBIAS_reg <= START_CONV_DAC_CH_PULSE_reg;
    
    sw_signal <= sw;
    valid_DAC_CHANNELS <= valid_DAC;
    valid_DAC_ROWSELECT <= valid_DAC;
    valid_DAC_TESBIAS <= valid_DAC;
    
    --data_DAC_signal <= "001111111111111111"; --1
    --data_DAC_signal <= "000111111111111111"; --1/2
    data_DAC_signal <= "101001100000110111"; --1 --1/8 and 1st DAC
    
    busy_flag_signal <= '0';
    
 ---------------------------------------------------------------------
 -------------- FRAME ------------------------------------------------
 ---------------------------------------------------------------------
   FRAME_STATUS_BIT4_ACTIVECLOCK_signal <= '0';
   FRAME_STATUS_BIT16TO19_NUMCOLS_signal <= "1000";
   FRAME_STATUS_BIT20_DATATIMINGERROR_signal <= '0';
   FRAME_HEADER_WORD2_ROWLEN_signal <= X"00000000"; -- DEPENDS ON J AND I. TO BE LATER ADJUSTED.
   FRAME_HEADER_WORD3AND9_NUMROWS_signal <= X"00000100"; -- 256 rows
   FRAME_HEADER_WORD4_DATARATE_signal <= X"00000014"; -- 20 CYCLES. TO BE CONFIRMED LATER.
   FRAME_HEADER_WORD6_HEADERVERSION_signal <= (others => '0'); -- TO BE DEFINED
   FRAME_HEADER_WORD7_RAMPVALUE_signal <= (others => '0'); -- TO BE DEFINED
   FRAME_HEADER_WORD8_RAMPCARD_ADDR_signal <= (others => '0'); -- TO BE DEFINED
   FRAME_HEADER_WORD12_USER_WORD_signal <= (others => '0'); -- TO BE DEFINED
   FRAME_HEADER_ERRNO_1_signal <= (others => '0'); -- TO BE DEFINED
   FRAME_FPGA_TEMP_signal <= (others => '0'); -- TO BE DEFINED


 ---------------------------------------------------------------------
 ----------------- Clocked Reset -------------------------------------
 ---------------------------------------------------------------------
    process(Sys_Clock_100mhz) is
    begin
        if rising_edge(Sys_Clock_100mhz) then
            Sys_Reset_buf <= Sys_Reset_in;
            Sys_Reset <= Sys_Reset_buf;
        end if;
    end process;


    
 ---------------------------------------------------------------------
 ----------------- Loopback Emulation signals ------------------------
 ---------------------------------------------------------------------
     
--	process(Sys_Clock_100mhz) is
--	begin
--        if (Sys_Reset = '1') then
--            START_CONV_ADC_CH_PULSE_emulation <= '0';
--        elsif rising_edge(Sys_Clock_100mhz) then
--            counter_clocks <= counter_clocks + 1;
--            if counter_clocks = 19 then
--                START_CONV_ADC_CH_PULSE_emulation <= '1';
--                counter_clocks <= (others => '0');                               
--            end if;
--            if START_CONV_ADC_CH_PULSE_emulation = '1' then
--                START_CONV_ADC_CH_PULSE_emulation <= '0';
--            end if;
--        end if;
--	end process;

----------------------------------------------------------------------
------------------ Row select ----------------------------------------
----------------------------------------------------------------------

 process(Sys_Clock_100mhz) is
    begin
        if rising_edge(Sys_Clock_100mhz) then
            if (Sys_Reset = '1') then
                row_num <= (others => '0');
                cycle_num <= (others => '0');
                FRAME_FIELDS_VALID_signal <= '0';
            else
                -- shift upon sync
                if (row_sync = '1') then
                    if (row_num >= ROWS_NUM - 1) then
                        row_num <= (others => '0');
                        cycle_num <= cycle_num + 1;
                        if cycle_num = 20 then
                            FRAME_FIELDS_VALID_signal <= '1';
                        end if;
                    else
                        row_num <= row_num + 1;
                    end if;
                end if;
            
            if FRAME_FIELDS_VALID_signal = '1' then
                FRAME_FIELDS_VALID_signal <= '0';
            end if;
            
            end if;
        end if;
    end process;

---------------------------------------------------------------------
---------------- Clock Distribution ---------------------------------
---------------------------------------------------------------------

    clock_distr: entity concept.clock_distribution
        port map(
            clock_in   => Sys_Clock,
            clock_005  => Sys_Clock_5mhz,
            clock_100  => Sys_Clock_100mhz,
            locked     => Sys_Clock_locked
        );

----------------------------------------------------------------------
---------------- 8 CHANNELS ------------------------------------------
----------------------------------------------------------------------

    ADC_simulator : entity concept.ADC_simulator
        port map(
            clk     => Sys_Clock_100mhz,
            nrst    => Sys_Reset,
            nCNV    => CNV_IO0_signal,
            SCK     => SCK_IO1_signal,
            SDO     => ADC_sim_SDO
        );

    colums_loop : for i in 1 to COLUMS_NUM generate

        ddr_input : entity concept.ddr_input
            port map (
                clock           => SCK_IO1_signal,
                reset           => Sys_Reset,
                output_en       => open,
                -- ddr_in          => SDO_CH_signal(i),
                ddr_in          => ADC_sim_SDO,
                parallel_out    => parallel_out_iddr(i)(1 downto 0)
            );
            
        fall_edge_detector_SCLK : entity concept.FallEdgeDetector
            port map (
                clk             => Sys_Clock_100mhz,
                rst             => Sys_Reset,
                signal_in       => SCK_IO1_signal,
                signal_out      => valid_bit_IDDR(i)
            );
        fall_edge_detector_CNV : entity concept.FallEdgeDetector
            port map (
                clk             => Sys_Clock_100mhz,
                rst             => Sys_Reset,
                signal_in       => CNV_IO0_signal,
                signal_out      => conv_started(i)
            );

        input_shift_register : entity concept.input_shift_register
            port map(
                clk                     => Sys_Clock_100mhz,
                nrst                    => Sys_Reset,
                serial_clk              => SCK_IO1_signal,
                iddr_parallel_output    => parallel_out_iddr(i),
                conv_started            => conv_started(i),
                valid_word              => valid_word_IDDR(i),
                parallel_data           => input_word_iddr(i)
            );
            
        IIR_in_m2s(i).Data  <= signed(input_word_iddr(i));
        IIR_in_m2s(i).Valid <= valid_word_IDDR(i);
        IIR_in_m2s(i).User  <= row_num;

        IIR_inst : entity concept.IIR_transposed
            generic map(
                BUFF_ELEMENTS  => ROWS_NUM
            )
            port map(
                Clock          => Sys_Clock_5mhz,
                Reset          => Sys_Reset,
                IIR_in_m2s     => IIR_in_m2s(i),
                IIR_out_m2s    => IIR_out_m2s(i),
                b_coefficients => b_coefficients,
                a_coefficients => a_coefficients
            );
    end generate;
    
----------------------------------------------------------------------	
-----------------  SPI DACs and ADCs ---------------------------------
----------------------------------------------------------------------
    
    ADC_controller : entity concept.ADC_controller
        port map(
            clk             => Sys_Clock_100mhz,
            nrst            => Sys_Reset,
            CNV             => CNV_IO0_signal,
            SCLK            => SCK_IO1_signal,
            start_pulse     => START_CONV_ADC_CH_PULSE_reg
        );
        
    DAC_controller_channels: entity concept.DAC_controller
        port map(
            clock               => Sys_Clock_100mhz,
            rst                 => Sys_Reset,
            start_conv_pulse    => START_CONV_DAC_CH_PULSE_CHANNELS_reg,
            CS                  => CS_CHANNELS,
            CLK                 => CK_CHANNELS,
            LDAC                => LD_CHANNELS
        );
        
    row_select <= "11";
        process(Sys_Clock_100mhz) is
            begin
                if (Sys_Reset = '1') then
                elsif rising_edge(Sys_Clock_100mhz) then
                    if row_select = "00" then
                        CS_ROWSELECTED1 <= CS_ROWSELECT;
                        CS_ROWSELECTED2 <= '1';
                        CS_ROWSELECTED3 <= '1';                        
                    elsif row_select = "01" then
                        CS_ROWSELECTED1 <= '1';
                        CS_ROWSELECTED2 <= CS_ROWSELECT;
                        CS_ROWSELECTED3 <= '1'; 
                    elsif row_select = "10" then
                        CS_ROWSELECTED1 <= '1';
                        CS_ROWSELECTED2 <= '1';
                        CS_ROWSELECTED3 <= CS_ROWSELECT;
                    elsif row_select = "11" then
                        CS_ROWSELECTED1 <= CS_ROWSELECT;
                        CS_ROWSELECTED2 <= CS_ROWSELECT;
                        CS_ROWSELECTED3 <= CS_ROWSELECT;    
                    end if;
             end if;
        end process;
    
        
    DAC_controller_row_select: entity concept.DAC_controller
        port map(
            clock               => Sys_Clock_100mhz,
            rst                 => Sys_Reset,
            start_conv_pulse    => START_CONV_DAC_CH_PULSE_ROWSELECT_reg,
            CS                  => CS_ROWSELECT,
            CLK                 => CK_ROWSELECT,
            LDAC                => LD_ROWSELECT
        );
        
     DAC_controller_tesbias: entity concept.DAC_controller
        port map(
            clock               => Sys_Clock_100mhz,
            rst                 => Sys_Reset,
            start_conv_pulse    => START_CONV_DAC_CH_PULSE_TESBIAS_reg,
            CS                  => CS_TESBIAS,
            CLK                 => CK_TESBIAS,
            LDAC                => LD_TESBIAS
        );
        
     data_serializer_wrapper_channel1: entity concept.data_serializer_wrapper
        port map(
            clk                 => Sys_Clock_100mhz,
            rst                 => Sys_Reset,
            gate_read           => CS_CHANNELS,
            data_clk            => CK_CHANNELS,
            valid               => valid_DAC_CHANNELS,
            parallel_data       => data_DAC_signal,
                
            ready               => ready_DAC_signal_CHANNELS,
            serial_data         => SDI_CH_signal(1),
            busy_flag           => busy_flag_signal
            );
            
     data_serializer_wrapper_channel2: entity concept.data_serializer_wrapper
        port map(
            clk                 => Sys_Clock_100mhz,
            rst                 => Sys_Reset,
            gate_read           => CS_CHANNELS,
            data_clk            => CK_CHANNELS,
            valid               => valid_DAC_CHANNELS,
            parallel_data       => data_DAC_signal,
                
            ready               => ready_DAC_signal_CHANNELS,
            serial_data         => SDI_CH_signal(2),
            busy_flag           => busy_flag_signal
            );
            
      data_serializer_wrapper_row_select: entity concept.data_serializer_wrapper
        port map(
            clk                 => Sys_Clock_100mhz,
            rst                 => Sys_Reset,
            gate_read           => CS_ROWSELECT,
            data_clk            => CK_ROWSELECT,
            valid               => valid_DAC_ROWSELECT,
            parallel_data       => data_DAC_signal,
                
            ready               => ready_DAC_signal_ROWSELECT,
            serial_data         => SDI_IO12_signal,
            busy_flag           => busy_flag_signal
            );
            
      data_serializer_wrapper_tesbias: entity concept.data_serializer_wrapper
        port map(
            clk                 => Sys_Clock_100mhz,
            rst                 => Sys_Reset,
            gate_read           => CS_TESBIAS,
            data_clk            => CK_TESBIAS,
            valid               => valid_DAC_TESBIAS,
            parallel_data       => data_DAC_signal,
            busy_flag           => busy_flag_signal,
                
            ready               => ready_DAC_signal_TESBIAS,
            serial_data              => SDI_IO28_signal
            );      
            
            
       rise_edge_detector_DAC : entity concept.RiseEdgeDetector
         port map (
            clk         => Sys_Clock_100mhz,
            rst         => Sys_Reset,
            signal_in   => START_CONV_DAC_CH_PULSE,
            signal_out  => START_CONV_DAC_CH_PULSE_reg
            );
            
       rise_edge_detector_ADC : entity concept.RiseEdgeDetector
         port map (
            clk         => Sys_Clock_100mhz,
            rst         => Sys_Reset,
            signal_in   => START_CONV_ADC_CH_PULSE,
            signal_out  => START_CONV_ADC_CH_PULSE_reg
            );         

----------------------------------------------------------------------
---------------- FRAME BUILDER ---------------------------------------
----------------------------------------------------------------------

FRAME_BUILDER: entity concept.FRAME_BUILDER
    port map(
           Sys_Clock_100mhz => Sys_Clock_100mhz,
           Sys_Reset => Sys_Reset,
           
           FRAME_STATUS_BIT4_ACTIVECLOCK => FRAME_STATUS_BIT4_ACTIVECLOCK_signal,
           FRAME_STATUS_BIT16TO19_NUMCOLS => FRAME_STATUS_BIT16TO19_NUMCOLS_signal,
           FRAME_STATUS_BIT20_DATATIMINGERROR => FRAME_STATUS_BIT20_DATATIMINGERROR_signal, 
           FRAME_HEADER_WORD2_ROWLEN => FRAME_HEADER_WORD2_ROWLEN_signal,
           FRAME_HEADER_WORD3AND9_NUMROWS => FRAME_HEADER_WORD3AND9_NUMROWS_signal,
           FRAME_HEADER_WORD4_DATARATE => FRAME_HEADER_WORD4_DATARATE_signal,
           FRAME_HEADER_WORD6_HEADERVERSION => FRAME_HEADER_WORD6_HEADERVERSION_signal,
           FRAME_HEADER_WORD7_RAMPVALUE => FRAME_HEADER_WORD7_RAMPVALUE_signal,
           FRAME_HEADER_WORD8_RAMPCARD_ADDR => FRAME_HEADER_WORD8_RAMPCARD_ADDR_signal,
           FRAME_HEADER_WORD12_USER_WORD => FRAME_HEADER_WORD12_USER_WORD_signal,
           FRAME_HEADER_ERRNO_1 => FRAME_HEADER_ERRNO_1_signal,
           FRAME_FPGA_TEMP => FRAME_FPGA_TEMP_signal,
           FRAME_FIELDS_VALID => FRAME_FIELDS_VALID_signal,
           FRAME_DATA => FRAME_DATA_signal,
           
           DATA => DATA_UART_signal,
           DATA_VALID => SEND_UART_signal,
           
           -- READY FLAG --
           READY => READY_signal
     );
     
----------------------------------------------------------------------
---------------- UART TX ---------------------------------------------
        
UART_TX_CTRL: entity concept.UART_TX_CTRL
    port map(
           SEND => SEND_UART_signal,
           DATA => DATA_UART_signal,
           CLK => Sys_Clock_100mhz,
           READY => READY_UART_signal,
           UART_TX => UART_TX_UART_signal
    );
    
--vio_DAC1: vio_DAC
--    port map(
--        clk => Sys_Clock_100mhz,
--        probe_out0 => data_DAC_signal
--    );
    
end architecture;
