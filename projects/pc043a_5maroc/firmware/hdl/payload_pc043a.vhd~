--=============================================================================
--! @file top_5maroc_extclk_sp601.vhd
--=============================================================================
-- @brief Top-level design for ipbus Maroc test . You must edit this file to set the IP and MAC addresses
--
--! @details Based on ipbus_demo_sp601 by Dave Newbold, 23/2/11
--! This version is for xc6slx16 on Xilinx SP601 eval board
--! Uses the s6 soft TEMAC core with GMII inteface to an external Gb PHY
--! You will need a license for the core
--
--! @author David Cussans, 16/12/11
--
--! changes: 6/8/12   - edited for  IPbusFirmware_pre_131_RAL
--!          13/8/12  - edited to have an external 31.250MHz clock
--!          13/8/12  - edited to have an external 25.000MHz clock
--!          12/10/12 - add generation of 25MHz clock and triggers from 200MHz
--!                     clock
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ipbus.ALL;
use work.ipbus_bus_decl.all;
use work.fiveMaroc.all;
use work.emac_hostbus_decl.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity top_extclk is
  generic (
    g_NMAROC : positive := 5);
  port(
	sysclk_p, sysclk_n : in STD_LOGIC;
	leds: out STD_LOGIC_VECTOR(3 downto 0);
	gmii_gtx_clk, gmii_tx_en, gmii_tx_er : out STD_LOGIC;
	gmii_txd : out STD_LOGIC_VECTOR(7 downto 0);
	gmii_rx_clk, gmii_rx_dv, gmii_rx_er: in STD_LOGIC;
	gmii_rxd : in STD_LOGIC_VECTOR(7 downto 0);
	phy_rstb : out STD_LOGIC;
	dip_switch: in std_logic_vector(3 downto 0);
        -- Connections to MAROC
        CK_40M_P: out STD_LOGIC;
        CK_40M_N: out STD_LOGIC;
        -- CK_40M_OUT_2V5: in STD_LOGIC; -- not currently used
        HOLD2_2V5: out STD_LOGIC;
        HOLD1_2V5: out STD_LOGIC;
        OR1_2V5: in STD_LOGIC_VECTOR(g_NMAROC-1 downto 0);
        OR0_2V5: in STD_LOGIC_VECTOR(g_NMAROC-1 downto 0);
        -- bodge for now, just to get code to build
--        OR1_2V5: in STD_LOGIC_VECTOR(g_NMAROC-2 downto 0);
--        OR0_2V5: in STD_LOGIC_VECTOR(g_NMAROC-2 downto 0);
        EN_OTAQ_2V5: out STD_LOGIC;
        CTEST_2V5: out STD_LOGIC;
        ADC_DAV_2V5: in STD_LOGIC_VECTOR(g_NMAROC-1 downto 0);
        OUT_ADC_2V5: in STD_LOGIC_VECTOR(g_NMAROC-1 downto 0);
        START_ADC_2V5_N: out STD_LOGIC;
        RST_ADC_2V5_N: out STD_LOGIC;
        RST_SC_2V5_N: out STD_LOGIC;
        Q_SC_2V5: in STD_LOGIC;
        D_SC_2V5: out STD_LOGIC;
        RST_R_2V5_N: out STD_LOGIC;
        Q_R_2V5: in STD_LOGIC;
        D_R_2V5: out STD_LOGIC;
        CK_R_2V5: out STD_LOGIC;
        CK_SC_2V5: out STD_LOGIC;
        -- lines to select marocs for setup and control
        MAROC_SELECT_2V5: out STD_LOGIC_VECTOR(2 downto 0);
        -- HDMI signals for Clock and trigger I/O
        -- For tests declare all as output
        HDMI0_CLK_P: in std_logic;      -- Need an input clock of 40MHz on J28
        HDMI0_CLK_N: in std_logic;
        HDMI0_DATA_P: in std_logic_vector(2 downto 0);
        HDMI0_DATA_N: in std_logic_vector(2 downto 0);
        --HDMI1_CLK_P: in std_logic;
        --HDMI1_CLK_N: in std_logic;        
        --HDMI1_DATA_P: in std_logic_vector(2 downto 0);
        --HDMI1_DATA_N: in std_logic_vector(2 downto 0);
        --HDMI1_CLK_P: inout std_logic;
        --HDMI1_CLK_N: inout std_logic;        
        --HDMI1_DATA_P: inout std_logic_vector(2 downto 0);
        --HDMI1_DATA_N: inout std_logic_vector(2 downto 0);
        HDMI1_SIGNALS_P : inout std_logic_vector(3 downto 0);
        HDMI1_SIGNALS_N : inout std_logic_vector(3 downto 0);
        
        -- GPIO header for debugging:
        GPIO_HDR_O: out STD_LOGIC_VECTOR(5 downto 0);
        GPIO_HDR_I: in STD_LOGIC_VECTOR(7 downto 6)
	);
end top_extclk;

architecture rtl of top_extclk is

	signal clk125, clk_fast, ipb_clk, ipb_clk_n , rst_125, rst_ipb, onehz : STD_LOGIC;
        signal clock_status : std_logic_vector(c_NCLKS+1 downto 0) := ( others => '0' );  --! locked/status lines for PLL, DCM, BUFPLLs
	signal mac_txd, mac_rxd : STD_LOGIC_VECTOR(7 downto 0);
	signal mac_txdvld, mac_txack, mac_rxclko, mac_rxdvld, mac_rxgoodframe, mac_rxbadframe : STD_LOGIC;
	signal ipb_master_out : ipb_wbus;
	signal ipb_master_in : ipb_rbus;
	signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
	signal hostbus_in: emac_hostbus_in;
	signal hostbus_out: emac_hostbus_out;

        -- Maroc signals
        signal ck_40M : std_logic;      -- 40Mhz clock for Maroc ADC
        signal maroc_input_signals : maroc_input_signals; -- record containing signals from FPGA to MAROC
        signal maroc_output_signals : maroc_output_signals; -- record containing signals from Maroc to FPGA

        -- Signals to/from HDMI
        signal hdmi_input_signals : hdmi_input_signals;  -- record containing signals into FPGA via HDMI connectors
        signal hdmi_output_signals : hdmi_output_signals;  -- record containing signals out of FPGA via HDMI connectors
        signal CK_40M_INT_P , CK_40M_INT_N : std_logic; 

        signal sysclk : std_logic;      -- ! currently a dummy signal
        signal externalHdmiTrigger : std_logic;  -- ! Async trigger, via HDMI connector
        signal ck_25M_internally_generated, triggers_internally_generated : std_logic;
        --signal clk_2x_fast : std_logic; 
        --signal clk_fast_strobe : std_logic;
        -- try for multiple 500MHz clocks....
        signal clk_2x_fast : std_logic_vector(c_NCLKS-1 downto 0); 
        signal clk_fast_strobe : std_logic_vector(c_NCLKS-1 downto 0); 
         
begin


        ext_trig_buf :IBUFGDS
          port map
          (O  => externalHdmiTrigger,
           I  => HDMI0_DATA_P(1),
           IB => HDMI0_DATA_N(1)
           );

        -- connect up the HDMI data lines to the hdmi_input_signals record.
        hdmi_input_signals.HDMI0_DATA_P(0) <= HDMI0_DATA_P(0);
        hdmi_input_signals.HDMI0_DATA_P(2) <= HDMI0_DATA_P(2);
        hdmi_input_signals.HDMI0_DATA_N(0) <= HDMI0_DATA_N(0);
        hdmi_input_signals.HDMI0_DATA_N(2) <= HDMI0_DATA_N(2);
        
        -- Differential output buffer for clock to MAROC
        -- ( currently IPBus clock 31.25MHz)
        OBUFDS_inst : OBUFDS
          generic map (
            IOSTANDARD => "DEFAULT")
          port map (
            O => CK_40M_P,    -- Diff_p output 
            OB => CK_40M_N,   -- Diff_n output 
            I => ck_40M      -- Buffer input
            );

--        -- use DDR register to drive clock to GPIO pin.
--        gpio_clock_buf  : ODDR2
--          port map (
--            Q => gpio_hdr_o(1) , -- 1-bit output data
--            C0 => ck_25M_internally_generated, -- 1-bit clock input
--            C1 => not ck_25M_internally_generated , -- 1-bit clock input
--            CE => '1',  -- 1-bit clock enable input
--            D0 => '0',   -- 1-bit data input (associated with C0)
--            D1 => '1',   -- 1-bit data input (associated with C1)
--            R => '0',    -- 1-bit reset input
--            S => '0'     -- 1-bit set input
--            );
        
        -- Use a DDR output register to get from clock net onto output. 
        maroc_clock_buf  : ODDR2
          port map (
            Q => CK_40M, -- 1-bit output data
            C0 => ipb_clk, -- 1-bit clock input
            C1 => ipb_clk_n, -- 1-bit clock input
            CE => '1',  -- 1-bit clock enable input
            D0 => '0',   -- 1-bit data input (associated with C0)
            D1 => '1',   -- 1-bit data input (associated with C1)
            R => '0',    -- 1-bit reset input
            S => '0'     -- 1-bit set input
            );

        -- Connect the top level signals to the maroc_signals record
        EN_OTAQ_2V5                   <= maroc_input_signals.EN_OTAQ_2V5;
        CTEST_2V5                     <= maroc_input_signals.CTEST_2V5       ;
        HOLD2_2V5                     <= maroc_input_signals.HOLD2_2V5;
        HOLD1_2V5                     <= maroc_input_signals.HOLD1_2V5;
        START_ADC_2V5_N               <= maroc_input_signals.START_ADC_2V5_N ;
        RST_ADC_2V5_N                 <= maroc_input_signals.RST_ADC_2V5_N   ;
        CK_SC_2V5                     <= maroc_input_signals.CK_SC_2V5       ;
        RST_SC_2V5_N                  <= maroc_input_signals.RST_SC_2V5_N    ;
        D_SC_2V5                      <= maroc_input_signals.D_SC_2V5        ;
        CK_R_2V5                      <= maroc_input_signals.CK_R_2V5        ;
        RST_R_2V5_N                   <= maroc_input_signals.RST_R_2V5_N     ;
        D_R_2V5                       <= maroc_input_signals.D_R_2V5         ;
        MAROC_SELECT_2V5              <= maroc_input_signals.MAROC_SELECT    ;
        
        -- Signals from MAROC to FPGA

        -- maroc_output_signals.CK_40M_OUT_2V5  <= CK_40M_OUT_2V5; -- not
        -- currently used
        
       maroc_output_signals.OR1_2V5         <= OR1_2V5;
       maroc_output_signals.OR0_2V5         <= OR0_2V5;
        -- bodge - disconnect or1_2v5(4) to get code to synthesize.
       -- maroc_output_signals.OR1_2V5(g_NMAROC-2 downto 0)         <= OR1_2V5;
       -- maroc_output_signals.OR0_2V5(g_NMAROC-2 downto 0)         <= OR0_2V5;
       -- maroc_output_signals.OR1_2V5(g_NMAROC-1)         <= '0';
       -- maroc_output_signals.OR0_2V5(g_NMAROC-1)         <= '0';

        -- end of bodge
        -- ADC signals
        maroc_output_signals.ADC_DAV_2V5     <= ADC_DAV_2V5;
        maroc_output_signals.OUT_ADC_2V5     <= OUT_ADC_2V5;
        -- SC shift register
        maroc_output_signals.Q_SC_2V5        <= Q_SC_2V5;
        -- R shift register
        maroc_output_signals.Q_R_2V5         <= Q_R_2V5;


--	DCM clock generation for internal bus, ethernet
	--clocks: entity work.clocks_s6_extclk port map(
        clocks: entity work.clocks_s6_extclk_multiclk_xtal
          generic map (
            g_NCLKS => c_NCLKS)
          port map(
          extclk_p => HDMI0_CLK_P,
          extclk_n => HDMI0_CLK_N,
          sysclk_p => sysclk_p,
          sysclk_n => sysclk_n,
          clko_125 => clk125,
          clko_fast => clk_fast,
          clko_2x_fast  => clk_2x_fast,
          clko_fast_strobe => clk_fast_strobe,
          clko_ipb => ipb_clk,
          clko_ipb_n => ipb_clk_n,
          clock_status => clock_status,
          rsto_125 => rst_125,
          rsto_ipb => rst_ipb,
          onehz => onehz
          );
		
	leds <= ('0', '0', clock_status(0), onehz);

        
--	Ethernet MAC core and PHY interface
-- In this version, consists of hard MAC core and GMII interface to external PHY
-- Can be replaced by any other MAC / PHY combination

 	eth: entity work.eth_s6_gmii port map(
		clk125 => clk125,
		rst => rst_125,
		gmii_gtx_clk => gmii_gtx_clk,
		gmii_tx_en => gmii_tx_en,
		gmii_tx_er => gmii_tx_er,
		gmii_txd => gmii_txd,
		gmii_rx_clk => gmii_rx_clk,
		gmii_rx_dv => gmii_rx_dv,
		gmii_rx_er => gmii_rx_er,
		gmii_rxd => gmii_rxd,
		txd => mac_txd,
		txdvld => mac_txdvld,
		txack => mac_txack,
		rxd => mac_rxd,
		rxclko => mac_rxclko,
		rxdvld => mac_rxdvld,
		rxgoodframe => mac_rxgoodframe,
		rxbadframe => mac_rxbadframe,
		hostbus_in => hostbus_in,
		hostbus_out => hostbus_out
	);
	
	phy_rstb <= '1';
	
-- ipbus control logic

	ipbus: entity work.ipbus_ctrl_udponly port map(
		ipb_clk => ipb_clk,
		rst_ipb => rst_ipb,
		rst_macclk => rst_125,
		mac_txclk => clk125,
		mac_rxclk => mac_rxclko,
		mac_rxd => mac_rxd,
		mac_rxdvld => mac_rxdvld,
		mac_rxgoodframe => mac_rxgoodframe,
		mac_rxbadframe => mac_rxbadframe,
		mac_txd => mac_txd,
		mac_txdvld => mac_txdvld,
		mac_txack => mac_txack,
		ipb_out => ipb_master_out,
		ipb_in => ipb_master_in,
		mac_addr => mac_addr,
		ip_addr => ip_addr
	);
       
	
	mac_addr <= X"020ddba115" & dip_switch & X"0"; -- Careful here, arbitrary addresses do not always work
	ip_addr   <= X"c0a8c8" & dip_switch & X"0"; -- 192.168.200.X


-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

	slaves: entity work.slaves_5maroc port map(
		ipb_clk => ipb_clk,
                ipb_clk_n => ipb_clk_n,
		rst => rst_ipb,
		ipb_in => ipb_master_out,
		ipb_out => ipb_master_in,
                hostbus_out => hostbus_in,
		hostbus_in => hostbus_out,
                clock_status => clock_status,
                -- Top level ports from here
                clk_fast_i => clk_fast,
--                clk_fast_i => clk125,   -- having problems with low latency
                clk_2x_fast_i => clk_2x_fast,
                clk_fast_strobe_i => clk_fast_strobe,
                externalHdmiTrigger_a_i => externalHdmiTrigger,
                externalTrigger_o => open,  -- need to connect to GPIO...
                maroc_input_signals => maroc_input_signals,
                maroc_output_signals => maroc_output_signals,
                hdmi_input_signals => hdmi_input_signals,
                hdmi_output_signals => hdmi_output_signals,
                hdmi_inout_signals_p => hdmi1_signals_p,
                hdmi_inout_signals_n => hdmi1_signals_n,
                gpio_o => gpio_hdr_o(5 downto 3),
                gpio_i => gpio_hdr_i
	);


--      signal_generation: entity work.generate_test_signals
--          port map (
--            sysclk       => sysclk,
--            test_clk_25M => ck_25M_internally_generated,
--            test_trigger => triggers_internally_generated
--            );
        
--        gpio_hdr_o(0) <= CK_40M ;       --! actually the IPBus clock...
        gpio_hdr_o(0) <= externalHdmiTrigger ;

        --gpio_hdr_o(1) <= ck_25M_internally_generated;
        p_1hz_out :process (ipb_clk)
        BEGIN
        if rising_edge(ipb_clk) then
          gpio_hdr_o(1) <= onehz;
          end if;
        end process;
          
        -- invert sense of triggers to be compatible with Scott Kolya's fanout
        -- which was designed for NIM.
        gpio_hdr_o(2) <= not triggers_internally_generated;
  
end rtl;

