--=============================================================================
--! @file marocShiftRegFSM_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
--! Specific packages
--use work.XXX.ALL;
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: marocShiftRegFSM (marocShiftRegFSM / rtl)
--
--! @brief State machine to produce control signals for marocShiftREG
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
--! None
--!
--! <b>References:</b>\n
--! referenced by marocShiftREG \n
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
--! Entity declaration for marocShiftRegFSM
--============================================================================
entity marocShiftRegFSM is

    generic (
    g_NBITS    : positive ;  --! Number of bits to shift out to MAROC
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
end marocShiftRegFSM;

--============================================================================
--! architecture declaration
--============================================================================
architecture rtl of marocShiftRegFSM is

  --! Define an enumerated type corresponding to FSM states
  type t_state_type is (IDLE , RESETTING , PREOUTPUTPAUSE , SHIFTINGOUT , CAPTURESR );
  signal s_state , s_next_state : t_state_type;

  --! Signal for J type flip-flop capuring start_p_i
  signal s_internalStart_p : std_logic := '0';
  
  --! counter for number of bits.
  signal s_bit_counter : unsigned( g_BITCOUNTER_WIDTH-1 downto 0) := (others => '0');  

  
--============================================================================
-- architecture begin
--============================================================================ 
begin  -- rtl

  
  --==========================================================================
  --! Process: Register that holds the current state of the FSM
  --! read: clk_system_i , rst_i
  --! write: s_state
  --==========================================================================
  p_state_register: process (clk_system_i , rst_i , s_state , s_next_state,sr_clk_rising_p_i )
  begin  -- process state_register
    if rising_edge(clk_system_i) and (sr_clk_rising_p_i = '1') then
      if ( rst_i = '1') then
        s_state <= IDLE;
      else
        s_state <= s_next_state;
      end if;
    else
      s_state <= s_state;
    end if;
  end process p_state_register;

  --==========================================================================
  --! Process: state logic - controls s_next_state based on current state and inputs
  --! read: clk_system_i , rst_i , s_state , 
  --! write: s_next_state
  --==========================================================================
  p_state_logic: process (s_state , s_next_state , s_internalStart_p , s_bit_counter  )
  begin  -- process p_state_logic
    case s_state is
      
      when IDLE =>
        if ( s_internalStart_p = '1' ) then
          s_next_state <= RESETTING;
        else
          s_next_state <= IDLE;
        end if;

      when RESETTING =>
        s_next_state <= PREOUTPUTPAUSE;

      when PREOUTPUTPAUSE =>
        s_next_state <= SHIFTINGOUT;

      when SHIFTINGOUT =>
        if ( s_bit_counter = 0 ) then
          s_next_state <= CAPTURESR;
        else
          s_next_state <= SHIFTINGOUT;
        end if;

      when CAPTURESR =>
        s_next_state <= IDLE;
        
      when others =>
        s_next_state <= IDLE;
        
    end case;
  end process p_state_logic;
  
  --==========================================================================
  --! Process: Bit counter
  --! read: clk_system_i , rst_i , s_state
  --! write: s_state
  --==========================================================================
  p_bit_counter: process (clk_system_i , s_state , rst_i , s_bit_counter)
  begin  -- process p_bit_counter
    if rising_edge(clk_system_i) then
      if (rst_i = '1') then
        s_bit_counter <= (others => '0');
      elsif ( s_state = PREOUTPUTPAUSE ) and (sr_clk_rising_p_i = '1') then
        s_bit_counter <= to_unsigned(g_NBITS-1 , g_BITCOUNTER_WIDTH );
      elsif ( s_state = SHIFTINGOUT ) and (sr_clk_rising_p_i = '1') then
        s_bit_counter <= s_bit_counter - 1;
      else
        s_bit_counter <= s_bit_counter;
      end if;
    end if;
  end process p_bit_counter;

  --==========================================================================
  --! Process: StartJK - capture start_p_i even if it isn't coincident with
  --! shift-reg clock 
  --! read: clk_system_i , rst_i , start_p_i
  --! write: s_internalStart_p
  --==========================================================================
  p_startJK: process (clk_system_i , rst_i , start_p_i)
  begin  -- process p_startJK
    if rising_edge(clk_system_i) then
      if rst_i = '1' then
        s_internalStart_p <= '0';
      elsif (s_state=IDLE) and (start_p_i='1') then
        s_internalStart_p <= '1';
      elsif s_state /= IDLE then
        s_internalStart_p <= '0';
      end if;
    end if;
  end process p_startJK;
  
  --! Set output signals on basis of state
  rst_sr_n_o <= '0' when s_state = RESETTING else '1';  --! reset to MAROC goes low when state=resetting

  load_sr_o <= '1' when s_state = RESETTING else '0';  --! load shift-reg whilerst is low

  enable_sr_clk_o <= '1' when s_state = SHIFTINGOUT  else '0';
  
  output_shiftreg_o <= '1' when (s_state = SHIFTINGOUT)  or (s_state = PREOUTPUTPAUSE) else '0';

  input_shiftreg_o <= '1' when (s_state = SHIFTINGOUT) else '0';

  capture_sr_o <= '1' when s_state = CAPTURESR else '0';
  
  status_o <= '0' when s_state = IDLE else '1';
  
end rtl;
--============================================================================
-- architecture end
--============================================================================
