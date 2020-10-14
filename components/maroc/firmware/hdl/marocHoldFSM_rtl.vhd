--=============================================================================
--! @file marocHoldFSM_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: marocHoldFSM (marocHoldFSM / rtl)
--
--! @brief State machine to produce control signals for maroc Hold* signal
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 12/07/2013
--
--! @version v0.1
--
--! @details
--! two inputs : trigger_i and adcBusy_o\n
--! two outputs : hold_n_o , fsmStatus_o\n
--! fsmStatus: 0=IDLE,1=WAIT_FOR_BUSY_LOW,2=WAIT_FOR_BUSY_HIGH
--!
--! <b>Dependencies:</b>\n
--! None
--!
--! <b>References:</b>\n
--! referenced by fiveMarocTriggerGenerator \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
---------------------------------------------------------------------------------

--============================================================================
--! Entity declaration for marocHoldFSM
--============================================================================
entity marocHoldFSM is

    port (
      clk_i             : in std_logic;  --! Rising edge active
      rst_i             : in std_logic;  --! Take high to reset state machine.
      trigger_i          : in std_logic;  --! Pulse high to start conversion
      adcBusy_i        : in std_logic;  --! High when one or more MAROC busy
      hold_n_o          : out std_logic;  --! Hold signal. Active low
      fsmStatus_o       : out std_logic_vector(1 downto 0) --! State of FSM.
                                                            
      );        
end marocHoldFSM;

--============================================================================
--! architecture declaration
--============================================================================
architecture rtl of marocHoldFSM is

  --! Define an enumerated type corresponding to FSM states
  type t_state_type is (IDLE , WAIT_FOR_BUSY_HIGH ,WAIT_FOR_BUSY_LOW );
  signal s_state , s_next_state : t_state_type := IDLE ;

  signal s_trigger_d1 : std_logic;             --! trigger_i clocked onto clk_fast
  signal s_trigger_d2 : std_logic;             --!
  signal s_adcBusy_d1 : std_logic;             --! adcBusy_i clocked onto clk_fast
  signal s_adcBusy_d2 : std_logic;             --! 
 
--============================================================================
-- architecture begin
--============================================================================ 
begin  -- rtl

  
  --==========================================================================
  --! Process: Register that holds the current state of the FSM
  --! read: clk_i , rst_i
  --! write: s_state
  --==========================================================================
  p_state_register: process (clk_i , rst_i , s_state , s_next_state )
  begin  -- process state_register
    if rising_edge(clk_i) then
      if ( rst_i = '1') then
        s_state <= IDLE;
      else
        s_state <= s_next_state;
      end if;
    end if;
  end process p_state_register;

  --==========================================================================
  --! Process: state logic - controls s_next_state based on current state and inputs
  --! read: clk_i , rst_i , s_state , 
  --! write: s_next_state
  --==========================================================================
  p_state_logic: process (s_state , s_next_state , s_adcBusy_d2 , s_trigger_d2 )
  begin  -- process p_state_logic
    case s_state is
      
      when IDLE =>
        if ( s_trigger_d2 = '1' ) then
          s_next_state <= WAIT_FOR_BUSY_HIGH;
        else
          s_next_state <= IDLE;
        end if;

      when WAIT_FOR_BUSY_HIGH =>
        if ( s_adcBusy_d2 = '1' ) then
          s_next_state <= WAIT_FOR_BUSY_LOW;
        else
          s_next_state <= WAIT_FOR_BUSY_HIGH;
        end if;

      when WAIT_FOR_BUSY_LOW =>
        if ( s_adcBusy_d2 = '0' ) then
          s_next_state <= IDLE;
        else
          s_next_state <= WAIT_FOR_BUSY_LOW;
        end if;
        
      when others =>
        s_next_state <= IDLE;
        
    end case;
  end process p_state_logic;
  
  --==========================================================================
  --! Process: Looks for Hold data valid falling edge
  --! read: clk_i , adc_dav_i , s_adc_dav_d1
  --! write: s_state
  --==========================================================================
  p_registerInputs: process (clk_i)
  begin  -- process p_bit_counter
    if rising_edge(clk_i) then
      
      s_trigger_d1 <= trigger_i;
      s_trigger_d2 <= s_trigger_d1 ;

      s_adcBusy_d1 <= adcBusy_i;
      s_adcBusy_d2 <= s_adcBusy_d1 ;
      
    end if;
  end process p_registerInputs;


  --==========================================================================
  --! Set output signals on basis of state
  --==========================================================================
  hold_n_o <= '1' when s_state = IDLE else '0';

  fsmStatus_o <= "00" when s_state = IDLE else
                 "01" when s_state = WAIT_FOR_BUSY_HIGH else
                 "10" when s_state = WAIT_FOR_BUSY_LOW else
                 "00";
                 
end rtl;
--============================================================================
-- architecture end
--============================================================================
