--=============================================================================
--! @file marocShiftReg_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
--! Package containg type definition and constants
use work.maroc.ALL;
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: marocShiftReg (marocShiftReg / rtl)
--
--! @brief Takes an array of 32-bit words data_i and shifts them out to d_sr_o
--! when start_sr_p_i is strobed high. Returning data from MAROC on q_sr_i
--! is captured into data_i .
--! The clock clk_sr_o is generated from the clk_system_i 
--! The most significant bit of data_i is shifted out to MAROC first.
--! i.e. data_i(g_NBITS-1) corresponds to "SC Bit 0" as shown
--! on p27 of Maroc3 datasheet.
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 23\12\2011
--
--! @version v0.1
--
--! @details
--!
--! <b>Dependencies:</b>\n
--! Instantiates marocShiftRegFSM
--!
--! <b>References:</b>\n
--! referenced by ipBusMarocShiftReg \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! <date> <initials> <log>\n
--! <extended description>
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
---------------------------------------------------------------------------------

--============================================================================
--! Entity declaration for marocShiftReg
--============================================================================

entity marocShiftReg is
  
  generic (
    g_NBITS    : positive := c_NBITS;  --! Number of bits to shift out to MAROC
    g_NWORDS   : positive := c_NWORDS;    --! Number of words in IPBUS space to store data
    g_BUSWIDTH : positive := c_BUSWIDTH;   --! Number of bits in each word

    --! Number of bits in clock divider between system clock and clock to shift reg
    g_CLKDIVISION : positive := 4     

    );       

  port (
    clk_system_i : in  std_logic;   --! System clock ( probably IPBUS clock)
    rst_i        : in  std_logic;   --! active high. synchronous. Resets shift-reg controler.
    start_p_i      : in  std_logic;   --! take high for one cycle to initiate serial transer to MAROC;

    --! Data to be written to MAROC shift reg. Integer number of IPBus words wide.
    --! Only the bottom g_NBITS is shifted out to MAROC.
    data_i       : in  std_logic_vector( (g_NWORDS*g_BUSWIDTH)-1 downto 0);

    --! Data read back from MAROC. Integer number of IPBus words wide.
    --! Only the bottom g_NBITS is significant.
    data_o       : out  std_logic_vector( (g_NWORDS*g_BUSWIDTH)-1 downto 0);
                   
    clk_sr_o     : out std_logic;         --! Clock out to shift-register

    --! Data being output to shift reg.
    d_sr_o       : out std_logic;
    
    q_sr_i       : in  std_logic;         --! input back from shift reg
    rst_sr_n_o    : out std_logic;         --! reset* to shift reg
    status_o     : out std_logic);        --! Zero when FSM is idle , one otherwise
end marocShiftReg;

--============================================================================
--! architecture declaration
--============================================================================
architecture rtl of marocShiftReg is

  --! Driven by MarocShiftRegFSM. Goes high for one cycle to load data
  --! from registers to shift reg\n
  signal s_load_sr : std_logic := '0';  --! Active high. Single cycle
  signal s_capture_sr : std_logic := '0';  --! Active high. Single cycle

  --! Goes high to indicate data should be shifted out of shift-register
  signal s_output_shiftreg : std_logic := '0';

  --! Goes high to indicate data should be shifted into input shift-register
  signal s_input_shiftreg : std_logic := '0';  
  
  --! Shift register to data going out to MAROC
  signal s_sr_out : std_logic_vector((g_BUSWIDTH*g_NWORDS)-1 downto 0) := (others => '0');

  --! Shift regsiter for data coming back from MAROC
  signal s_sr_in : std_logic_vector((g_BUSWIDTH*g_NWORDS)-1 downto 0) := (others => '0');

  signal s_clk_sr : std_logic := '0';   -- ! Internal copy of clk_sr_o
  signal s_enable_sr_clk : std_logic := '0';  -- ! Goes high to enable shift reg. clock
  
  -- ! pulses high for one cycle of clk_system_i when s_clk_sr goes high
  signal s_clk_sr_rising_p : std_logic := '0';

    -- ! pulses high for one cycle of clk_system_i when s_clk_sr goes falls
  signal s_clk_sr_falling_p : std_logic := '0';

  -- ! Delayed version of s_clk_sr. Used to generate s_clk_sr_rising_p
  signal  s_clk_sr_d1 : std_logic := '0';  

  -- ! Counter to divide down system clock
  signal s_clk_counter : unsigned( g_CLKDIVISION-1 downto 0) := ( others => '0') ;  

  component  marocShiftRegFSM is
    generic (
    g_NBITS    : positive := c_NBITS ;  --! Number of bits to shift out to MAROC
    g_BITCOUNTER_WIDTH : positive := 10     --! Number of bits in counter for bits
    );
    port (
      clk_system_i      : in std_logic;
      rst_i             : in std_logic;  --! Take high to reset state machine.
      sr_clk_rising_p_i : in std_logic;  --! Goes high on rising edge of shift-reg clock
      start_p_i         : in std_logic;
      rst_sr_n_o        : out std_logic;  --! reset to MAROC SR
      load_sr_o         : out std_logic;
      capture_sr_o      : out std_logic;
      output_shiftreg_o : out std_logic;
      enable_sr_clk_o   : out std_logic;
      input_shiftreg_o  : out std_logic;
      status_o          : out std_logic --! Zero when FSM is idle , one otherwise
      );        
  end component;
      
--============================================================================
-- architecture begin
--============================================================================ 
begin  -- rtl

  --==========================================================================
  --! Process: generate a clock for shift register and a pulse on rising edge
  --! read: clk_system_i , s_clk_counter
  --! write: s_clk_sr_rising , s_clk_sr
  --==========================================================================
  p_generate_sr_clk: process (clk_system_i , s_clk_counter )
  begin  -- process p_generate_sr_clk
    if rising_edge(clk_system_i) then 

      if rst_i='1' then
        s_clk_counter <= to_unsigned(0, g_CLKDIVISION);
      else
        s_clk_counter <= s_clk_counter+1;
        s_clk_sr <= s_clk_counter( g_CLKDIVISION-1 );
        s_clk_sr_d1 <= s_clk_sr;          
      end if;

      --! Copy of shift-reg clock to output to MAROC
      if s_enable_sr_clk='1' then
        clk_sr_o <= s_clk_sr_d1;        --! Use the delayed clock to avoid glitch at end of train 
      else
        clk_sr_o <= '0';
      end if;
      
    end if;
  end process p_generate_sr_clk;

  --! Pulses high for one clock cycle of clk_system_i on rising edge of s_clk_sr
  s_clk_sr_rising_p <= s_clk_sr and ( not s_clk_sr_d1 );

  --! Pulses high for one clock cycle of clk_system_i on falling edge of s_clk_sr
  s_clk_sr_falling_p <= (not s_clk_sr) and s_clk_sr_d1 ;  

  
  --==========================================================================
  --! Component: FSM to generate control signals
  --==========================================================================
  cmp_marocShiftRegFSM: marocShiftRegFSM
    generic map (
      g_NBITS => g_NBITS)
    port map (
      clk_system_i      => clk_system_i,
      rst_i             => rst_i,
      sr_clk_rising_p_i => s_clk_sr_rising_p ,
      start_p_i         => start_p_i,
      rst_sr_n_o        => rst_sr_n_o,
      load_sr_o         => s_load_sr,
      capture_sr_o      => s_capture_sr,
      output_shiftreg_o => s_output_shiftreg,
      enable_sr_clk_o   => s_enable_sr_clk,
      input_shiftreg_o  => s_input_shiftreg,
      status_o          => status_o);
    
  
  --==========================================================================
  --! Process: shift out data to d_o when FSM takes s_output_shiftreg high
  --! read: clk_system_i , s_output_shiftreg , s_sr_out
  --! write: d_sr_o
  --==========================================================================
  p_output_shiftreg: process (clk_system_i , s_output_shiftreg , s_sr_out)
  begin  -- process p_output_shiftreg
    if rising_edge(clk_system_i) then
      if (s_load_sr = '1') then
        s_sr_out <= data_i;
        d_sr_o <= '0';
      elsif (s_output_shiftreg = '1') then
        if (s_clk_sr_falling_p = '1') then
          d_sr_o <= s_sr_out(g_NBITS-1);  --! MAROC expects MSB first
          s_sr_out <= s_sr_out( (g_BUSWIDTH*g_NWORDS)-2 downto 0) & '0';
        end if;
      else
        s_sr_out <= s_sr_out;
        d_sr_o <= '0';
      end if;
    end if;
  end process p_output_shiftreg;

  
  --==========================================================================
  --! Process: shift in data from q_sr_i when FSM takes s_input_shiftreg high
  --! read: clk_system_i , s_input_shiftreg , q_sr_i
  --! write: s_sr_in
  --==========================================================================
  p_input_shiftreg: process (clk_system_i , s_input_shiftreg , q_sr_i)
  begin  -- process p_input_shiftreg
    if rising_edge(clk_system_i) then
      if (s_capture_sr = '1') then
        data_o <= s_sr_in;
      elsif (s_input_shiftreg = '1') and (s_clk_sr_rising_p = '1') then
        s_sr_in <= s_sr_in( (g_BUSWIDTH*g_NWORDS)-2 downto 0) & q_sr_i;  --! Capture MSB first
      end if;
    end if;
  end process p_input_shiftreg;

    
end rtl;
--============================================================================
-- architecture end
--============================================================================
