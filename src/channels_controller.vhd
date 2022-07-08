----------------------------------------------------------------------------------
-- Company: NASA Goddard Space Flight Center
-- Engineer: Albert Risco
-- 
-- Create Date: 06.06.2022
-- Module Name: channels_controller.vhd
-- Project Name: channel_card_v1
-- Target Devices: Spartan 7 xc7s25csga324-1
-- Tool Versions: Vivado 2019.1
-- Description: This component is in charge of controlling the channels. That is to say to send the start pulse to the
--              feedback DAC, the bias of both the First Stage and the series array. It also determines which data is 
--              sent to the frame builder

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

library concept;
use concept.utils.all;

entity channels_controller is
    port(
        clk                     : in std_logic; -- 5MHz clock                                                                           
        rst                     : in std_logic; -- asynchronous reset

        data_mode               : in std_logic_vector(bits_req(NUM_DATA_MODES) - 1 downto 0); -- Param that indicates which type of data should we insert in the data frames
        servo_mode              : in t_param_array(0 to PARAM_ID_TO_SIZE(SERVO_MODE_ID) - 1); -- Param that indicates if the PID loop is active or we just ramp or set constant values for the lines
        fb_dly                  : in unsigned(bits_req(MAX_FB_DLY) - 1 downto 0); -- Param that indicates how many 5 MHz cycles do we have to wait to set the fb (activate DAC)

        new_row                 : in std_logic; -- Signal that indicates that a new row has started
        acquisition_on          : in std_logic; -- Signal that indicates that the acquisition is active
        frame_active            : in std_logic; -- Signal that remains active until the last row has been multiplexed
        set_SF                  : in std_logic; -- Pulse to update the SA feedback line
        set_SB                  : in std_logic; -- Pulse to update the SA bias line
        set_FF                  : in std_logic; -- Pulse to update the 1st stage feedback line
        set_FB                  : in std_logic; -- Pulse to update the 1st stage bias line

        DAC_start_pulse         : out std_logic; -- Pulse to start the DAC controller
        DAC_address             : out std_logic_vector(DAC_ADDR_SIZE - 1 downto 0); -- Address of the DAC that we are updating (corresponds either to the SF, SB, FF or FB). The same for all channels
        line_sel                : out t_line_sel_array; -- Selector for the multiplexer that chooses which data to set in the DAC. We have different selector per channel
        data_sel                : out unsigned(bits_req(NUM_DATA_MODES) - 1 downto 0) -- Selector for the multiplexer that chooses which data to put in the data frame
    );

end channels_controller;

architecture behave of channels_controller is

    -- Mapping of the physical lines with their corrersponding DAC addresses
    constant SF_ADDRESS : std_logic_vector(1 downto 0) := "00";
    constant SB_ADDRESS : std_logic_vector(1 downto 0) := "01";
    constant FF_ADDRESS : std_logic_vector(1 downto 0) := "10";
    constant FB_ADDRESS : std_logic_vector(1 downto 0) := "11";

    -- Options for the fb multiplexer
    constant LINE_SEL_PID   : unsigned(LINE_SEL_SIZE - 1 downto 0) := to_unsigned(0, LINE_SEL_SIZE);
    constant LINE_SEL_RAMP  : unsigned(LINE_SEL_SIZE - 1 downto 0) := to_unsigned(1, LINE_SEL_SIZE);
    constant LINE_SEL_SF    : unsigned(LINE_SEL_SIZE - 1 downto 0) := to_unsigned(2, LINE_SEL_SIZE);
    constant LINE_SEL_SB    : unsigned(LINE_SEL_SIZE - 1 downto 0) := to_unsigned(3, LINE_SEL_SIZE);
    constant LINE_SEL_FF    : unsigned(LINE_SEL_SIZE - 1 downto 0) := to_unsigned(4, LINE_SEL_SIZE);
    constant LINE_SEL_FB    : unsigned(LINE_SEL_SIZE - 1 downto 0) := to_unsigned(5, LINE_SEL_SIZE);

    type stateType is (idle, wait_new_row, wait_fb_dly, set_DAC_voltage);
    signal state : stateType := idle;

    signal dly_counter : unsigned(fb_dly'range) := (others => '0');

begin

-- Selector for the multiplexer selecting the output of each channel
data_sel <= to_unsigned(0, data_sel'length) when data_mode = std_logic_vector(to_unsigned(DATA_MODE_ERROR, data_mode'length)) else
            to_unsigned(1, data_sel'length) when data_mode = std_logic_vector(to_unsigned(DATA_MODE_FB, data_mode'length)) else
            to_unsigned(2, data_sel'length) when data_mode = std_logic_vector(to_unsigned(DATA_MODE_FILT_FB, data_mode'length)) else
            to_unsigned(3, data_sel'length);

main_logic : process(clk, rst)
begin
    if (rst = '1') then
        DAC_address <= (others => '0');
        line_sel <= (others => to_unsigned(0, LINE_SEL_SIZE));
        dly_counter <= (others => '0');
        state <= idle;

    elsif (rising_edge(clk)) then
        case state is
            when idle =>
                DAC_start_pulse <= '0';

                if (acquisition_on = '1') then
                    -- Each channel is assigned its corresponding line depending on the servo_mode chosen for that channel
                    for i in 0 to MAX_CHANNELS - 1 loop
                        if (unsigned(servo_mode(i)(bits_req(NUM_SERVO_MODES) - 1 downto 0)) = to_unsigned(SERVO_MODE_CONST, bits_req(NUM_SERVO_MODES))) then
                            line_sel(i) <= LINE_SEL_SF;
                        elsif (unsigned(servo_mode(i)(bits_req(NUM_SERVO_MODES) - 1 downto 0)) = to_unsigned(SERVO_MODE_RAMP, bits_req(NUM_SERVO_MODES))) then
                            line_sel(i) <= LINE_SEL_RAMP;
                        else
                            line_sel(i) <= LINE_SEL_PID;
                        end if;
                    end loop;

                    DAC_address <= SF_ADDRESS; -- When acquisition is on, we modify the SA feedback only
                    state <= wait_new_row;

                -- When acquisition is off we update all channels independently of their servo_mode
                elsif (set_SF = '1') then
                    line_sel <= (others => LINE_SEL_SF);
                    DAC_address <= SF_ADDRESS; 
                    DAC_start_pulse <= '1';
                    state <= set_DAC_voltage;

                elsif (set_SB = '1') then
                    line_sel <= (others => LINE_SEL_SB);
                    DAC_address <= SB_ADDRESS; 
                    DAC_start_pulse <= '1';
                    state <= set_DAC_voltage;

                elsif (set_FF = '1') then
                    line_sel <= (others => LINE_SEL_FF);
                    DAC_address <= FF_ADDRESS; 
                    DAC_start_pulse <= '1';
                    state <= set_DAC_voltage;

                elsif (set_FB = '1') then
                    line_sel <= (others => LINE_SEL_FB);
                    DAC_address <= FB_ADDRESS; 
                    DAC_start_pulse <= '1';
                    state <= set_DAC_voltage;
                else
                    state <= state;
                end if;

            when wait_new_row =>
                if (acquisition_on = '1' or frame_active = '1') then
                    if (new_row = '1') then
                        if (dly_counter = fb_dly) then
                            DAC_start_pulse <= '1';
                            dly_counter <= (others => '0');
                            state <= set_DAC_voltage;
                        else
                            dly_counter <= dly_counter + 1;
                            state <= wait_fb_dly;
                        end if;
                    else
                        state <= state;
                    end if;
                else
                    state <= idle;
                end if;
            
            when wait_fb_dly =>
                if (dly_counter = fb_dly) then
                    DAC_start_pulse <= '1';
                    dly_counter <= (others => '0');
                    state <= set_DAC_voltage;
                else 
                    dly_counter <= dly_counter + 1;
                    state <= state;
                end if;
            
            when set_DAC_voltage =>
                DAC_start_pulse <= '0';
                if (frame_active = '1') then
                    state <= wait_new_row;
                else
                    state <= idle;
                end if;

            when others =>
                state <= idle;
        end case;
    end if;

end process;

end behave;