--=============================================================================
--! @file ipbusMarocShiftReg_rtl.vhd
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

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: ipbusMarocShiftReg_rtl (ipbusMarocShiftReg / rtl)
--
--! @brief Interfaces between IPBus and Maroc shift register.\n
--! addresses 0x00 - 0x1F : data to be written to MAROC ( r/w )\n
--! addresses 0x20 - 0x3F : data returned from MAROC ( ro )\n
--! address   0x40        : control/status. Writing to bit-0 starts transfer.
--! Reading bit-0 returns high if transfer is in progress\n
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 4\1\2011
--
--! @version v0.1
--
--! @details
--!
--! <b>Based on ipbus_ram by Dave Newbold.<b>\n
--!
--! <b>Dependencies:</b>\n
--! Instantiates marocShiftReg
--!
--! <b>References:</b>\n
--! referenced by slaves \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! Friday 13/Jan/2012 DGC - Now only starts Shifting if data bit zero of is high\n
--! <extended description>
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
---------------------------------------------------------------------------------
--
-- $Id: ipbus_ram.vhd 324 2011-04-25 19:37:43Z phdmn $


entity ipbusMarocShiftReg is
  generic(
    g_ADDRWIDTH   : positive;
    g_NBITS       : positive := c_NBITS;  --! Number of bits to shift out to MAROC
    g_NWORDS      : positive := c_NWORDS;    --! Number of words in IPBUS space to store data
    g_BUSWIDTH    : positive := c_BUSWIDTH;   --! Number of bits in each word
    g_CLKDIVISION : positive := 4 --! Number of bits in clock divider between system clock and clock to shift reg
    );
  port(
    clk_i        : in STD_LOGIC;
    reset_i      : in STD_LOGIC;
    ipbus_i      : in ipb_wbus;
    ipbus_o      : out ipb_rbus;
    clk_sr_o     : out std_logic;      --! Clock out to shift-register
    d_sr_o       : out std_logic;      --! Data being output to shift reg.
    q_sr_i       : in  std_logic;      --! input back from shift reg
    rst_sr_n_o   : out std_logic      --! reset* to shift reg
    );
	
end ipbusMarocShiftReg;

architecture rtl of ipbusMarocShiftReg is

  type t_reg_array is array(2**g_ADDRWIDTH-1 downto 0) of std_logic_vector(31 downto 0);
  signal s_reg_out: t_reg_array;
  signal s_reg_in: t_reg_array;
  signal s_sel: integer;
  signal s_ack: std_logic;

  signal s_start_p : std_logic := '0';  --! Control signal to shift reg controller. Take high for one cycle to start transfer
  signal s_status : std_logic ;  --! From shift reg controller. Goes high while transfer in progress

  signal s_data_to_maroc , s_data_from_maroc : std_logic_vector( (g_NWORDS*g_BUSWIDTH)-1 downto 0) := (others => '0');  --! register storing data going to/from MAROC shift reg.
  
begin

  s_sel <= to_integer(unsigned(ipbus_i.ipb_addr(g_ADDRWIDTH-1 downto 0)));

  -- read/write to registers storing data to/from MAROC and to control reg.
  p_register_data: process(clk_i)
  begin
    if rising_edge(clk_i) then

      -- If the bit g_ADDRWIDTH+1 is low then read/write to register storing
      -- data going to/from maroc
      if ipbus_i.ipb_addr(g_ADDRWIDTH+1)='0' then

        -- If ipb_addr(g_ADDRWIDTH)  low then read/write register storing data *to* Maroc
        if ipbus_i.ipb_addr(g_ADDRWIDTH)='0' then
          
          if ipbus_i.ipb_strobe='1' and ipbus_i.ipb_write='1' then
            s_reg_out(s_sel) <= ipbus_i.ipb_wdata;
          end if;

          ipbus_o.ipb_rdata <= s_reg_out(s_sel);

        else
          -- else if ipb_addr(g_ADDRWIDTH)  high then read/write register storing data *from* Maroc           

          ipbus_o.ipb_rdata <= s_reg_in(s_sel);

        end if;
        
      else
        
        -- ipb_addr(g_ADDRWIDTH+1) is high, so we are addressing the
        -- control/status register
        -- writing to s_start_p is handled in separate proccess
        -- just do read  here
        ipbus_o.ipb_rdata(0) <= s_status;
        
      end if;

      s_ack <= ipbus_i.ipb_strobe and not s_ack;
    end if;
  end process;                          -- p_register_data

  --! purpose: Controls state of s_start_p
  --! type   : combinational
  --! inputs : clk_i , ipbus_i 
  --! outputs: 
  p_start_control: process (clk_i , ipbus_i )
  begin  -- process p_start_control
    if rising_edge(clk_i) then

      if ipbus_i.ipb_strobe='1' and ipbus_i.ipb_write='1' and
        ipbus_i.ipb_addr(g_ADDRWIDTH+1)='1' 
      then
        s_start_p <= ipbus_i.ipb_wdata(0) ;
      else
        s_start_p <= '0';
      end if;
    end if;
  end process p_start_control;

  ipbus_o.ipb_ack <= s_ack;
  ipbus_o.ipb_err <= '0';

  --! Copy data to input/output shift registers
  -- Hopefully synthesis tool will not generate an additional pair of registers.
  l_copywords: for iword in 0 to g_NWORDS-1 generate
    s_data_to_maroc( (((iword+1)*g_BUSWIDTH)-1) downto iword*g_BUSWIDTH ) <= s_reg_out(iword);
    s_reg_in(iword) <= s_data_from_maroc((((iword+1)*g_BUSWIDTH)-1) downto iword*g_BUSWIDTH );
  end generate l_copywords;


--! Instantiate a shift register controller
  cmp_shiftRegController: entity work.marocShiftReg
    generic map (
      g_NBITS => g_NBITS)
    PORT MAP (
      clk_system_i => clk_i,
      rst_i => reset_i,
      start_p_i => s_start_p,
      data_i => s_data_to_maroc,
      data_o => s_data_from_maroc,
      clk_sr_o => clk_sr_o,
      d_sr_o =>  d_sr_o,
      q_sr_i =>  q_sr_i,
      rst_sr_n_o => rst_sr_n_o,
      status_o => s_status
      );
  
end rtl;
