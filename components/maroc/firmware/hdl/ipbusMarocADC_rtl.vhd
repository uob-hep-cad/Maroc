--=============================================================================
--! @file ipbusMarocADC_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--! Package containing type definition and constants for MAROC interface
use work.maroc.all;
--! Package containing type definition and constants for IPBUS
use work.ipbus.all;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: ipbusMarocADC_rtl (ipbusMarocADC / rtl)
--
--! @brief Interfaces between IPBus and Maroc ADC\n
--! Addresses ( with respect to base address)\n
--! 0x00 - 0x2FF : ADC data ( ro )\n
--! 0x200        : control/status.
--!               Writing '1' to bit-0 starts conversion.\n
--!               Reading bit-0 returns high if conversion is in progress\n
--!               Writing '1' to bit-1 resets write pointer\n
--! 0x201       : returns the number of bits shifted out by MAROC ADC\n
--!               during last conversion ( ro )\n
--! 0x202       : DPRAM write-pointer (next address to be written to ( ro )\n
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 4\Jan\2012
--
--! @version v0.3
--
--! @details
--! This module provides input/output to Maroc ADC pins.
--! An ADC conversion can be initiated either by writing to bit-1 of 0x401 or
--! (usually) by a pulse on the input port adcConversionStart_i
--!
--! There are two ways to trigger an ADC conversion:
--! a) A pulse on adcConversionStart_i 
--! b) Writing to bit-0 of address 0x20
--!
--! As serial data arrives from ADC the earliest data ends up in highest bits of
--! the lowest words in the DPRAM.
--!
--! Data are written to a DPRAM. Address 0x402 stores the location that the next
--! word that will be written (the "write pointer").
--! The ADC data are preceeded by a trigger number word
--! and a timestamp word. Hence with the Maroc set to 12-bit samples the total
--! number of 32-bit words = (64 * 12)/32 + 2 = 26
--!
--! NB. There is no attempt to throttle the input data if the write pointer overtakes
--! the read pointer on the IPBus host.
--!
--! <b>Dependencies:</b>\n
--! Instantiates marocADC ( which contains the DPRAM )
--!
--! <b>References:</b>\n
--! referenced by slaves \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! 18/Jan/2012 DGC Fixed bug so that writing to control register only triggers
--!                 a single ADC conversion.\n
--! 25/Jan/2012 DGC Added FIFO\n
--! 17/Feb/2012 DGC Changed marocADC to use Dual-port RAM rather than shift-reg\
--!                 need to change ports accordingly\n
--! 7/March/2012 DGC Got rid of FIFO and make DPRAM big enough to act as a
--!                  circular buffer\n
--! 17/March/2012 DGC Add internal reset, to reset state of ADC\n
--! 9/May/2013    DGC Reduced buffer size to 512 words
-------------------------------------------------------------------------------
--! @todo 
---------------------------------------------------------------------------------
--

entity ipbusMarocADC is
  generic(
    g_ADDRWIDTH : positive                      := 9;  --! Number of words in the data  buffer
                                                       --! is 2^g_ADDRWIDTH
    g_BUSWIDTH  : positive                      := 32;  --! Width of data bus
    g_IDENT     : std_logic_vector(31 downto 0) := X"DEADBEEF"
    );
  port(
    clk_i   : in  std_logic;            --! IPBus clock. Active high
    reset_i : in  std_logic;            --! Active high
    control_ipbus_i : in  ipb_wbus;             --! Signals from IPBus master for control/status
    control_ipbus_o : out ipb_rbus;             --! Signals to IPBus master
    data_ipbus_i : in  ipb_wbus;             --! Signals from IBus master for data
    data_ipbus_o : out ipb_rbus;             --! Signals to IPBus master

    logic_reset_i : in std_logic;       --! Reset logic signal. High for one cycle of ipbus clock

    -- Signals to trigger controller
    adcConversionStart_i : in  std_logic;  --! Signal from trigger generator. an ADC conversion is started when pulses high
    adcStatus_o          : out std_logic;  --! goes high when ADC is in progres.
    triggerNumber_i      : in  std_logic_vector(g_BUSWIDTH-1 downto 0);
    timeStamp_i          : in  std_logic_vector(g_BUSWIDTH-1 downto 0);
    -- Signals to MAROC
    START_ADC_N_O        : out std_logic;  --! Signal to MAROC. Drops low to initiate ADC conversion
    RST_ADC_N_O          : out std_logic;  --! Signal to MAROC. Drops low to reset ADC
    ADC_DAV_I            : in  std_logic;  --! Signal from MAROC. Goes high during data transmission 
    OUT_ADC_I            : in  std_logic  --! Data from MAROC. Clocked by clk_i

    );

end ipbusMarocADC;

architecture rtl of ipbusMarocADC is

  --signal s_adc_data               : std_logic_vector(g_BUSWIDTH-1 downto 0);
  --signal s_adc_dpr_address        : std_logic_vector(g_ADDRWIDTH-1 downto 0);
  --signal s_adc_dpr_addr_from_fifo : std_logic_vector(g_ADDRWIDTH-1 downto 0);
  signal s_adc_dpr_write_pointer  : std_logic_vector(g_ADDRWIDTH-1 downto 0);

--    signal s_sel: integer;
  signal s_ack : std_logic := '0'; -- , s_ack_d1 : std_logic;

  signal s_start_p : std_logic;  --! Control line to ADC interface. Pulses high to start conversion manually

  --! Generated by IPBus. ADC starts if either internal or external signal goes high
  signal s_internal_start_p : std_logic;

  signal s_internal_reset , s_reset : std_logic;

  signal s_status    : std_logic;  --! Control line from ADC interface. Goes high when conversion in progress
  signal s_status_d1 : std_logic;       --! s_status delayed by 1 cycle

  signal s_bitcount : std_logic_vector(9 downto 0);  --! Number of bits output by ADC during last conversion

begin

  -- read/write to registers storing data to/from MAROC and to control reg.
  p_register_data : process(clk_i)
  begin

      -- Register the counters and status
      if rising_edge(clk_i) then
        case control_ipbus_i.ipb_addr(1 downto 0) is
          when "00" =>
            -- We are reading the control/status register. s_start_p is
            -- handled a separate process, so just do read here.
            control_ipbus_o.ipb_rdata(0)                     <= s_status;
            control_ipbus_o.ipb_rdata(g_BUSWIDTH-1 downto 1) <= (others => '0');
          when "01" =>
            -- We are reading the bit counter
            control_ipbus_o.ipb_rdata(s_bitcount'range)                      <= s_bitcount;
            control_ipbus_o.ipb_rdata(g_BUSWIDTH-1 downto s_bitcount'high+1) <=
              (others => '0');
          when "10" =>
            -- We are reading the ADC write pointer
            control_ipbus_o.ipb_rdata(s_adc_dpr_write_pointer'range) <=
              s_adc_dpr_write_pointer;
            control_ipbus_o.ipb_rdata(g_BUSWIDTH-1 downto s_adc_dpr_write_pointer'high+1) <=
              (others => '0');
          when "11" =>
            -- test location
            control_ipbus_o.ipb_rdata <= g_IDENT;
          when others => null;
        end case;
        
      end if;
      
  end process;  -- p_register_data

  p_ipbus_ack : process (clk_i)
  begin  -- process p_ipbus_ack
    if rising_edge(clk_i) then          -- rising clock edge
      s_ack    <= control_ipbus_i.ipb_strobe and not s_ack;
    end if;
  end process p_ipbus_ack;

  control_ipbus_o.ipb_ack <= s_ack;
  control_ipbus_o.ipb_err <= '0';

  --! purpose: Controls state of s_start_p and s_internal_reset
  --! type   : combinational
  --! inputs : clk_i , control_ipbus_i 
  --! outputs: 
  p_start_control : process (clk_i , control_ipbus_i)
  begin  -- process p_start_control
    if rising_edge(clk_i) then

      if control_ipbus_i.ipb_strobe = '1' and control_ipbus_i.ipb_write = '1' and
        control_ipbus_i.ipb_addr(g_ADDRWIDTH) = '1' and
        control_ipbus_i.ipb_addr(1 downto 0) = "00"
      then
        s_internal_start_p <= control_ipbus_i.ipb_wdata(0);
        s_internal_reset   <= control_ipbus_i.ipb_wdata(1);
      else
        s_internal_start_p <= '0';
        s_internal_reset   <= '0';
      end if;

      s_start_p <= s_internal_start_p or adcConversionStart_i;
      
    end if;
  end process p_start_control;

  --! Sigh.... can't read from an out-port so take a local copy...
  adcStatus_o        <= s_status;

  --! Fire a reset either from IPBus
  --master, or by writing to bit-1 of
  --ctrl reg or external logic reset
  s_reset <= reset_i or s_internal_reset or logic_reset_i;


  -- Instantiate the ADC interface
  cmp_ADCInterface : entity work.marocADC
    generic map (
      g_ADDRWIDTH => g_ADDRWIDTH
      )
    port map (
      clk_i   => clk_i ,
      reset_i => s_reset,

      start_p_i       => s_start_p ,    --! Pulse high to start conversion.
      status_o        => s_status ,

      write_pointer_o => s_adc_dpr_write_pointer,  --! Next address to be written
      bitcount_o      => s_bitcount ,

      -- IPBus port to read data.
      --data_o          => s_adc_data ,   --! 32 bit word from DPR
      --addr_i          => s_adc_dpr_address ,  --! Read port address into DPR
      ipbus_i      => data_ipbus_i,
      ipbus_o      => data_ipbus_o,
      
      -- Timestamp and trigger number
      triggerNumber_i => triggerNumber_i ,
      timeStamp_i     => timeStamp_i ,

      -- Signals to MAROC
      START_ADC_N_O => START_ADC_N_O ,
      RST_ADC_N_O   => RST_ADC_N_O,
      ADC_DAV_I     => ADC_DAV_I,
      OUT_ADC_I     => OUT_ADC_I

      );


end rtl;
