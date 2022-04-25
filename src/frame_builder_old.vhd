----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Iban Ibanez, Albert Risco
-- 
-- Create Date: 04.21.2020
-- Module Name: frame_builder.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of generating each of the bytes of the different frames in the communication
--              between the MATESSE board and the external PC. It is able to produce 3 different types of frames:
--              commands, replies and data frames.

-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

library concept;
use     concept.utils.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FRAME_BUILDER is
    port ( clk :  in  STD_LOGIC;
           rst: in  std_logic;
           
           -- FRAME FIELDS --
           FRAME_STATUS_BIT4_ACTIVECLOCK: in  std_logic;
           FRAME_STATUS_BIT16TO19_NUMCOLS: in  std_logic_vector(3 downto 0);
           FRAME_STATUS_BIT20_DATATIMINGERROR: in  std_logic;
           FRAME_HEADER_WORD2_ROWLEN: in std_logic_vector(31 downto 0);
           FRAME_HEADER_WORD3AND9_NUMROWS: in std_logic_vector(31 downto 0);
           FRAME_HEADER_WORD4_DATARATE: in std_logic_vector(31 downto 0);
           FRAME_HEADER_WORD6_HEADERVERSION: in std_logic_vector(31 downto 0);
           FRAME_HEADER_WORD7_RAMPVALUE: in std_logic_vector(31 downto 0);
           FRAME_HEADER_WORD8_RAMPCARD_ADDR: in std_logic_vector(31 downto 0);
           FRAME_HEADER_WORD12_USER_WORD: in std_logic_vector(31 downto 0);
           FRAME_HEADER_ERRNO_1: in std_logic_vector(31 downto 0);
           FRAME_FPGA_TEMP: in std_logic_vector(31 downto 0);
           FRAME_FIELDS_VALID : in std_logic;
           FRAME_DATA: in T_FRAME_DATA;
           
           -- DATA WORD VALID --
           DATA : out  STD_LOGIC_VECTOR (7 downto 0);
           DATA_VALID : out  STD_LOGIC;
           
           -- READY FLAG --
           READY : out  std_logic);
end FRAME_BUILDER;

architecture Behavioral of FRAME_BUILDER is

    signal FRAME_HEADER_signal      : T_FRAME_HEADER;
    signal FRAME_DATA_signal        : T_FRAME_DATA;
    signal CC_Frame_counter         : unsigned(31 downto 0);
    signal START_UART_DATA_TX       : std_logic;
    signal UART_TRANSMITTING        : std_logic;
    signal CLOCK_BIT_COUNTER        : unsigned(3 downto 0); -- There are 8 bits for each UART Word to count. Counter up to 2^4 = 16.
    signal DATA_UART_WORD_COUNTER   : unsigned(2 downto 0); -- There are 4 UART Words for each Frame word to count. Counter up to 2^3 = 8.
    signal DATA_FRAME_WORD_COUNTER  : unsigned(8 downto 0); -- There are 43 + 255 + 1 = 300 Frame Words to count. Counter up to 2^9 = 512.
    signal DATA_VALID_signal        : std_logic;
    signal DATA_signal              : std_logic_vector(7 downto 0);
    signal DATA_COLUMN_COUNTER      : unsigned(3 downto 0); -- There are 8 Columns to count. Counter up to 2^4 = 16.
    signal DATA_ROW_COUNTER         : unsigned(8 downto 0); -- There are 256 Rows to count. Counter up to 2^9 = 512.
    signal TRANSMITTING_CHECKSUM    : std_logic;
    constant NUM_ROWS               : integer := 256;
    signal CHECKSUM                 : std_logic_vector(31 downto 0);
begin

 ---------------------------------------------------------------------
 ----------------- Loopback Emulation signals ------------------------
 ---------------------------------------------------------------------
 	
 	DATA_VALID <= DATA_VALID_signal; 
    DATA <= DATA_signal;
    READY <= not UART_TRANSMITTING;
 	
	process(clk, rst) is
	begin
        if (rst = '1') then
            FRAME_HEADER_signal <= (others => (others => '0'));
            FRAME_DATA_signal <= (others => (others => (others => '0')));
            CC_Frame_counter <= (others => '0');
            START_UART_DATA_TX <= '0';
            UART_TRANSMITTING <= '0';
            CLOCK_BIT_COUNTER <= (others => '0');
            DATA_UART_WORD_COUNTER <= (others => '0');
            DATA_VALID_signal <= '0';
            DATA_signal <= (others => '0');
            DATA_FRAME_WORD_COUNTER <= (others => '0');
            DATA_COLUMN_COUNTER <= (others => '0');
            DATA_ROW_COUNTER <= (others => '0');
            CHECKSUM <= (others => '0');
            TRANSMITTING_CHECKSUM <= '0';
        elsif rising_edge(clk) then
        
            -- Set fields values --
            if FRAME_FIELDS_VALID = '1' then
                FRAME_HEADER_signal(0)  <= "00000000000" & FRAME_STATUS_BIT20_DATATIMINGERROR & FRAME_STATUS_BIT16TO19_NUMCOLS & "00000000000" & FRAME_STATUS_BIT4_ACTIVECLOCK & "0000";
		        FRAME_HEADER_signal(1)  <= std_logic_vector(CC_Frame_counter);
		        FRAME_HEADER_signal(2)  <= FRAME_HEADER_WORD2_ROWLEN;
		        FRAME_HEADER_signal(3)  <= FRAME_HEADER_WORD3AND9_NUMROWS;
		        FRAME_HEADER_signal(4)  <= FRAME_HEADER_WORD4_DATARATE;
		        FRAME_HEADER_signal(5)  <= (others => '0'); --- TO BE ADJUSTED
		        FRAME_HEADER_signal(6)  <= FRAME_HEADER_WORD6_HEADERVERSION;
		        FRAME_HEADER_signal(7)  <= FRAME_HEADER_WORD7_RAMPVALUE;
		        FRAME_HEADER_signal(8)  <= FRAME_HEADER_WORD8_RAMPCARD_ADDR;
		        FRAME_HEADER_signal(9)  <= FRAME_HEADER_WORD3AND9_NUMROWS;
		        FRAME_HEADER_signal(10) <= (others => '0');
		        FRAME_HEADER_signal(11) <= (others => '0');
		        FRAME_HEADER_signal(12) <= FRAME_HEADER_WORD12_USER_WORD;
		        FRAME_HEADER_signal(13) <= FRAME_HEADER_ERRNO_1;
		        FRAME_HEADER_signal(14) <= (others => '0');
		        FRAME_HEADER_signal(15) <= (others => '0');
		        FRAME_HEADER_signal(16) <= (others => '0');
		        FRAME_HEADER_signal(17) <= (others => '0');
		        FRAME_HEADER_signal(18) <= (others => '0');
		        FRAME_HEADER_signal(19) <= (others => '0');
		        FRAME_HEADER_signal(20) <= (others => '0');
		        FRAME_HEADER_signal(21) <= (others => '0');
		        FRAME_HEADER_signal(22) <= (others => '0');
		        FRAME_HEADER_signal(23) <= (others => '0');
		        FRAME_HEADER_signal(24) <= (others => '0');
		        FRAME_HEADER_signal(25) <= (others => '0');
		        FRAME_HEADER_signal(26) <= (others => '0');
		        FRAME_HEADER_signal(27) <= (others => '0');
		        FRAME_HEADER_signal(28) <= (others => '0');
		        FRAME_HEADER_signal(29) <= (others => '0');
		        FRAME_HEADER_signal(30) <= (others => '0');
		        FRAME_HEADER_signal(31) <= (others => '0');
		        FRAME_HEADER_signal(32) <= (others => '0');
		        FRAME_HEADER_signal(33) <= (others => '0');
		        FRAME_HEADER_signal(34) <= (others => '0');
		        FRAME_HEADER_signal(35) <= (others => '0');
		        FRAME_HEADER_signal(36) <= (others => '0');
		        FRAME_HEADER_signal(37) <= (others => '0');
		        FRAME_HEADER_signal(38) <= (others => '0');
		        FRAME_HEADER_signal(39) <= (others => '0');
		        FRAME_HEADER_signal(40) <= (others => '0');
		        FRAME_HEADER_signal(41) <= (others => '0');
		        FRAME_HEADER_signal(42) <= FRAME_FPGA_TEMP;
		        
		        CC_Frame_counter <= CC_Frame_counter + 1;
		        START_UART_DATA_TX <= '1';   
		    end if;
		    
		    -- Reset UART Start transmission pulse 
		    if START_UART_DATA_TX = '1' then
		        START_UART_DATA_TX <= '0';
		        UART_TRANSMITTING <= '1';
		    end if;
		    
		    -- Transmission in UART --
		    if UART_TRANSMITTING = '1' then
		       CLOCK_BIT_COUNTER <= CLOCK_BIT_COUNTER + 1;
		       
		       if CLOCK_BIT_COUNTER = 8 then
		          CLOCK_BIT_COUNTER <= (others => '0');
		          DATA_UART_WORD_COUNTER <= DATA_UART_WORD_COUNTER + 1;
		          
		          -- COUNTERS WORDS, FRAMES, HEADER, DATA and CHECKSUM --
                  if DATA_UART_WORD_COUNTER = 3 then
                     DATA_UART_WORD_COUNTER <= (others => '0');
                     DATA_FRAME_WORD_COUNTER <= DATA_FRAME_WORD_COUNTER + 1;
                     if DATA_FRAME_WORD_COUNTER >= FRAME_HEADER_signal'length and DATA_FRAME_WORD_COUNTER < FRAME_HEADER_signal'length + NUM_ROWS + 1 then
                         DATA_ROW_COUNTER <= DATA_ROW_COUNTER + 1;
                         if DATA_ROW_COUNTER = NUM_ROWS-1 then
                             DATA_ROW_COUNTER <= (others => '0');
                             --DATA_FRAME_WORD_COUNTER <= (others => '0');
                             DATA_COLUMN_COUNTER <= DATA_COLUMN_COUNTER + 1;
                             if DATA_COLUMN_COUNTER = 7 then
                                TRANSMITTING_CHECKSUM <= '1';
                                DATA_COLUMN_COUNTER <= (others => '0');
                             end if;
                         end if;
                         
                         if TRANSMITTING_CHECKSUM = '1' then
                             DATA_ROW_COUNTER <= (others => '0');
                             DATA_FRAME_WORD_COUNTER <= (others => '0');
                             UART_TRANSMITTING <= '0';
                             TRANSMITTING_CHECKSUM <= '0';
                             DATA_COLUMN_COUNTER <= (others => '0');
                         end if;
                         
                         
                     end if;
                  end if;
		          
		          if DATA_FRAME_WORD_COUNTER < FRAME_HEADER_signal'length then
                      case DATA_UART_WORD_COUNTER is
                          when "000" =>
                            DATA_signal <= FRAME_HEADER_signal(to_integer(DATA_FRAME_WORD_COUNTER))(31 downto 24);
                          when "001" =>
                            DATA_signal <= FRAME_HEADER_signal(to_integer(DATA_FRAME_WORD_COUNTER))(23 downto 16);
                          when "010" =>
                            DATA_signal <= FRAME_HEADER_signal(to_integer(DATA_FRAME_WORD_COUNTER))(15 downto 8);
                          when "011" =>
                            DATA_signal <= FRAME_HEADER_signal(to_integer(DATA_FRAME_WORD_COUNTER))(7 downto 0);
                          when others =>
                      end case;
                  elsif DATA_FRAME_WORD_COUNTER >= FRAME_HEADER_signal'length and DATA_FRAME_WORD_COUNTER < FRAME_HEADER_signal'length + NUM_ROWS then
                      case DATA_UART_WORD_COUNTER is
                          when "000" =>
                            DATA_signal <= FRAME_DATA_signal(to_integer(DATA_COLUMN_COUNTER))(to_integer(DATA_ROW_COUNTER))(31 downto 24);
                          when "001" =>
                            DATA_signal <= FRAME_DATA_signal(to_integer(DATA_COLUMN_COUNTER))(to_integer(DATA_ROW_COUNTER))(23 downto 16);
                          when "010" =>
                            DATA_signal <= FRAME_DATA_signal(to_integer(DATA_COLUMN_COUNTER))(to_integer(DATA_ROW_COUNTER))(15 downto 8);
                          when "011" =>
                            DATA_signal <= FRAME_DATA_signal(to_integer(DATA_COLUMN_COUNTER))(to_integer(DATA_ROW_COUNTER))(7 downto 0);
                          when others =>
                      end case;
                  elsif DATA_FRAME_WORD_COUNTER = FRAME_HEADER_signal'length + NUM_ROWS then
                      case DATA_UART_WORD_COUNTER is
                          when "000" =>
                            DATA_signal <= CHECKSUM(31 downto 24);
                          when "001" =>
                            DATA_signal <= CHECKSUM(23 downto 16);
                          when "010" =>
                            DATA_signal <= CHECKSUM(15 downto 8);
                          when "011" =>
                            DATA_signal <= CHECKSUM(7 downto 0);
                          when others =>
                      end case;
                  end if;
		          DATA_VALID_signal <= '1';   
		       end if;
		       
		    end if;
		    if DATA_VALID_signal = '1' then
		      DATA_VALID_signal <= '0';
		    end if;
		    
        end if;
	end process;
end Behavioral;
