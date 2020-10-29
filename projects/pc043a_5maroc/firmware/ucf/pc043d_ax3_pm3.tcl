set_property BITSTREAM.Config.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

# CHANGE ME - Add constraints for 5 MAROC board.
# 
# 
# For 250MHz bit rate
# create_clock -period 20.000 -name sysclk_clk [get_ports sysclk_p]
create_clock -period 40.000 -name ext_clk [get_ports HDMI0_CLK_P]


set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks osc_clk] -group [get_clocks -include_generated_clocks ext_clk] 
# -filter {NAME =~ *CLKOUT*}]]


set_property IOSTANDARD LVDS_25 [get_port { HDMI* }]
set_property DIFF_TERM TRUE [get_port { HDMI* }]

# Why have these nets dissapeared??
#set_false_path -through [get_pins clocks/rst ]
#set_false_path -through [get_pins clocks/rsto_ipb ]

# set_false_path -through [get_ports cfg[*]  ]

# Why don't these work? Put these back...
# set_false_path -through [get_pins slaves/slave7/s_set_iobufds_direction[*] ]
# set_false_path -through [get_pins slaves/slave7/s_signal_to_iobufds[*] ]




# Start of constraints from UCF file.....
#set_property PACKAGE_PIN K15  [get_ports {sysclk_p}]
#set_property PACKAGE_PIN K16  [get_ports {sysclk_n}]
#set_property PACKAGE_PIN tnm_ipb_clk  [get_ports {ipb_clk}]
# set_property PACKAGE_PIN tnm_clk500  [get_ports {clk_2x_fast}]
# LED locations defined in enclustra_ax3_pm3.tcl
#set_property PACKAGE_PIN E13  [get_ports {leds<0>}]
#set_property PACKAGE_PIN C14  [get_ports {leds<1>}]
#set_property PACKAGE_PIN C4  [get_ports {leds<2>}]
#set_property PACKAGE_PIN A4  [get_ports {leds<3>}]

# CHANGE ME
# Find 4 pins on FMC connector that aren't being used and put in here in place of SP601 DIP switch
#set_property PACKAGE_PIN D14  [get_ports {dip_switch<0>}]
#set_property PACKAGE_PIN E12  [get_ports {dip_switch<1>}]
#set_property PACKAGE_PIN F12  [get_ports {dip_switch<2>}]
#set_property PACKAGE_PIN V13  [get_ports {dip_switch<3>}]

# Commented out, DGC, 29/Oct/20
# set_property PACKAGE_PIN B2  [get_ports {ADC_DAV_2V5[0]}]
# set_property PACKAGE_PIN D8  [get_ports {ADC_DAV_2V5[1]}]
# set_property PACKAGE_PIN D12  [get_ports {ADC_DAV_2V5[2]}]
# set_property PACKAGE_PIN C15  [get_ports {ADC_DAV_2V5[3]}]
# set_property PACKAGE_PIN V15  [get_ports {ADC_DAV_2V5[4]}]
# set_property PACKAGE_PIN G9  [get_ports {OUT_ADC_2V5[0]}]
# set_property PACKAGE_PIN B12  [get_ports {OUT_ADC_2V5[1]}]
# set_property PACKAGE_PIN E7  [get_ports {OUT_ADC_2V5[2]}]
# set_property PACKAGE_PIN C13  [get_ports {OUT_ADC_2V5[3]}]
# set_property PACKAGE_PIN N9  [get_ports {OUT_ADC_2V5[4]}]
# set_property PACKAGE_PIN E11  [get_ports {RST_ADC_2V5_N}]
# set_property PACKAGE_PIN E8  [get_ports {START_ADC_2V5_N}]
# set_property PACKAGE_PIN A16  [get_ports {HOLD1_2V5}]
# set_property PACKAGE_PIN A13  [get_ports {HOLD2_2V5}]
# set_property PACKAGE_PIN U11  [get_ports {MAROC_SELECT_2V5[2]}]
# set_property PACKAGE_PIN T6  [get_ports {MAROC_SELECT_2V5[1]}]
# set_property PACKAGE_PIN V11  [get_ports {MAROC_SELECT_2V5[0]}]
# set_property PACKAGE_PIN C6  [get_ports {CK_R_2V5}]
# set_property PACKAGE_PIN F9  [get_ports {D_R_2V5}]
# set_property PACKAGE_PIN A2  [get_ports {Q_R_2V5}]
# set_property PACKAGE_PIN A11  [get_ports {RST_R_2V5_N}]
# set_property PACKAGE_PIN N8  [get_ports {CK_SC_2V5}]
# set_property PACKAGE_PIN A12  [get_ports {D_SC_2V5}]
# set_property PACKAGE_PIN C8  [get_ports {Q_SC_2V5}]
# set_property PACKAGE_PIN F10  [get_ports {RST_SC_2V5_N}]
# set_property PACKAGE_PIN C12  [get_ports {CTEST_2V5}]
# set_property PACKAGE_PIN A14  [get_ports {EN_OTAQ_2V5}]
# set_property PACKAGE_PIN N17  [get_ports {GPIO_HDR_O[0]}]
# set_property PACKAGE_PIN M18  [get_ports {GPIO_HDR_O[1]}]
# set_property PACKAGE_PIN A3  [get_ports {GPIO_HDR_O[2]}]
# set_property PACKAGE_PIN L15  [get_ports {GPIO_HDR_O[3]}]
# set_property PACKAGE_PIN F15  [get_ports {GPIO_HDR_O[4]}]
# set_property PACKAGE_PIN B4  [get_ports {GPIO_HDR_O[5]}]
# set_property PACKAGE_PIN F13  [get_ports {GPIO_HDR_I[6]}]
# set_property PACKAGE_PIN P12  [get_ports {GPIO_HDR_I[7]}]
# set_property PACKAGE_PIN T10  [get_ports {HDMI0_CLK_N}]
# set_property PACKAGE_PIN R10  [get_ports {HDMI0_CLK_P}]
# set_property PACKAGE_PIN T7  [get_ports {HDMI0_DATA_N[0]}]
# set_property PACKAGE_PIN R7  [get_ports {HDMI0_DATA_P[0]}]
# set_property PACKAGE_PIN P6  [get_ports {HDMI0_DATA_N[1]}]
# set_property PACKAGE_PIN N5  [get_ports {HDMI0_DATA_P[1]}]
# set_property PACKAGE_PIN V8  [get_ports {HDMI0_DATA_N[2]}]
# set_property PACKAGE_PIN U8  [get_ports {HDMI0_DATA_P[2]}]
# #set_property PACKAGE_PIN T8  [get_ports {HDMI1_CLK_N}]
# #set_property PACKAGE_PIN R8  [get_ports {HDMI1_CLK_P}]
# #set_property PACKAGE_PIN P7  [get_ports {HDMI1_DATA_N[0]}]
# #set_property PACKAGE_PIN N6  [get_ports {HDMI1_DATA_P[0]}]
# #set_property PACKAGE_PIN N11  [get_ports {HDMI1_DATA_N[1]}]
# #set_property PACKAGE_PIN M11  [get_ports {HDMI1_DATA_P[1]}]
# #set_property PACKAGE_PIN V4  [get_ports {HDMI1_DATA_N[2]}]
# #set_property PACKAGE_PIN T4  [get_ports {HDMI1_DATA_P[2]}]
# set_property PACKAGE_PIN T8  [get_ports {HDMI1_SIGNALS_N[0]}]
# set_property PACKAGE_PIN R8  [get_ports {HDMI1_SIGNALS_P[0]}]
# set_property PACKAGE_PIN P7  [get_ports {HDMI1_SIGNALS_N[1]}]
# set_property PACKAGE_PIN N6  [get_ports {HDMI1_SIGNALS_P[1]}]
# set_property PACKAGE_PIN N11  [get_ports {HDMI1_SIGNALS_N[2]}]
# set_property PACKAGE_PIN M11  [get_ports {HDMI1_SIGNALS_P[2]}]
# set_property PACKAGE_PIN V4  [get_ports {HDMI1_SIGNALS_N[3]}]
# set_property PACKAGE_PIN T4  [get_ports {HDMI1_SIGNALS_P[3]}]

# Added from Magnus Loutit E-mail, 29/Oct/20
# -------------------------------------------------------------------------------------------------
# mars pm3: fmc lpc connector
# -------------------------------------------------------------------------------------------------
#FMC LANES BELOW ARE LISTED N THEN P
#N
#N
#P
#P

#FMC CLK0
set_property PACKAGE_PIN T4 [get_ports CK_40M_N]
set_property IOSTANDARD LVDS_25 [get_ports CK_40M_N]
set_property PACKAGE_PIN T5 [get_ports CK_40M_P]
set_property IOSTANDARD LVDS_25 [get_ports CK_40M_P]

#FMC CLK01
#set_property PACKAGE_PIN D3 [get_ports FMC_CLK1_M2C_N]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_CLK1_M2C_N]
#set_property PACKAGE_PIN E3 [get_ports FMC_CLK1_M2C_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_CLK1_M2C_P]

#FMC LA00
set_property PACKAGE_PIN P5 [get_ports MAROC_SELECT_2V5[0]]
set_property IOSTANDARD LVCMOS25 [get_ports MAROC_SELECT_2V5[0]]
set_property PACKAGE_PIN N5 [get_ports OR1_2V5[3]]
set_property IOSTANDARD LVCMOS25 [get_ports OR1_2V5[3]]

#FMC LA01
set_property PACKAGE_PIN P3 [get_ports MAROC_SELECT_2V5[1]]
set_property IOSTANDARD LVCMOS25 [get_ports MAROC_SELECT_2V5[1]]
set_property PACKAGE_PIN P4 [get_ports OR0_2V5[3]]
set_property IOSTANDARD LVCMOS25 [get_ports OR0_2V5[3]]

#FMC LA02
set_property PACKAGE_PIN N6 [get_ports MAROC_SELECT_2V5[2]]
set_property IOSTANDARD LVCMOS25 [get_ports MAROC_SELECT_2V5[2]]
set_property PACKAGE_PIN M6 [get_ports ADC_DAV_2V5[3]]
set_property IOSTANDARD LVCMOS25 [get_ports ADC_DAV_2V5[3]]

#FMC LA03
set_property PACKAGE_PIN L5 [get_ports HOLD2_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports HOLD2_2V5]
set_property PACKAGE_PIN L6 [get_ports OUT_ADC_2V5[3]]
set_property IOSTANDARD LVCMOS25 [get_ports OUT_ADC_2V5[3]]

#FMC LA04
set_property PACKAGE_PIN M1 [get_ports HOLD1_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports HOLD1_2V5]
set_property PACKAGE_PIN L1 [get_ports OR1_2V5[2]]
set_property IOSTANDARD LVCMOS25 [get_ports OR1_2V5[2]]

#FMC LA05
set_property PACKAGE_PIN N4 [get_ports EN_OTAQ_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports EN_OTAQ_2V5]
set_property PACKAGE_PIN M4 [get_ports OR0_2V5[2]]
set_property IOSTANDARD LVCMOS25 [get_ports OR0_2V5[2]]

#FMC LA06
set_property PACKAGE_PIN N1 [get_ports CTEST_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports CTEST_2V5]
set_property PACKAGE_PIN N2 [get_ports ADC_DAV_2V5[2]]
set_property IOSTANDARD LVCMOS25 [get_ports ADC_DAV_2V5[2]]

#FMC LA07
set_property PACKAGE_PIN M2 [get_ports START_ADC_2V5_N]
set_property IOSTANDARD LVCMOS25 [get_ports START_ADC_2V5_N]
set_property PACKAGE_PIN M3 [get_ports OUT_ADC_2V5[2]]
set_property IOSTANDARD LVCMOS25 [get_ports OUT_ADC_2V5[2]]

#FMC LA08
set_property PACKAGE_PIN R5 [get_ports RST_ADC_2V5_N]
set_property IOSTANDARD LVCMOS25 [get_ports RST_ADC_2V5_N]
set_property PACKAGE_PIN R6 [get_ports OR1_2V5[1]]
set_property IOSTANDARD LVCMOS25 [get_ports OR1_2V5[1]]

#FMC LA09
set_property PACKAGE_PIN R2 [get_ports RST_SC_2V5_N]
set_property IOSTANDARD LVCMOS25 [get_ports RST_SC_2V5_N]
set_property PACKAGE_PIN P2 [get_ports OR0_2V5[1]]
set_property IOSTANDARD LVCMOS25 [get_ports OR0_2V5[1]]

#FMC LA10
set_property PACKAGE_PIN T1 [get_ports Q_SC_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports Q_SC_2V5]
set_property PACKAGE_PIN R1 [get_ports ADC_DAV_2V5[1]]
set_property IOSTANDARD LVCMOS25 [get_ports ADC_DAV_2V5[1]]

#FMC LA11
set_property PACKAGE_PIN V1 [get_ports D_SC_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports D_SC_2V5]
set_property PACKAGE_PIN U1 [get_ports OUT_ADC_2V5[1]]
set_property IOSTANDARD LVCMOS25 [get_ports OUT_ADC_2V5[1]]

#FMC LA12
set_property PACKAGE_PIN T6 [get_ports CK_R_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports CK_R_2V5]
set_property PACKAGE_PIN R7 [get_ports OR1_2V5[0]]
 set_property IOSTANDARD LVCMOS25 [get_ports OR1_2V5[0]]

#FMC LA13
set_property PACKAGE_PIN U3 [get_ports RST_R_2V5_N]
set_property IOSTANDARD LVCMOS25 [get_ports RST_R_2V5_N]
set_property PACKAGE_PIN U4 [get_ports OR0_2V5[0]]
set_property IOSTANDARD LVCMOS25 [get_ports OR0_2V5[0]]

#FMC LA14
set_property PACKAGE_PIN T8 [get_ports Q_R_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports Q_R_2V5]
set_property PACKAGE_PIN R8 [get_ports ADC_DAV_2V5[0]]
set_property IOSTANDARD LVCMOS25 [get_ports ADC_DAV_2V5[0]]

#FMC LA15
set_property PACKAGE_PIN L4 [get_ports D_R_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports D_R_2V5]
set_property PACKAGE_PIN K5 [get_ports OUT_ADC_2V5[0]]
set_property IOSTANDARD LVCMOS25 [get_ports OUT_ADC_2V5[0]]

#FMC LA16 - Not used in this design
#set_property PACKAGE_PIN L3 [get_ports FMC_LA16_N]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA16_N]
#set_property PACKAGE_PIN K3 [get_ports FMC_LA16_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA16_P]

#FMC LA17
set_property PACKAGE_PIN F3 [get_ports HDMI1_SIGNALS_N[0]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_N[0]]
set_property PACKAGE_PIN F4 [get_ports HDMI1_SIGNALS_P[0]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_P[0]]

#FMC LA08
set_property PACKAGE_PIN D2 [get_ports HDMI0_CLK_N]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_CLK_N]
set_property PACKAGE_PIN E2 [get_ports HDMI0_CLK_P]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_CLK_P]

#FMC LA19
set_property PACKAGE_PIN G3 [get_ports HDMI1_SIGNALS_N[1]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_N[1]]
set_property PACKAGE_PIN G4 [get_ports HDMI1_SIGNALS_P[1]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_P[1]]

#FMC LA20
set_property PACKAGE_PIN C7 [get_ports HDMI1_SIGNALS_N[2]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_N[2]]
#set_property PACKAGE_PIN D8 [get_ports FMC_LA20_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA20_P]

#FMC LA21
set_property PACKAGE_PIN C1 [get_ports HDMI1_SIGNALS_N[3]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_N[3]]
set_property PACKAGE_PIN C2 [get_ports HDMI1_SIGNALS_P[3]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_P[3]]

#FMC LA22
set_property PACKAGE_PIN D7 [get_ports HDMI0_DATA_N[0]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_DATA_N[0]]
set_property PACKAGE_PIN E7 [get_ports HDMI0_DATA_P[0]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_DATA_P[0]]

#FMC LA23
set_property PACKAGE_PIN E1 [get_ports HDMI0_DATA_N[1]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_DATA_N[1]]
set_property PACKAGE_PIN F1 [get_ports HDMI0_DATA_P[1]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_DATA_P[1]]

#FMC LA24
set_property PACKAGE_PIN F6 [get_ports HDMI0_DATA_N[2]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_DATA_N[2]]
set_property PACKAGE_PIN G6 [get_ports HDMI0_DATA_P[2]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI0_DATA_P[2]]

#FMC LA25
#set_property PACKAGE_PIN H5 [get_ports FMC_LA25_N]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA25_N]
set_property PACKAGE_PIN H6 [get_ports HDMI1_SIGNALS_P[2]]
set_property IOSTANDARD LVDS_25 [get_ports HDMI1_SIGNALS_P[2]]

#FMC LA26
#set_property PACKAGE_PIN G2 [get_ports FMC_LA26_N]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA26_N]
#set_property PACKAGE_PIN H2 [get_ports FMC_LA26_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA26_P]

#FMC LA27
#set_property PACKAGE_PIN J2 [get_ports FMC_LA27_N]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA27_N]
#set_property PACKAGE_PIN J3 [get_ports FMC_LA27_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA27_P]

#FMC LA28
#set_property PACKAGE_PIN H4 [get_ports FMC_LA28_N]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA28_N]
#set_property PACKAGE_PIN J4 [get_ports FMC_LA28_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA28_P]

#FMC LA29
set_property PACKAGE_PIN G1 [get_ports CK_SC_2V5]
set_property IOSTANDARD LVCMOS25 [get_ports CK_SC_2V5]
#set_property PACKAGE_PIN H1 [get_ports FMC_LA29_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA29_P]

#FMC LA30
set_property PACKAGE_PIN K1 [get_ports OR1_2V5[4]]
 set_property IOSTANDARD LVCMOS25 [get_ports OR1_2V5[4]]
#set_property PACKAGE_PIN K2 [get_ports FMC_LA30_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA30_P]

#FMC LA31
set_property PACKAGE_PIN C5 [get_ports OR0_2V5[4]]
set_property IOSTANDARD LVCMOS25 [get_ports OR0_2V5[4]]
#set_property PACKAGE_PIN C6 [get_ports FMC_LA31_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA31_P]

#FMC LA32
set_property PACKAGE_PIN A1 [get_ports ADC_DAV_2V5[4]]
set_property IOSTANDARD LVCMOS25 [get_ports ADC_DAV_2V5[4]]
#set_property PACKAGE_PIN B1 [get_ports FMC_LA32_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA32_P]

#FMC LA33
set_property PACKAGE_PIN B4 [get_ports OUT_ADC_2V5[4]]
set_property IOSTANDARD LVCMOS25 [get_ports OUT_ADC_2V5[4]]
#set_property PACKAGE_PIN C4 [get_ports FMC_LA33_P]
#set_property IOSTANDARD LVCMOS25 [get_ports FMC_LA33_P]
