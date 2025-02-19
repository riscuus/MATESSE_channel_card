##====================================================
##                  CONSTRAINTS FILE
##     FOR PLDA XpressK7 xc7k325tfbg676-2 BOARD
##====================================================


#set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property CFGBVS VCCO [current_design]


## ----------------------------------------------------
##  TIMING CONSTRAINTS
## ----------------------------------------------------



## Frequency Constraints

##create_clock -period 10.000 -name sys_clk_p -waveform {0.000 5.000} [get_ports sys_clk_p]
### create_clock -period 10.000 -name sys_clk_n -waveform {5.000 5.000} [get_ports sys_clk_n]
##create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_pins * -hier -filter {NAME  =~ */refclk_ibuf/O}]
##create_clock -period 10.000 -name txoutclk -waveform {0.000 5.000} [get_pins * -hier -filter {NAME  =~ */pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK}]
##create_clock -period 100.000 -name EXTERNAL_CLK -waveform {0.000 50.000} [get_ports EXTERNAL_CLK]
##create_clock -period 100.000 -name RefClkInt1In -waveform {0.000 50.000} [get_ports RefClkInt1In]

##create_generated_clock -name clk_125mhz_mux -source [get_pins * -hier -filter {NAME  =~ */pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I0}] -divide_by 1 [get_pins * -hier -filter {NAME  =~ */pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O}]

##create_generated_clock -name clk_250mhz_mux -source [get_pins * -hier -filter {NAME  =~ */pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1}] -divide_by 1 -add -master_clock clk_250mhz [get_pins * -hier -filter {NAME  =~ */pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O}]

##set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux -group clk_250mhz_mux
##set_false_path -to [get_pins * -hier -filter {NAME  =~ */pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S*}]


### False pathes
###set_false_path -from [get_ports sys_rst_n]
###set_false_path -through [get_cells aresetn_reg]

# Property to allow clkout signal to be used as clock for the ddr input module
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets ADC_CLKOUT_IO31_IBUF]

##set_property IOB TRUE [get_cells {u1/io_exp_ctrl/SM_read_IOEXP/reg_shift_reg[0]}]
## ----------------------------------------------------
##  PCIE HARD IP CONSTRAINTS
## ----------------------------------------------------

### BlockRAM placement
##set_property LOC RAMB36_X4Y34 [get_cells * -hier -filter {NAME  =~ */pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[0].ram/use_tdp.ramb36/genblk5_0.bram36_tdp_bl.bram36_tdp_bl}]
##set_property LOC RAMB36_X4Y35 [get_cells * -hier -filter {NAME  =~ */pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_rx/brams[1].ram/use_tdp.ramb36/genblk5_0.bram36_tdp_bl.bram36_tdp_bl}]
##set_property LOC RAMB36_X4Y33 [get_cells * -hier -filter {NAME  =~ */pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[0].ram/use_tdp.ramb36/genblk5_0.bram36_tdp_bl.bram36_tdp_bl}]
##set_property LOC RAMB36_X4Y32 [get_cells * -hier -filter {NAME  =~ */pcie_top_i/pcie_7x_i/pcie_bram_top/pcie_brams_tx/brams[1].ram/use_tdp.ramb36/genblk5_0.bram36_tdp_bl.bram36_tdp_bl}]


## ----------------------------------------------------
##  PIN PROPERTIES
## ----------------------------------------------------

## 50Mhz Clock
##set_property PACKAGE_PIN AB11 [get_ports clk_50mhz]
##set_property IOSTANDARD LVCMOS15 [get_ports clk_50mhz]

## System Reset
#set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n]
#set_property PULLUP true [get_ports sys_rst_n]
#set_property PACKAGE_PIN U16 [get_ports sys_rst_n]

##PCIe signals
#set_property PACKAGE_PIN D6 [get_ports sys_clk_p]
#set_property PACKAGE_PIN D5 [get_ports sys_clk_n]


### On-board LEDs
##set_property PACKAGE_PIN W10 [get_ports {usr_led[0]}]
##set_property PACKAGE_PIN V11 [get_ports {usr_led[1]}]
##set_property PACKAGE_PIN Y10 [get_ports {usr_led[2]}]
##set_property PACKAGE_PIN W13 [get_ports {usr_led[3]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_led[0]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_led[1]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_led[2]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_led[3]}]

### Front Tricolor LEDs
##set_property PACKAGE_PIN T7 [get_ports {front_led[0]}]
##set_property PACKAGE_PIN V7 [get_ports {front_led[1]}]
##set_property PACKAGE_PIN U4 [get_ports {front_led[2]}]
##set_property PACKAGE_PIN V2 [get_ports {front_led[3]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {front_led[0]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {front_led[1]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {front_led[2]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {front_led[3]}]

### On-board Switches
##set_property PACKAGE_PIN AA15 [get_ports {usr_sw[0]}]
##set_property PACKAGE_PIN V8 [get_ports {usr_sw[1]}]
##set_property PACKAGE_PIN Y8 [get_ports {usr_sw[2]}]
##set_property PACKAGE_PIN Y7 [get_ports {usr_sw[3]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_sw[0]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_sw[1]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_sw[2]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {usr_sw[3]}]

###------------------------------------------------------------------------------
### Protocore Signals
###------------------------------------------------------------------------------
##set_property PACKAGE_PIN AB19 [get_ports prot0_out]
##set_property PACKAGE_PIN V13 [get_ports {prot2_in[0]}]
##set_property PACKAGE_PIN W9 [get_ports {prot2_in[1]}]
##set_property PACKAGE_PIN W8 [get_ports prot2_out]

##set_property IOSTANDARD LVCMOS15 [get_ports prot0_out]
##set_property IOSTANDARD LVCMOS15 [get_ports {prot2_in[0]}]
##set_property IOSTANDARD LVCMOS15 [get_ports {prot2_in[1]}]
##set_property IOSTANDARD LVCMOS15 [get_ports prot2_out]

##------------------------------------------------------------------------------
## bitstream properties
##------------------------------------------------------------------------------
#set_property BITSTREAM.STARTUP.STARTUPCLK Cclk [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
#set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type2 [current_design]
##set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1  [current_design]
#set_property BITSTREAM.CONFIG.BPI_PAGE_SIZE 1 [current_design]
#set_property BITSTREAM.CONFIG.BPI_1ST_READ_CYCLE 1 [current_design]
#set_property CONFIG_MODE BPI16 [current_design]

##set_property PACKAGE_PIN N21 [get_ports RefClkInt1In]
##set_property IOSTANDARD LVCMOS33 [get_ports RefClkInt1In]
##set_property PACKAGE_PIN Y22 [get_ports EXTERNAL_CLK]
##set_property IOSTANDARD LVCMOS33 [get_ports EXTERNAL_CLK]

#set_property PACKAGE_PIN AB22 [get_ports RefClkInt1In]
#set_property IOSTANDARD LVCMOS33 [get_ports RefClkInt1In]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets RefClkInt1In_IBUF]

#set_property PACKAGE_PIN AB26 [get_ports EXTERNAL_CLK]
#set_property IOSTANDARD LVCMOS33 [get_ports EXTERNAL_CLK]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets EXTERNAL_CLK_IBUF]

##------------------------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------------------------

## This file is a general .xdc for the Arty S7-50 Rev. B
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk_12]
create_clock -period 83.333 -name sys_clk_pin -waveform {0.000 41.667} -add [get_ports clk_12]
#set_property -dict {PACKAGE_PIN R2 IOSTANDARD SSTL135} [get_ports clk_100]
#create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100]

# Switches
# SW[0]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports sys_rst]
#set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
#set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
#set_property -dict {PACKAGE_PIN M5 IOSTANDARD SSTL135} [get_ports {sw[3]}]


## RGB LEDs
#set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { led0_r }]; #IO_L23N_T3_FWE_B_15 Sch=led0_r
#set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {LED[4]}]
#set_property -dict { PACKAGE_PIN F15   IOSTANDARD LVCMOS33 } [get_ports { led0_b }]; #IO_L13N_T2_MRCC_15 Sch=led0_b
#set_property -dict { PACKAGE_PIN E15   IOSTANDARD LVCMOS33 } [get_ports { led1_r }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=led1_r
#set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {LED[5]}]
#set_property -dict { PACKAGE_PIN E14   IOSTANDARD LVCMOS33 } [get_ports { led1_b }]; #IO_L15P_T2_DQS_15 Sch=led1_b


# LEDs
#set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
#set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
#set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
#set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]


## Buttons
#set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports START_CONV_DAC_CH_PULSE]
#set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports valid_DAC]
#set_property -dict { PACKAGE_PIN J16   IOSTANDARD LVCMOS33 } [get_ports btn[2]]; #IO_L19N_T3_A21_VREF_15 Sch=btn[2]
#set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports START_CONV_ADC_CH_PULSE]


## PMOD Header JA
#set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports {SDO_CH[3]}]
#set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {SDO_CH[4]}]
#set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {SDO_CH[5]}]
#set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {SDO_CH[6]}]
#set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {SDO_CH[7]}]
#set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports {SDO_CH[8]}]
#set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports row_sync]
#set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { ja[7] }]; #IO_L8N_T1_D12_14 Sch=ja_n[4]


## PMOD Header JB
#set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { jb[0] }]; #IO_L9P_T1_DQS_14 Sch=jb_p[1]
#set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { jb[1] }]; #IO_L9N_T1_DQS_D13_14 Sch=jb_n[1]
#set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { jb[2] }]; #IO_L10P_T1_D14_14 Sch=jb_p[2]
#set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { jb[3] }]; #IO_L10N_T1_D15_14 Sch=jb_n[2]
#set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { jb[4] }]; #IO_L11P_T1_SRCC_14 Sch=jb_p[3]
#set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { jb[5] }]; #IO_L11N_T1_SRCC_14 Sch=jb_n[3]
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { jb[6] }]; #IO_L12P_T1_MRCC_14 Sch=jb_p[4]
#set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { jb[7] }]; #IO_L12N_T1_MRCC_14 Sch=jb_n[4]


## PMOD Header JC
#set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { jc[0] }]; #IO_L18P_T2_A12_D28_14 Sch=jc1/ck_io[41]
#set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { jc[1] }]; #IO_L18N_T2_A11_D27_14 Sch=jc2/ck_io[40]
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { jc[2] }]; #IO_L15P_T2_DQS_RDWR_B_14 Sch=jc3/ck_io[39]
#set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { jc[3] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=jc4/ck_io[38]
#set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { jc[4] }]; #IO_L16P_T2_CSI_B_14 Sch=jc7/ck_io[37]
#set_property -dict { PACKAGE_PIN P13   IOSTANDARD LVCMOS33 } [get_ports { jc[5] }]; #IO_L19P_T3_A10_D26_14 Sch=jc8/ck_io[36]
#set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { jc[6] }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=jc9/ck_io[35]
#set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { jc[7] }]; #IO_L20P_T3_A08_D24_14 Sch=jc10/ck_io[34]


## PMOD Header JD
#set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { jd[0] }]; #IO_L20N_T3_A07_D23_14 Sch=jd1/ck_io[33]
#set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { jd[1] }]; #IO_L21P_T3_DQS_14 Sch=jd2/ck_io[32]
#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { jd[2] }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=jd3/ck_io[31]
#set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { jd[3] }]; #IO_L22P_T3_A05_D21_14 Sch=jd4/ck_io[30]
#set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { jd[4] }]; #IO_L22N_T3_A04_D20_14 Sch=jd7/ck_io[29]
#set_property -dict { PACKAGE_PIN R11   IOSTANDARD LVCMOS33 } [get_ports { jd[5] }]; #IO_L23P_T3_A03_D19_14 Sch=jd8/ck_io[28]
#set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { jd[6] }]; #IO_L23N_T3_A02_D18_14 Sch=jd9/ck_io[27]
#set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { jd[7] }]; #IO_L24P_T3_A01_D17_14 Sch=jd10/ck_io[26]


## USB-UART Interface
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports tx_uart_serial]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports rx_uart_serial]


# ChipKit Single Ended Analog Inputs
# NOTE: The ck_an_p pins can be used as single ended analog inputs with voltages from 0-3.3V (Chipkit Analog pins A0-A5).
# These signals should only be connected to the XADC core. When using these pins as digital I/O, use pins ck_io[14-19].
#set_property -dict { PACKAGE_PIN B13   IOSTANDARD LVCMOS33 } [get_ports { vauxp0 }]; #IO_L1P_T0_AD0P_15 Sch=ck_an_p[0]
#set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33 } [get_ports { vauxn0 }]; #IO_L1N_T0_AD0N_15 Sch=ck_an_n[0]
#set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports { vauxp1 }]; #IO_L3P_T0_DQS_AD1P_15 Sch=ck_an_p[1]
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports { vauxn1 }]; #IO_L3N_T0_DQS_AD1N_15 Sch=ck_an_n[1]
#set_property -dict { PACKAGE_PIN E12   IOSTANDARD LVCMOS33 } [get_ports { vauxp2 }]; #IO_L5P_T0_AD9P_15 Sch=ck_an_p[2]
#set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { vauxn2 }]; #IO_L5N_T0_AD9N_15 Sch=ck_an_n[2]
#set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS33 } [get_ports { vauxp10 }]; #IO_L7P_T1_AD2P_15 Sch=ck_an_p[3]
#set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { vauxn10 }]; #IO_L7N_T1_AD2N_15 Sch=ck_an_n[3]
#set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { vauxp3 }]; #IO_L8P_T1_AD10P_15 Sch=ck_an_p[4]
#set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { vauxn3 }]; #IO_L8N_T1_AD10N_15 Sch=ck_an_n[4]
#set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { vauxp4 }]; #IO_L10P_T1_AD11P_15 Sch=ck_an_p[5]
#set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { vauxn4 }]; #IO_L10N_T1_AD11N_15 Sch=ck_an_n[5]

# Dedicated Analog Inputs
#set_property -dict { PACKAGE_PIN J10   } [get_ports { vp_in }]; #IO_L1P_T0_AD4P_35 Sch=v_p
#set_property -dict { PACKAGE_PIN K9    } [get_ports { vn_in }]; #IO_L1N_T0_AD4N_35 Sch=v_n


## ChipKit Digital I/O Low
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports ADC_CNV_IO0]
set_property -dict {PACKAGE_PIN N13 IOSTANDARD LVCMOS33} [get_ports ADC_SCK_IO1]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports ADC_SDO_0_IO2]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports channels_DAC_LDAC_IO3]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports channels_DAC_CS_IO4]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports channels_DAC_CLK_IO5]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports channels_DAC_SDI_0_IO6]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports row_activator_DAC_LDAC_IO7]
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports row_activator_DAC_CS_0_IO8]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports row_activator_DAC_CS_1_IO9]
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports row_activator_DAC_CS_2_IO10]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports row_activator_DAC_CLK_IO11]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports row_activator_DAC_SDI_IO12]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports TES_bias_DAC_LDAC_IO13]



#set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS33 } [get_ports { ck_io[0] }]; #IO_0_14 Sch=ck_io[0]
#set_property -dict { PACKAGE_PIN N13   IOSTANDARD LVCMOS33 } [get_ports { ck_io[1] }]; #IO_L6N_T0_D08_VREF_14 Sch=ck_io[1]
#set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { ck_io[2] }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=ck_io[2]
#set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { ck_io[3] }]; #IO_L13P_T2_MRCC_14 Sch=ck_io[3]
#set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { ck_io[4] }]; #IO_L13N_T2_MRCC_14 Sch=ck_io[4]
#set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { ck_io[5] }]; #IO_L14P_T2_SRCC_14 Sch=ck_io[5]
#set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { ck_io[6] }]; #IO_L14N_T2_SRCC_14 Sch=ck_io[6]
#set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { ck_io[7] }]; #IO_L16N_T2_A15_D31_14 Sch=ck_io[7]
#set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { ck_io[8] }]; #IO_L17P_T2_A14_D30_14 Sch=ck_io[8]
#set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { ck_io[9] }]; #IO_L17N_T2_A13_D29_14 Sch=ck_io[9]
#set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { ck_io[10] }]; #IO_L22P_T3_A17_15 Sch=ck_io10_ss
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { ck_io[11] }]; #IO_L22N_T3_A16_15 Sch=ck_io11_mosi
#set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { ck_io[12] }]; #IO_L23P_T3_FOE_B_15 Sch=ck_io12_miso
#set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { ck_io[13] }]; #IO_L14P_T2_SRCC_15 Sch=ck_io13_sck



## ChipKit Digital I/O On Outer Analog Header
## NOTE: These pins should be used when using the analog header signals A0-A5 as digital I/O (Chipkit digital pins 14-19)
#set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { ck_io[14] }]; #IO_0_15 Sch=ck_a[0]
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports { ck_io[15] }]; #IO_L4P_T0_15 Sch=ck_a[1]
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports { ck_io[16] }]; #IO_L4N_T0_15 Sch=ck_a[2]
#set_property -dict { PACKAGE_PIN C13   IOSTANDARD LVCMOS33 } [get_ports { ck_io[17] }]; #IO_L6P_T0_15 Sch=ck_a[3]
#set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33 } [get_ports { ck_io[18] }]; #IO_L6N_T0_VREF_15 Sch=ck_a[4]
#set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { ck_io[19] }]; #IO_L11P_T1_SRCC_15 Sch=ck_a[5]

# ChipKit Inner Analog Header - as Differential Analog Inputs
# NOTE: These ports can be used as differential analog inputs with voltages from 0-1.0V (ChipKit analog pins A6-A11) or as digital I/O.
# WARNING: Do not use both sets of constraints at the same time!
# NOTE: The following constraints should be used with the XADC core when using these ports as analog inputs.
#set_property -dict { PACKAGE_PIN B14   IOSTANDARD LVCMOS33 } [get_ports { vauxp8  }]; #IO_L2P_T0_AD8P_15     Sch=ad_p[8]   ChipKit pin=A6
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { vauxn8  }]; #IO_L2N_T0_AD8N_15     Sch=ad_n[8]   ChipKit pin=A7
#set_property -dict { PACKAGE_PIN D16   IOSTANDARD LVCMOS33 } [get_ports { vauxp11 }]; #IO_L9P_T1_DQS_AD3P_15 Sch=ad_p[3]   ChipKit pin=A8
#set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { vauxn11 }]; #IO_L9N_T1_DQS_AD3N_15 Sch=ad_n[3]   ChipKit pin=A9

## ChipKit Inner Analog Header - as Digital I/O
## NOTE: The following constraints should be used when using the inner analog header ports as digital I/O.
#set_property -dict { PACKAGE_PIN B14   IOSTANDARD LVCMOS33 } [get_ports { ck_a6  }]; #IO_L2P_T0_AD8P_15     Sch=ad_p[8]
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { ck_a7  }]; #IO_L2N_T0_AD8N_15     Sch=ad_n[8]
#set_property -dict { PACKAGE_PIN D16   IOSTANDARD LVCMOS33 } [get_ports { ck_a8  }]; #IO_L9P_T1_DQS_AD3P_15 Sch=ad_p[3]
#set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { ck_a9  }]; #IO_L9N_T1_DQS_AD3N_15 Sch=ad_n[3]
#set_property -dict { PACKAGE_PIN D14   IOSTANDARD LVCMOS33 } [get_ports { ck_a10 }]; #IO_L12P_T1_MRCC_15    Sch=ck_a10_r   (Cannot be used as an analog input)
#set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33 } [get_ports { ck_a11 }]; #IO_L12N_T1_MRCC_15    Sch=ck_a11_r   (Cannot be used as an analog input)


## ChipKit Digital I/O High
## Note: these pins are shared with PMOD Headers JC and JD and cannot be used at the same time as the applicable PMOD interface(s)
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports TES_bias_DAC_CS_IO26]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports TES_bias_DAC_CLK_IO27]
set_property -dict {PACKAGE_PIN R11 IOSTANDARD LVCMOS33} [get_ports TES_bias_DAC_SDI_IO28]
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports ADC_SDO_1_IO29]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports channels_DAC_SDI_1_IO30]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports ADC_CLKOUT_IO31]
#set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {SDI_CH[4]}]
#set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {SDI_CH[5]}]
#set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {SDI_CH[6]}]
#set_property -dict {PACKAGE_PIN R13 IOSTANDARD LVCMOS33} [get_ports {SDI_CH[7]}]
#set_property -dict {PACKAGE_PIN P13 IOSTANDARD LVCMOS33} [get_ports {SDI_CH[8]}]
#set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports START_CONV_ADC_CH_PULSE_emulation]
##set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports START_CONV_ADC_CH_PULSE]
##set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports START_CONV_DAC_CH_PULSE]
#set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports Clock_5mhz]
#set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports Clock_100mhz]



## ChipKit SPI
## Note: these are shared with the ChipKit IOL pins and should not be used at the same time as the pins.
#set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { ck_ss }]; #IO_L22P_T3_A17_15 Sch=ck_io10_ss
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { ck_mosi }]; #IO_L22N_T3_A16_15 Sch=ck_io11_mosi
#set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { ck_miso }]; #IO_L23P_T3_FOE_B_15 Sch=ck_io12_miso
#set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { ck_sck }]; #IO_L14P_T2_SRCC_15 Sch=ck_io13_sck


## CihpKit I2C
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { ck_scl }]; #IO_L24N_T3_RS0_15 Sch=ck_scl
#set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { ck_sda }]; #IO_L24P_T3_RS1_15 Sch=ck_sda


## Misc. ChipKit signals
#set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports { ck_ioa }] #IO_25_15 Sch=ck_ioa
#set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports Sys_Reset_in]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {Sys_Reset_IBUF}]

## Quad SPI Flash
## Note: the SCK clock signal can be driven using the STARTUPE2 primitive
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
#set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]

## Configuration options, can be used for all designs
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

## SW3 is assigned to a pin M5 in the 1.35v bank. This pin can also be used as
## the VREF for BANK 34. To ensure that SW3 does not define the reference voltage
## and to be able to use this pin as an ordinary I/O the following property must
## be set to enable an internal VREF for BANK 34. Since a 1.35v supply is being
## used the internal reference is set to half that value (i.e. 0.675v). Note that
## this property must be set even if SW3 is not used in the design.
set_property INTERNAL_VREF 0.675 [get_iobanks 34]

##------------------------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------------------------



##set_false_path -from [get_clocks userclk1] -to [get_clocks RefClkInt1In]
##set_false_path -from [get_clocks RefClkInt1In] -to [get_clocks userclk1]
##set_false_path -from [get_clocks userclk1] -to [get_clocks EXTERNAL_CLK]
##set_false_path -from [get_clocks EXTERNAL_CLK] -to [get_clocks userclk1]
##set_false_path -from [get_clocks RefClkInt1In] -to [get_clocks EXTERNAL_CLK]
##set_false_path -from [get_clocks EXTERNAL_CLK] -to [get_clocks RefClkInt1In]


#create_generated_clock -name u1/io_exp_ctrl/SM_SCLK_CS_generation/stateMachine_ioexp_clk_cs_gen/SCLK -source [get_pins u3/qpcie_xx_hip_top/g_xx_pcie_hip.qpcie_pcie_core_inst/pipe_clock_i/mmcm_i/CLKOUT2] -divide_by 8 [get_pins u1/io_exp_ctrl/SM_SCLK_CS_generation/stateMachine_ioexp_clk_cs_gen/SCLK_reg_reg/Q]



##set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
##set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
##set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
##connect_debug_port dbg_hub/clk [get_nets qpcie_clk_out]




create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clock_distr/clk_generator/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {main_module/parallel_data[0]_5[0]} {main_module/parallel_data[0]_5[1]} {main_module/parallel_data[0]_5[2]} {main_module/parallel_data[0]_5[3]} {main_module/parallel_data[0]_5[4]} {main_module/parallel_data[0]_5[5]} {main_module/parallel_data[0]_5[6]} {main_module/parallel_data[0]_5[7]} {main_module/parallel_data[0]_5[8]} {main_module/parallel_data[0]_5[9]} {main_module/parallel_data[0]_5[10]} {main_module/parallel_data[0]_5[11]} {main_module/parallel_data[0]_5[12]} {main_module/parallel_data[0]_5[13]} {main_module/parallel_data[0]_5[14]} {main_module/parallel_data[0]_5[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {main_module/valid_sample[0]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {main_module/valid_word[0]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {main_module/sample_data[0]_3[0]} {main_module/sample_data[0]_3[1]} {main_module/sample_data[0]_3[2]} {main_module/sample_data[0]_3[3]} {main_module/sample_data[0]_3[4]} {main_module/sample_data[0]_3[5]} {main_module/sample_data[0]_3[6]} {main_module/sample_data[0]_3[7]} {main_module/sample_data[0]_3[8]} {main_module/sample_data[0]_3[9]} {main_module/sample_data[0]_3[10]} {main_module/sample_data[0]_3[11]} {main_module/sample_data[0]_3[12]} {main_module/sample_data[0]_3[13]} {main_module/sample_data[0]_3[14]} {main_module/sample_data[0]_3[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 2 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {main_module/ddr_parallel[0]_7[0]} {main_module/ddr_parallel[0]_7[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 32 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {main_module/channels_data[0][value][0]} {main_module/channels_data[0][value][1]} {main_module/channels_data[0][value][2]} {main_module/channels_data[0][value][3]} {main_module/channels_data[0][value][4]} {main_module/channels_data[0][value][5]} {main_module/channels_data[0][value][6]} {main_module/channels_data[0][value][7]} {main_module/channels_data[0][value][8]} {main_module/channels_data[0][value][9]} {main_module/channels_data[0][value][10]} {main_module/channels_data[0][value][11]} {main_module/channels_data[0][value][12]} {main_module/channels_data[0][value][13]} {main_module/channels_data[0][value][14]} {main_module/channels_data[0][value][15]} {main_module/channels_data[0][value][16]} {main_module/channels_data[0][value][17]} {main_module/channels_data[0][value][18]} {main_module/channels_data[0][value][19]} {main_module/channels_data[0][value][20]} {main_module/channels_data[0][value][21]} {main_module/channels_data[0][value][22]} {main_module/channels_data[0][value][23]} {main_module/channels_data[0][value][24]} {main_module/channels_data[0][value][25]} {main_module/channels_data[0][value][26]} {main_module/channels_data[0][value][27]} {main_module/channels_data[0][value][28]} {main_module/channels_data[0][value][29]} {main_module/channels_data[0][value][30]} {main_module/channels_data[0][value][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {main_module/ddr_valid[0]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 32 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {main_module/fb_sample[0][value][0]} {main_module/fb_sample[0][value][1]} {main_module/fb_sample[0][value][2]} {main_module/fb_sample[0][value][3]} {main_module/fb_sample[0][value][4]} {main_module/fb_sample[0][value][5]} {main_module/fb_sample[0][value][6]} {main_module/fb_sample[0][value][7]} {main_module/fb_sample[0][value][8]} {main_module/fb_sample[0][value][9]} {main_module/fb_sample[0][value][10]} {main_module/fb_sample[0][value][11]} {main_module/fb_sample[0][value][12]} {main_module/fb_sample[0][value][13]} {main_module/fb_sample[0][value][14]} {main_module/fb_sample[0][value][15]} {main_module/fb_sample[0][value][16]} {main_module/fb_sample[0][value][17]} {main_module/fb_sample[0][value][18]} {main_module/fb_sample[0][value][19]} {main_module/fb_sample[0][value][20]} {main_module/fb_sample[0][value][21]} {main_module/fb_sample[0][value][22]} {main_module/fb_sample[0][value][23]} {main_module/fb_sample[0][value][24]} {main_module/fb_sample[0][value][25]} {main_module/fb_sample[0][value][26]} {main_module/fb_sample[0][value][27]} {main_module/fb_sample[0][value][28]} {main_module/fb_sample[0][value][29]} {main_module/fb_sample[0][value][30]} {main_module/fb_sample[0][value][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 32 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {main_module/acc_sample[0][value][0]} {main_module/acc_sample[0][value][1]} {main_module/acc_sample[0][value][2]} {main_module/acc_sample[0][value][3]} {main_module/acc_sample[0][value][4]} {main_module/acc_sample[0][value][5]} {main_module/acc_sample[0][value][6]} {main_module/acc_sample[0][value][7]} {main_module/acc_sample[0][value][8]} {main_module/acc_sample[0][value][9]} {main_module/acc_sample[0][value][10]} {main_module/acc_sample[0][value][11]} {main_module/acc_sample[0][value][12]} {main_module/acc_sample[0][value][13]} {main_module/acc_sample[0][value][14]} {main_module/acc_sample[0][value][15]} {main_module/acc_sample[0][value][16]} {main_module/acc_sample[0][value][17]} {main_module/acc_sample[0][value][18]} {main_module/acc_sample[0][value][19]} {main_module/acc_sample[0][value][20]} {main_module/acc_sample[0][value][21]} {main_module/acc_sample[0][value][22]} {main_module/acc_sample[0][value][23]} {main_module/acc_sample[0][value][24]} {main_module/acc_sample[0][value][25]} {main_module/acc_sample[0][value][26]} {main_module/acc_sample[0][value][27]} {main_module/acc_sample[0][value][28]} {main_module/acc_sample[0][value][29]} {main_module/acc_sample[0][value][30]} {main_module/acc_sample[0][value][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {main_module/acc_sample[0][valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list ADC_CNV_IO0_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list ADC_SCK_IO1_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list ADC_SDO_0_IO2_IBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {main_module/channels_data[0][valid]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {main_module/fb_sample[0][valid]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk_100]
