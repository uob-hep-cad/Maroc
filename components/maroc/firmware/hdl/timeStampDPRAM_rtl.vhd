--=============================================================================
--! @file timeStampDPRAM_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--
--
--! @brief Instaniates a dual-port-ram to store timestamps and logic to write
--!        multiple words per trigger
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 20\4\2013
--
--! @version v0.1
--
--! @details
--!
--!
--! <b>Dependencies:</b>\n
--! Instantiates dual-port-ram
--!
--! <b>References:</b>\n
--! referenced by fineTimeStamp \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
-------------------------------------------------------------------------------
--
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.fiveMaroc.all;

--! Package containing type definition and constants for IPBUS
use work.ipbus.all;

entity timeStampDPRAM is
  
  generic (
    g_BUSWIDTH  : positive := 32;       --! Width of data bus ( IPBus)
    g_ADDRWIDTH : positive := 10;       --! Width of DPR address bus
    g_NMAROC    : positive := 5         --! number of MAROC chips
    );      

  port (
    clk_i            : in  std_logic;   --! IPBus clock. Rising edge active
    reset_i          : in  std_logic;   --! Active high synchronous
    event_trigger_i  : in  std_logic;  -- goes high for one clock cycle to trigger writing of event data into DPR
    trigger_number_i : in  std_logic_vector(g_BUSWIDTH-1 downto 0);  --!Current trigger number
    timestamp_i      : in  t_dual_timestamp_array;  --! Array of 32-bit timestamps
    event_timestamp_i : in std_logic_vector(g_BUSWIDTH-1 downto 0);  --! Timestamp of current trigger
    write_pointer_o  : out std_logic_vector(g_ADDRWIDTH-1 downto 0);  --! Pointer to last address written

    -- IPBus for access to DPR
    ipbus_clk : in std_logic;
    ipbus_i : in  ipb_wbus;
    ipbus_o : out ipb_rbus

    );
end timeStampDPRAM;

architecture rtl of timeStampDPRAM is

  signal s_wen       : std_logic                               := '0';  --! take high to write into dual-port-ram
  signal s_writeAddr : unsigned(write_pointer_o'range)         := (others => '0');  --! Address into write-port of DPR
  signal s_counter   : unsigned(write_pointer_o'range)         := (others => '0');  --! Counter that controls which item of data is written to DPRAM.
  signal s_dataToDPR : std_logic_vector(g_BUSWIDTH-1 downto 0) := (others => '0');  --! Output from mux that selects which item of data to write
  signal s_registered_event_timestamp : std_logic_vector( event_timestamp_i'range); --!
  constant c_INITIAL_COUNT : positive := (2*g_NMAROC) + 2;
  constant c_NUM_HEADER_WORDS : positive := 2;
  -- signal s_counterIndex : natural := 0;  -- ! Point to which timestamp to feed to DPR
  signal s_counterIndex : integer := 0;  -- ! Point to which timestamp to feed to DPR
  
begin  -- rtl

  -----------------------------------------------------------------------------
  -- Instantiate a dual-port-ram to store timestamps
  cmp_timestamp_buf : entity work.ipbusDPRAM
    generic map (
      data_width        => g_BUSWIDTH,
      ram_address_width => g_ADDRWIDTH)
    port map (
      Wren_a => s_wen,
      clk    => clk_i,

      address_a => std_logic_vector(s_writeAddr),
      data_a    => s_dataToDPR,

      -- IPBus to read data
      ipbus_clk => ipbus_clk,
      ipbus_i => ipbus_i,
      ipbus_o => ipbus_o

      );


  -- purpose: controls counter and write_pointer
  -- type   : combinational
  -- inputs : clk_i
  -- outputs: clk_i , event_trigger_i
  p_counterControl : process (clk_i, event_trigger_i, s_writeAddr , s_counter)
  begin  -- process p_counterControl
    if rising_edge(clk_i) then

      if reset_i = '1' then
        s_counter <= (others => '0');
      elsif event_trigger_i = '1' then  -- if trigger set the sequence counter
        s_counter <= to_unsigned(c_INITIAL_COUNT, s_counter'length);
        s_registered_event_timestamp <=  event_timestamp_i; -- and capture current timestamp
      elsif (s_counter /= 0) then  -- if no trigger, but counter /=0 then decrement
        s_counter <= s_counter - 1;
      else
        s_counter <= s_counter;
      end if;

      if reset_i = '1' then
        s_writeAddr <= (others => '0');
      elsif s_counter /= 0 then
        s_writeAddr <= s_writeAddr + 1;
      end if;

      -- end of clock loop
    end if;


    
  end process p_counterControl;

  -- copy write address to output port.
  write_pointer_o <= std_logic_vector(s_writeAddr);

  --! Write to dual-port-ram when counter isn't zero
  s_wen <= '0' when s_counter = 0 else '1';

  s_counterIndex <= (c_INITIAL_COUNT - to_integer(s_counter) - c_NUM_HEADER_WORDS) when ( (s_counter /= c_INITIAL_COUNT) and (s_counter /= (c_INITIAL_COUNT-1)) and (s_counter /= 0)) else 0;

  s_dataToDPR <= trigger_number_i when (s_counter = c_INITIAL_COUNT) else
                 s_registered_event_timestamp when (s_counter = (c_INITIAL_COUNT-1)) else
                 timestamp_i(s_counterIndex) when (s_counter /= 0) else
                 (others => '0');
  
end rtl;
