--=============================================================================
--! @file marocADC_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
--! Package containing type definition and constants for MAROC interface
use work.maroc.ALL;
--! Package containing type definition and constants for IPBUS
use work.ipbus.all;

--! Use UNISIM for Xilix primitives
Library UNISIM;
use UNISIM.vcomponents.all;


-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: marocADC_rtl (marocADC / rtl)
--
--! @brief Interfaces to Maroc ADC\n
--! when start_p_i pulses high issues a reset to ADC then a startADC signal.
--! status_o goes high during conversion.
--! Waits for ADC data valid to return low again before dropping status_o
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 4\1\2012
--
--! @version v0.1
--
--! @details
--! Controls the physical signal lines to and from MAROC.
--! Deserializes the data coming from the ADCs, and puts into Dual-Port-RAM
--! Each event is preceeded by a trigger number and a timestamp .
--!
--! <b>Dependencies:</b>\n
--! Instantiates marocADCFSM
--!
--! <b>References:</b>\n
--! referenced by marocADC \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! 17/Feb/2012 DGC Move to storing data in a DPR. Change ports accordingly\n
--! 
-------------------------------------------------------------------------------
--! @todo Include trigger number and timestamp \n
--
---------------------------------------------------------------------------------

--============================================================================
--! Entity declaration for marocADC
--============================================================================
entity marocADC is
  generic(
    g_ADDRWIDTH   : positive;
    g_BUSWIDTH    : positive := 32
    );
  port(
    clk_i        : in STD_LOGIC;
    reset_i      : in STD_LOGIC;

    start_p_i    : in STD_LOGIC;        --! Pulse high to start conversion.
    end_p_o      : out STD_LOGIC;       --! Pulses high at end of conversion
    status_o     : out STD_LOGIC;       --! goes high during conversion

    ipbus_i : in  ipb_wbus;             --! Signals from IPBus master for data
    ipbus_o : out ipb_rbus;             --! Signals to IPBus master

    --! Next location in DPR circular buffer that will get written to
    write_pointer_o : out STD_LOGIC_VECTOR(g_ADDRWIDTH-1 downto 0);
    
    --! Number of bits shifted in  
    bitcount_o   : out STD_LOGIC_VECTOR( 9 downto 0 );  

    triggerNumber_i   : in std_logic_vector(g_BUSWIDTH-1 downto 0);
    timeStamp_i       : in std_logic_vector(g_BUSWIDTH-1 downto 0);

    -- Signals to MAROC
    START_ADC_N_O : out std_logic;
    RST_ADC_N_O   : out std_logic;
    ADC_DAV_I     : in std_logic;
    OUT_ADC_I     : in std_logic
      
    );
	
end marocADC;

--============================================================================
--! architecture declaration
--============================================================================
architecture rtl of marocADC is

  signal s_status : std_logic;   --! Control line from ADC interface. Goes high when conversion in progress

  --! Shift register
  signal s_shiftReg : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');
  signal s_dataToDPR : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');

  signal s_shiftRegCounter : unsigned(bitcount_o'range) := (others => '0');  --! Counts bits shifted in
  
  signal s_reset_sr : std_logic := '0';  -- ! Driven by ADC FSM. When high resets the shift register and bit counter
  signal s_reset_sr_d1 : std_logic := '0';  -- ! s_reset_sr delayed one clk_i cycle
--  signal s_reset_sr_d2 : std_logic := '0';  -- ! s_reset_sr_d1 delayed one clk_i cycle

  --! DPR signals
--  signal s_wen , s_wen_d1 : std_logic := '0';      -- ! Write enable for DPR
  signal s_wen  : std_logic := '0';      -- ! Write enable for DPR
  signal s_shiftRegFull , s_shiftRegFull_d1 : std_logic := '0';      -- ! Write enable for DPR
  signal s_writeAddr : unsigned(write_pointer_o'range) := (others => '0');   --! Address into write-port of DPR
  -- signal s_readAddr : unsigned(addr_i'range);  -- ! Read address in DPR
  signal  s_RegisteredEventTimestamp : std_logic_vector( timeStamp_i'range) := (others => '0');

begin


  --! Capture the timestamp at the start of the event.
  p_captureTimestamp: process (clk_i)
  begin  -- process p_captureTimestamp
    if rising_edge(clk_i) and (start_p_i = '1') then  -- rising clock edge
       s_RegisteredEventTimestamp <= timeStamp_i;
    end if;
  end process p_captureTimestamp;
  
  --==========================================================================
  -- purpose: Shift register to deserialize data from MAROC
  -- type   : combinational
  -- inputs : clk_i , out_adc_i
  -- outputs: s_shiftReg
  --==========================================================================
  p_shiftReg: process (clk_i , out_adc_i)
  begin  -- process p_shiftReg
    if rising_edge(clk_i) then

      if (reset_i = '1') then
        s_writeAddr <= (others => '0');
        s_shiftRegCounter <= (others => '0');
      elsif (s_reset_sr='1') then
        s_shiftRegCounter <= (others => '0');
      elsif adc_dav_i = '1' then
        s_shiftReg <= s_shiftReg(s_shiftReg'left-1 downto 0) & out_adc_i;
        s_shiftRegCounter <=  s_shiftRegCounter + 1;
      end if;

      -- Increment write address if a complete word has been shifted or if end
      -- of ADC readout has been reached.
      s_shiftRegFull_d1 <= s_shiftRegFull;


      if (s_wen = '1') then
        s_writeAddr <= s_writeAddr + 1;
      end if;

      --! Delay reset shift-reg signal to act as flag for
      --! writing timestamp into DPR.
      s_reset_sr_d1 <= s_reset_sr;
      
    end if;                             -- rising_edge(clk_i)
    
  end process p_shiftReg;

  --! Generate write enable for DPRAM ( also increments write address
  s_shiftRegFull <= '1' when (s_shiftRegCounter(4 downto 0) = "11111" ) else '0';
  
  s_wen <= '1' when s_shiftRegFull_d1='1' or
           (s_reset_sr = '1') or (s_reset_sr_d1 = '1')
           else '0';

  s_dataToDPR <= triggerNumber_i when (s_reset_sr = '1') else
                 s_RegisteredEventTimestamp when (s_reset_sr_d1 = '1') else
                 s_shiftReg ;
  
  -- Instantiate finite state machine that drives control lines.
  cmp_marocADC_fsm: entity work.marocADCFSM 
   port map (
      clk_system_i   => clk_i,
      rst_i          => reset_i,
      start_p_i      => start_p_i,
      adc_dav_i      => adc_dav_i,
      reset_sr_o     => s_reset_sr,
      start_adc_n_o  => start_adc_n_o,
      status_o       => status_o
      ); 

  -- Instantiate Dual Port RAM
  cmp_capbuf: entity work.ipbusDPRAM
    generic map (
      data_width => g_BUSWIDTH,
      ram_address_width => g_ADDRWIDTH )
    Port map (
--      Wren_a    =>  s_wen_d1,
      Wren_a    =>  s_wen,
      clk       =>  clk_i,

      -- Write port
      address_a =>  std_logic_vector(s_writeAddr),      
      data_a     =>  s_dataToDPR,

      -- IPBus for read-port
      ipbus_i => ipbus_i,
      ipbus_o => ipbus_o

      );

  -- Connect internal signals to output ports
  
  RST_ADC_N_O   <= not s_reset_sr;

  bitcount_o    <= std_logic_vector(s_shiftRegCounter);

  write_pointer_o <= std_logic_vector(s_writeAddr);
  
end rtl;
