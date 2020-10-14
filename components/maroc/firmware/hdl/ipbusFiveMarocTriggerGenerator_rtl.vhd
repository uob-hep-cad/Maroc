--=============================================================================
--! @file ipbusFiveMarocTriggerGenerator_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;
--! Package containing type definition and constants for MAROC interface
use work.fiveMaroc.all;
--! Package containing type definition and constants for IPBUS
use work.ipbus.all;

--library UNISIM;
--use UNISIM.vcomponents.all;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: ipbusFiveMarocTriggerGenerator_rtl (ipbusFiveMarocTriggerGenerator / rtl)
--
--! @brief Interfaces between IPBus and Maroc TriggerGenerator\n
--! Addresses ( with respect to base address)\n
--! 0x000 : Status register. Writing 1 to bit-0 resets trigger and timestamp counters\n
--! 0x001 : Manual trigger register. Write 1 to bit 0 to cause internal trigger\n
--! 0x002 : HOLD1 delay. 5 bits, 5ns ticks\n
--! 0x003 : HOLD2 delay. 5 bits, 5ns ticks\n
--! 0x004 : Trigger select register. 7 bits.\n
--!        bit 0 = internal(software)-trigger , 1 = external(HDMI)-trigger\n, bit2 = or1 , bit3=or2\n
--!        bit4 = OR1 from neighbouring FPGA , bit5= OR2 from neigbouring FPGA, bit6=external(GPIO)-trigger\n
--! 0x005 : Conversion counter - read = number of ADC conversions since last reset.\n
--! 0x006 : Timestamp - read = number of clock cycles since last reset\n
--! 0x007 : Write pointer of fine-grain timestamp buffer DPR\n
--! 0x008 : bit 0 = type-A/type-B control for OR1/OR2 I/O. \n
--!         Bit-0=0  --> board is type-A ,\n
--!         Bit-0=1  --> board is type-B . \n
--!         bit 1 = enable LVDS transmitters.  Bit-0 = disable , Bit-1 = enable.\n
--!         N.B. In a cassette, if J27 is connected by HDMI cable, one board must be type-A one type-B\n
--!         N.B. To avoid contention at start up when both default to type-set direction first, then enable transmitters.\n
--! 0x010 : Number of triggers from OR1[0] since last reset\n
--! 0x011 : Number of triggers from OR1[1] since last reset\n
--! 0x012 : Number of triggers from OR1[2] since last reset\n
--! 0x013 : Number of triggers from OR1[3] since last reset\n
--! 0x014 : Number of triggers from OR1[4] since last reset\n
--! 0x020 : Number of triggers from OR2[0] since last reset\n
--! 0x021 : Number of triggers from OR2[1] since last reset\n
--! 0x022 : Number of triggers from OR2[2] since last reset\n
--! 0x023 : Number of triggers from OR2[3] since last reset\n
--! 0x024 : Number of triggers from OR2[4] since last reset\n
--! 0x200 - 0x3FF : Buffer for trigger information
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 21\1\2012
--
--! @version v0.1
--
--! @details
--!
--!
--! <b>Dependencies:</b>\n
--! Instantiates marocTriggerGenerator
--!
--! <b>References:</b>\n
--! referenced by slaves \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! 9/March/2012 DGC Adding trigger counter and timestamp\n
--! 12/Feb/2013 DGC Adding counter for OR1 , OR2 inputs\n
--! 10/May/2013 DGC Moving to two IPBuses, one for control, one for data.
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! CHANGEME - Protect all the clock crossing I introduced by separating clk_1x and ipb_clk  \n
--
---------------------------------------------------------------------------------
--


entity ipbusFiveMarocTriggerGenerator is
  generic(
    g_BUSWIDTH         : positive := 32;
    g_NMAROC           : positive := 5;
    g_NCLKS            : positive := 3;
    g_NHDMI_SIGNALS    : positive := 4;
    g_NTRIGGER_SOURCES : positive := 7  -- ! Number of different trigger sources
    );
  port(
    clk_1x_i           : in  std_logic;
    ipb_clk_i         : in std_logic;
    reset_i         : in  std_logic;
    control_ipbus_i : in  ipb_wbus;
    control_ipbus_o : out ipb_rbus;
    data_ipbus_i    : in  ipb_wbus;
    data_ipbus_o    : out ipb_rbus;

    logic_reset_i : in std_logic;       --! Reset logic signal. High for one

    -- Signals to MAROC and ADC controller
    adcBusy_i            : in  std_logic;
    adcConversionStart_o : out std_logic;
    triggerNumber_o      : out std_logic_vector(g_BUSWIDTH-1 downto 0);
    timeStamp_o          : out std_logic_vector(g_BUSWIDTH-1 downto 0);

    clk_8x_i        : in std_logic;
    clk_16x_i     : in std_logic_vector(g_NCLKS-1 downto 0);  --! twice speed of fast clock

    externalHdmiTrigger_a_i : in  std_logic;
    externalGpioTrigger_a_i : in  std_logic;
    externalTrigger_o       : out std_logic;
    or1_a_i                 : in  std_logic_vector(g_NMAROC-1 downto 0);
    or2_a_i                 : in  std_logic_vector(g_NMAROC-1 downto 0);

    -- Signals to/from neighbouring FPGA
    hdmi_inout_signals_p : inout std_logic_vector(g_NHDMI_SIGNALS-1 downto 0);
    hdmi_inout_signals_n : inout std_logic_vector(g_NHDMI_SIGNALS-1 downto 0);

    -- Hold signals for MAROC sample/hold
    hold1_o : out std_logic;
    hold2_o : out std_logic;

    -- Debugging/status signals
    fsmStatus_o : out std_logic_vector(1 downto 0);
    or1_from_neighbour_o : out std_logic; -- signal from neighbouring board
    or1_to_neighbour_o   : out std_logic -- signal to neighbouring board.
    
    
    );

end ipbusFiveMarocTriggerGenerator;

architecture rtl of ipbusFiveMarocTriggerGenerator is

  constant c_OR_COUNTER_SELECT_WIDTH     : positive := 3;  --! need to address 5 counters
  constant c_TIMESTAMP_BUFFER_ADDR_WIDTH : positive := 9;  -- ! Bit that is set high to indicate that the timestamp buffer is being addressed
--  constant c_NTRIGGER_SOURCES : positive := 6; -- ! Number of differenet trigger sources

  signal s_internalTrigger_p         : std_logic;
  signal s_triggerSourceSelect       : std_logic_vector(g_NTRIGGER_SOURCES-1 downto 0) := (others => '0');
  signal s_hold1Delay , s_hold2Delay : std_logic_vector(g_NMAROC-1 downto 0)           := (others => '0');

  signal s_ack , s_ack_d1 : std_logic;

  signal s_counter_reset , s_counter_reset_ipb : std_logic;
  signal s_conversion_counter                  : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');
  signal s_timeStamp                           : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');
  signal s_finetimestamp_buffer_data           : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');
  signal s_triggerCounterOR1                   : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');
  signal s_triggerCounterOR2                   : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');
  signal s_adcConversionStart                  : std_logic;  -- internal coopy of adcConversionStart_o
  signal s_fineTimeStampWritePointer           : std_logic_vector(c_TIMESTAMP_BUFFER_ADDR_WIDTH-1 downto 0);

  signal s_or1_ipbclk , s_or1_fast_clk : std_logic_vector(g_NMAROC-1 downto 0);  -- ! OR1 inputs synchronized and stretched/shortened onto one pulse of ipbus clock
  signal s_or2_ipbclk , s_or2_fast_clk : std_logic_vector(g_NMAROC-1 downto 0);  -- ! OR2 inputs synchronized and stretched/shortened onto one pulse of ipbus clock
  signal s_or_ipbclk , s_or_fast_clk   : std_logic_vector(2*g_NMAROC-1 downto 0);  -- ! OR1 and OR2 outputs concatenated.
  signal s_or_async                    : std_logic_vector(2*g_NMAROC-1 downto 0);  -- ! combination of or1 and or2
  signal s_typeA_typeB_flag            : std_logic := '0';  -- ! 0 means board is "type-A" w.r.t. trigger I/O to neighbour.  
  signal s_enable_hdmi_lvds            : std_logic := '0';  -- Set high to turn on LVDS outputs. By default turned off.

--  signal s_signal_from_iobufds , s_signal_to_iobufds , s_set_iobufds_direction : std_logic_vector(g_NHDMI_SIGNALS-1 downto 0) := (others => '0');

--  signal s_or1_to_neighbour , s_or2_to_neighbour     : std_logic := '0';  -- ! OR of the OR1 , OR2 signals
  signal s_or1_from_neighbour , s_or2_from_neighbour : std_logic := '0';  --! OR1,OR2 combination from neigbouring FPGA
  signal s_ipb_strobe_d1 , s_ipb_strobe_d2           : std_logic := '0';  -- used to generate ACK
  
begin

  -- read/write to registers storing data to/from MAROC and to control reg.
  p_addressDecode : process(ipb_clk_i)
  begin

    -- Register the accesses....
    if rising_edge(ipb_clk_i) then
      -- Decode the address bits to see if we are addressing trigger counters or
      -- control registers
      case control_ipbus_i.ipb_addr(c_OR_COUNTER_SELECT_WIDTH+2 downto
                                    c_OR_COUNTER_SELECT_WIDTH+1) is

        --! When top address bits zero, address setup/control regs
        when "00" =>

          case control_ipbus_i.ipb_addr(c_OR_COUNTER_SELECT_WIDTH downto 0) is
            
            when "0000" =>                          -- status register
              control_ipbus_o.ipb_rdata(0) <= '0';  --dummy for now
              
            when "0010" =>              -- hold1 delay
              control_ipbus_o.ipb_rdata(s_hold1Delay'range)                      <= s_hold1Delay;
              control_ipbus_o.ipb_rdata(g_BUSWIDTH-1 downto s_hold1Delay'high+1) <= (others => '0');
              
            when "0011" =>              -- hold2 delay
              control_ipbus_o.ipb_rdata(s_hold2Delay'range)                      <= s_hold2Delay;
              control_ipbus_o.ipb_rdata(g_BUSWIDTH-1 downto s_hold2Delay'high+1) <= (others => '0');
              
            when "0100" =>              -- triger source select
              control_ipbus_o.ipb_rdata(s_triggerSourceSelect'range)                      <= s_triggerSourceSelect;
              control_ipbus_o.ipb_rdata(g_BUSWIDTH-1 downto s_triggerSourceSelect'high+1) <= (others => '0');

            when "0101" =>
              control_ipbus_o.ipb_rdata <= s_conversion_counter;
              
            when "0110" =>
              control_ipbus_o.ipb_rdata <= s_timeStamp;

            when "0111" =>
              control_ipbus_o.ipb_rdata(s_fineTimeStampWritePointer'range)                        <= s_fineTimeStampWritePointer;
              control_ipbus_o.ipb_rdata(g_BUSWIDTH-1-1 downto s_fineTimeStampWritePointer'high+1) <= (others => '0');

            when "1000" =>
              control_ipbus_o.ipb_rdata(0)                       <= s_typeA_typeB_flag;
              control_ipbus_o.ipb_rdata(1)                       <= s_enable_hdmi_lvds;
              control_ipbus_o.ipb_rdata(g_BUSWIDTH-1-1 downto 2) <= (others => '0');

            when others => null;
                           
          end case;

          --! When top address bits = 01, address OR1 counters
        when "01" =>
          control_ipbus_o.ipb_rdata <= s_triggerCounterOR1;

          --! When top address bits = 01, address OR2 counters          
        when "10" =>
          control_ipbus_o.ipb_rdata <= s_triggerCounterOR2;

        when others => null;
                       
      end case;

    end if;  -- End of rising edge clocked

    
  end process;  -- p_addressDecode

  p_write : process (ipb_clk_i)
  begin  -- process p_write
    if rising_edge(ipb_clk_i) then          -- rising clock edge
      -- Handle writing
      if control_ipbus_i.ipb_strobe = '1' and control_ipbus_i.ipb_write = '1' then
        case control_ipbus_i.ipb_addr(3 downto 0) is

          when "0010" =>                -- hold1 delay
            s_hold1Delay <= control_ipbus_i.ipb_wdata(s_hold1Delay'range);
            
          when "0011" =>                -- hold2 delay
            s_hold2Delay <= control_ipbus_i.ipb_wdata(s_hold2Delay'range);
          when "0100" =>                -- triger source select
            s_triggerSourceSelect <=
              control_ipbus_i.ipb_wdata(s_triggerSourceSelect'range);
          when "1000" =>
            s_typeA_typeB_flag <= control_ipbus_i.ipb_wdata(0);
            s_enable_hdmi_lvds <= control_ipbus_i.ipb_wdata(1);
          when others => null;
        end case;
      end if;
    end if;
  end process p_write;

-- Generate the IPBus ACK signal
  p_ipbus_ack : process (ipb_clk_i)
  begin  -- process p_ipbus_ack
    if rising_edge(ipb_clk_i) then          -- rising clock edge
      --s_ack <= control_ipbus_i.ipb_strobe and not s_ack and not s_ack_d1;
      --s_ack_d1 <= s_ack; -- delay strobe by one cycle for DPR latency
      --D s_ipb_strobe_d1 <= control_ipbus_i.ipb_strobe;
      --D s_ipb_strobe_d2 <= s_ipb_strobe_d1;
      s_ack <= control_ipbus_i.ipb_strobe and not s_ack;
    end if;
  end process p_ipbus_ack;
-- Output IPBus ACK  
  control_ipbus_o.ipb_ack <= s_ack;
--D control_ipbus_o.ipb_ack <= control_ipbus_i.ipb_strobe and s_ipb_strobe_d2;
  control_ipbus_o.ipb_err <= '0';


--! purpose: Controls state of s_internalTrigger
--! inputs : ipb_clk_i , control_ipbus_i 
--! outputs: 
  p_internalTrigger : process (ipb_clk_i , control_ipbus_i)
  begin  -- process p_internalTrigger
    if rising_edge(ipb_clk_i) then

      if control_ipbus_i.ipb_strobe = '1' and control_ipbus_i.ipb_write = '1' and
        control_ipbus_i.ipb_addr(2 downto 0) = "001"
      then
        s_internalTrigger_p <= control_ipbus_i.ipb_wdata(0);
      else
        s_internalTrigger_p <= '0';
      end if;
    end if;
  end process p_internalTrigger;

--! purpose: Controls state of s_counter_reset
--! inputs : ipb_clk_i , control_ipbus_i 
--! outputs: 
  p_resetCounter : process (ipb_clk_i , control_ipbus_i)
  begin  -- process p_internalTrigger
    if rising_edge(ipb_clk_i) then

      if control_ipbus_i.ipb_strobe = '1' and control_ipbus_i.ipb_write = '1' and
        control_ipbus_i.ipb_addr(2 downto 0) = "000"
      then
        s_counter_reset_ipb <= control_ipbus_i.ipb_wdata(0);
      else
        s_counter_reset_ipb <= '0';
      end if;
    end if;
  end process p_resetCounter;

  s_counter_reset <= s_counter_reset_ipb or logic_reset_i or reset_i;

-- Instantiate the TriggerGenerator
  cmp_TriggerGeneratorInterface : entity work.fiveMarocTriggerGenerator
    generic map (
      g_BUSWIDTH         => g_BUSWIDTH,
      g_NTRIGGER_SOURCES => g_NTRIGGER_SOURCES)
    port map (
      adcBusy_i               => adcBusy_i,
      clk_8x_i                => clk_8x_i,
      clk_sys_i               => clk_1x_i,
      reset_i                 => s_counter_reset,
--      conversion_counter_o => s_conversion_counter,
      externalHdmiTrigger_a_i => externalHdmiTrigger_a_i ,
      externalGpioTrigger_a_i => externalGpioTrigger_a_i ,
      internalTrigger_i       => s_internalTrigger_p,
      triggerSourceSelect_i   => s_triggerSourceSelect,
      hold1Delay_i            => s_hold1Delay,
      hold2Delay_i            => s_hold2Delay,

      or1_a_i              => s_or1_fast_clk,
      or2_a_i              => s_or2_fast_clk,
      or1_from_neighbour_i => s_or1_from_neighbour ,
      or2_from_neighbour_i => s_or2_from_neighbour ,

      adcConversionStart_o => s_adcConversionStart,
      externalTrigger_o    => externalTrigger_o,
      hold1_o              => hold1_o,
      hold2_o              => hold2_o,
      fsmStatus_o          => fsmStatus_o 
      );

  adcConversionStart_o <= s_adcConversionStart;

--! For now just count conversions, not triggers....
  triggerNumber_o <= s_conversion_counter;

  timeStamp_o <= s_TimeStamp;

--! Instantiate a counter for ADC conversions.
  cmp_triggerCounter : entity work.counterWithReset
    generic map (
      g_COUNTER_WIDTH => g_BUSWIDTH)
    port map (
      clock_i  => clk_i,
      reset_i  => s_counter_reset,
      enable_i => s_adcConversionStart,
      result_o => s_conversion_counter);

--! Instantiate a timestamp counter
  cmp_timeStamp : entity work.counterWithReset
    generic map (
      g_COUNTER_WIDTH => g_BUSWIDTH)
    port map (
      clock_i  => clk_i,
      reset_i  => s_counter_reset,
      enable_i => '1',
      result_o => s_timeStamp);

--! Instantiate a set of counters for OR1
--! NB. Need to addde-glitch, pulse stretch and move
--! to IPBus clock domain.
  cmp_or1Counters : entity work.multiCounterWithReset
    generic map (
      g_COUNTER_WIDTH => g_BUSWIDTH,
      g_NUM_COUNTERS  => g_NMAROC,
      g_ADDR_WIDTH    => c_OR_COUNTER_SELECT_WIDTH)
    port map (
      clock_i  => clk_i,
      reset_i  => s_counter_reset,
      enable_i => s_or1_ipbclk,
      result_o => s_triggerCounterOR1,
      select_i => control_ipbus_i.ipb_addr(c_OR_COUNTER_SELECT_WIDTH-1 downto 0)
      );

--! Instantiate a set of counters for OR2
--! NB. Need to de-glitch, pulse stretch and move
--! to IPBus clock domain.
  cmp_or2Counters : entity work.multiCounterWithReset
    generic map (
      g_COUNTER_WIDTH => g_BUSWIDTH,
      g_NUM_COUNTERS  => g_NMAROC,
      g_ADDR_WIDTH    => c_OR_COUNTER_SELECT_WIDTH)
    port map (
      clock_i  => clk_i,
      reset_i  => s_counter_reset,
      enable_i => s_or2_ipbclk,
      result_o => s_triggerCounterOR2,
      select_i => control_ipbus_i.ipb_addr(c_OR_COUNTER_SELECT_WIDTH-1 downto 0)
      );

--  s_or_fast_clk <= s_or2_fast_clk & s_or1_fast_clk;
--  s_or_ipbclk <= s_or2_ipbclk & s_or1_ipbclk;
--
  s_or2_fast_clk <= s_or_fast_clk(2*g_NMAROC-1 downto g_NMAROC);
  s_or2_ipbclk   <= s_or_ipbclk(2*g_NMAROC-1 downto g_NMAROC);

  s_or1_fast_clk <= s_or_fast_clk(g_NMAROC-1 downto 0);
  s_or1_ipbclk   <= s_or_ipbclk(g_NMAROC-1 downto 0);

  s_or_async <= or2_a_i & or1_a_i;

-- fime-grain timestamp generation and buffering. Also synchronizes the
-- incoming async trigger signals onto IPBus and fast-clock domains.
-- OR1 signals
  cmp_ORSync : entity work.fineTimeStamp
    generic map (
      g_ADDR_WIDTH => c_TIMESTAMP_BUFFER_ADDR_WIDTH,
      g_NMAROC     => 2*g_NMAROC,
      g_NCLKS      => g_NCLKS) 
    port map (
      ipb_clk_i          => ipb_clk_i,
      clk_1x_i           => clk_1x_i,
      clk_8x_i           => clk_8x_i,
      clk_16x_i          => clk_16x_i,
      reset_i            => s_counter_reset,
      event_trig_i       => s_adcConversionStart,
      trigger_number_i   => s_conversion_counter,
      coarse_timestamp_i => s_timeStamp ,
      trig_in_a_i        => s_or_async,
      trig_out_8x_o      => s_or_fast_clk,
      trig_out_1x_o      => s_or_ipbclk,
      write_address_o    => s_fineTimeStampWritePointer,

      -- IPBus to read data.
      ipbus_i => data_ipbus_i,
      ipbus_o => data_ipbus_o

      );


------------------------------------------------------------------------------------------------------------------------------------
-- Combine OR1 , OR2 signals together and send them off chip.
-- Receive OR1 , OR2 signals from neighbouring FPGA
-- Control the direction of I/O buffers based on s_typeA_typeB_flag
------------------------------------------------------------------------------------------------------------------------------------
  cmp_neighbourTriggerIO : entity work.neighbourTriggerIO
    port map (
      clk_8x_i           => clk_8x_i,
      boardType_na_b_i     => s_typeA_typeB_flag,
      hdmi_inout_signals_p => hdmi_inout_signals_p,
      hdmi_inout_signals_n => hdmi_inout_signals_n,
      or1_from_neighbour_o  => s_or1_from_neighbour,
      or1_to_neighbour_i    => s_or1_fast_clk,
      or2_from_neighbour_o  => s_or2_from_neighbour,
      or2_to_neighbour_i    => s_or2_fast_clk
      );

  -- Output signals to/from neighbouring board for debugging.
  or1_from_neighbour_o <= s_or1_from_neighbour;
  or1_to_neighbour_o   <= s_or1_fast_clk(0) or s_or1_fast_clk(1) or s_or1_fast_clk(2) or s_or1_fast_clk(3) or s_or1_fast_clk(4);
  

end rtl;
