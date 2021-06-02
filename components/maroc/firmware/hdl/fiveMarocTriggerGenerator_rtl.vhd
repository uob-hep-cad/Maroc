--=============================================================================
--! @file fiveMarocTriggerGenerator_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

--! Xilinx primitives
LIBRARY UNISIM;
USE UNISIM.vcomponents.all;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: fiveMarocTriggerGenerator (fiveMarocTriggerGenerator / rtl)
--
--! @brief Takes asynchronous trigger signals, registers them onto clk_8x_i
--! and outputs an externalTrigger_o signal. 
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 19\Jan\2011
--
--! @version v0.1
--
--! @details
--! externalTrigger_i , or1_i , or2_i are the incoming trigger signals.
--! Setting the appropriate bit in triggerSourceSelect_i allows that trigger to contribute
--! bit0 - internalTrigger_i
--! bit1 - externalHdmiTrigger_i
--! bit2 - or1_i
--! bit3 - or2_i
--! bit4 - or1 
--! bit6 - externalGpioTrigger_i
--! Delays trigger by hold1Delay_i cycles of clk_8x_i and then asserts hold1.
--! Delays hold1 by hold2Delay_i cycles of clk_8x_i then asserts hold2
--! After asserting hold2 outputs a pulse on adcStartConversion_o , last for single cycle of clk_sys_i
--! When the ADC controller signals end of conversion by pulsing adcConversionEnd_i then
--! hold1,hold2 are deasserted.
--! Compile with VHDL-2008
--!
--! <b>Dependencies:</b>\n
--! none
--!
--! <b>References:</b>\n
--! referenced by ipBusMarocTriggerGenerator \n
--!
--! <b>Modified by:</b>\n
--! Author:
--! DGC March/2013 - Put pack in register stage for external trigger.
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

ENTITY fiveMarocTriggerGenerator IS
  generic (
    g_BUSWIDTH : integer := 32;
    g_NMAROC   : positive := 5;
    g_NTRIGGER_SOURCES : positive := 7
    );
   PORT( 
      adcBusy_i   : IN     std_logic;                      --! High is any of the MAROC are busy
      clk_8x_i           : IN     std_logic;                      --! Fast clock used to register and delay trigger signals
      clk_sys_i            : IN     std_logic;                      --! system clock used for adcConversionEnd_o , adcConversionStart_i
      reset_i              : in     std_logic;                       --! Active high. Resets s_preDelayHold and counter value
--      conversion_counter_o : out    std_logic_vector( g_BUSWIDTH-1 downto 0); --! Number of ADC conversions since last reset. Wraps round at full scale.
      externalHdmiTrigger_a_i: in std_logic;  --! External trigger ( routed from HDMI connector). Async
      externalGpioTrigger_a_i: in std_logic;  --! External trigger ( routed from TTLU GPIO connector). Async
      internalTrigger_i    : IN     std_logic;                      --! Internal trigger ( from IPBus slave). Assume async w.r.t. clk_8x_i and lasting one or more cycles of clk_8x_i 
      triggerSourceSelect_i : IN    std_logic_vector(g_NTRIGGER_SOURCES-1 downto 0);   --! 7-bit mask to select which trigger inputs are active.
                                                                                    --! bit0 = internal , bit1 = external ,
                                                                                    --! bit2 = or1 , bit3 = or2
                                                                                    --! bit3 = or1 from neighbour , bit5 = or2 from neighbour
                                                                                    --! bit6 = GPIO
      
      hold1Delay_i         : IN     std_logic_vector (g_NMAROC-1 DOWNTO 0);  --! Number of clocks of clk_8x_i to between input trigger and HOLD1 output
      hold2Delay_i         : IN     std_logic_vector (g_NMAROC-1 DOWNTO 0);  --! Number of clocks of clk_8x_i to between input trigger and HOLD2 output

      or1_a_i              : IN     std_logic_vector(g_NMAROC-1 downto 0);                      --! OR1 output from MAROC. Async
      or2_a_i              : IN     std_logic_vector(g_NMAROC-1 downto 0);                      --! OR2 output from MAROC. Async
      or1_from_neighbour_i : in std_logic;  --! OR1 signal from another FPGA on HDMI cable
      or2_from_neighbour_i : in std_logic;  --! OR2 signal from another FPGA on HDMI cable
        
      adcConversionStart_o : OUT    std_logic;                      --! start of conversion signal to ADC controller. Sync with rising edge of clk_sys_i
      externalTrigger_o    : OUT    std_logic;                      --! Trigger output. Sync with rising edge of clk_8x_i
      hold1_o              : OUT    std_logic;                      --! HOLD1 output to MAROC. ACTIVE LOW. Sync with rising edge clk_8x_i
      hold2_o              : OUT    std_logic;                       --! HOLD2 output to MAROC. ACTIVE LOW. Sync with rising edge clk_8x_i
      fsmStatus_o          : out std_logic_vector(1 downto 0)
   );

-- Declarations

END fiveMarocTriggerGenerator ;

--
ARCHITECTURE rtl OF fiveMarocTriggerGenerator IS

  signal s_or1_a , s_or2_a : std_logic := '0';  -- Result of OR signals from all Marocs combined
  signal s_or1_d1 : std_logic;       -- ! OR1 signal delayed by one-clock of clk_8x_i
  signal s_or1_d2 : std_logic;             --!
      
  signal s_or2_d1 : std_logic;             --!
  signal s_or2_d2 : std_logic;             --!

  signal s_or1_from_neighbour_d1 : std_logic;             --!
  signal s_or1_from_neighbour_d2 : std_logic;             --!

  signal s_or2_from_neighbour_d1 : std_logic;             --!
  signal s_or2_from_neighbour_d2 : std_logic;             --!

  signal s_externalHdmiTrigger_d1 : std_logic;             --!
  signal s_externalHdmiTrigger_d2 : std_logic;             --!
  signal s_externalGpioTrigger_d1 : std_logic;             --!
  signal s_externalGpioTrigger_d2 : std_logic;             --!

  signal s_internalTrigger_d1 : std_logic;             --!
  signal s_internalTrigger_d2 : std_logic;             --!

  signal s_hold1 , s_hold2 : std_logic;             --!

  --! hold1,hold2 are active low. This signal gets put through a delay.
  signal s_preDelayHold  : std_logic := '1';             
  
      
  signal s_trig : std_logic;             --! trigger generated from input trigers
  signal s_trig_d1 : std_logic;             --! s_trig clocked onto clk_fast
  signal s_trig_d2 : std_logic;             --! 

  signal s_adcConversionStart : std_logic;  --! Local copy since can't read
                                            --from output port...
  signal s_hold2_d1 : std_logic;  --! 
  signal s_hold2_d2 : std_logic;  --! 
  signal s_hold2_d3 : std_logic;  --! 
  -- signal s_preDelayHold_d1 : std_logic;
  
  attribute mark_debug : string;
  attribute mark_debug of s_adcConversionStart , s_hold2, s_trig , s_internalTrigger_d2 , triggerSourceSelect_i : signal is "true";
 
BEGIN 


  -- Combine all the input trigger signals from the MAROCs into a single signal.
  s_or1_a <=  or1_a_i(0) or or1_a_i(1) or or1_a_i(2) or or1_a_i(3) or or1_a_i(4);
  s_or2_a <=  or2_a_i(0) or or2_a_i(1) or or2_a_i(2) or or2_a_i(3) or or2_a_i(4);

  
  --! purpose: Registers async signals onto fast clock to supress meta-stability
  --! type   : sequential
  --! inputs : clk_8x_i
  --! outputs: 
  p_RegisterSignals: process (clk_8x_i)
  begin  -- process p_RegisterSignals

    if rising_edge(clk_8x_i) then

      s_or1_d1 <= s_or1_a;
      s_or1_d2 <= s_or1_d1;
      
      s_or2_d1 <= s_or2_a;
      s_or2_d2 <= s_or2_d1;

      -- Register signals from other FPGA:
      s_or1_from_neighbour_d1 <=   or1_from_neighbour_i;
      s_or1_from_neighbour_d2 <= s_or1_from_neighbour_d1;
      s_or2_from_neighbour_d1 <=   or2_from_neighbour_i;
      s_or2_from_neighbour_d2 <= s_or2_from_neighbour_d1;

      -- Comment out the following register stages to reduce latency on
      -- incoming external (cosmic ray ) trigger.
      -- However, this seems to cause occasional lock-ups
      s_externalHdmiTrigger_d1 <= externalHdmiTrigger_a_i;
      s_externalHdmiTrigger_d2 <= s_externalHdmiTrigger_d1 ;
      s_externalGpioTrigger_d1 <= externalGpioTrigger_a_i;
      s_externalGpioTrigger_d2 <= s_externalGpioTrigger_d1 ;

      s_internalTrigger_d1 <= internalTrigger_i;
      s_internalTrigger_d2 <= s_internalTrigger_d1 ;

      s_trig_d1 <= s_trig;
      s_trig_d2 <= s_trig_d1;

    end if;
    
  end process p_RegisterSignals;

  --! Form a trigger from the input signals
  s_trig <=   ( s_internalTrigger_d2 and triggerSourceSelect_i(0) ) OR
              ( s_externalHdmiTrigger_d2 and triggerSourceSelect_i(1) ) OR
              ( s_or1_d2 and triggerSourceSelect_i(2) ) OR
              ( s_or2_d2 and triggerSourceSelect_i(3) ) OR
              ( s_or1_from_neighbour_d2 and s_or1_d2  and triggerSourceSelect_i(4) ) OR
              ( s_or2_from_neighbour_d2 and s_or2_d2  and triggerSourceSelect_i(5) ) OR
              ( s_externalGpioTrigger_d2 and triggerSourceSelect_i(6) )
              ;
  
  --! purpose: Finite state machine
  --! Sets hold* low when trigger goes high.
  --! Sets hold* high when either busy drops or reset go high.
  --! type   : sequential
  --! inputs : clk_8x_i , adcBusy_i ,  s_trig_d2 , reset_i
  --! outputs: hold_o
  cmp_holdfsm: entity work.marocHoldFSM
    port map (
      clk_i       => clk_8x_i,
      rst_i       => reset_i,
      trigger_i   => s_trig,
      adcBusy_i   => adcBusy_i,
      hold_n_o    => s_preDelayHold,
      fsmStatus_o => fsmStatus_o 
      );
 
  cmp_generate_external_trig: entity work.stretchPulse
    generic map (
      g_PULSE_LENGTH => 8 )
    port map (
      clk_i     => clk_8x_i,
      level_i  => not s_preDelayHold,
      pulse_out => externalTrigger_o);
  
-- -- -- --

  --! Delay trigger by up to 32 clock cycles then output to hold1 pin
  cmp_delayHold1 : SRLC32E
    generic map (
      INIT => X"00000000")
    port map (
      Q => s_hold1, -- SRL data output 
      Q31 => open, -- SRL cascade output pin 
      A => hold1Delay_i, -- 5-bit shift depth select input 
      CE => '1', -- Clock enable input 
      CLK => clk_8x_i, -- Clock input 
      D => s_preDelayHold -- SRL data input
      ); -- End of SRLC32E_inst instantiation

  hold1_o <= s_hold1;
  
  --! Delay HOLD1 signal by up to 32 (fast) clock cycles then output to hold2
  cmp_delayHold2 : SRLC32E
    generic map (
      INIT => X"00000000")
    port map (
      Q => s_hold2, -- SRL data output 
      Q31 => open, -- SRL cascade output pin 
      A => hold2Delay_i, -- 5-bit shift depth select input 
      CE => '1', -- Clock enable input 
      CLK => clk_8x_i, -- Clock input 
      D => s_hold1 -- SRL data input
      ); -- End of SRLC32E_inst instantiation

  hold2_o <= s_hold2;
  
  -- purpose: registers s_hold2 onto system (slow) clock and detect rising edge to form adcConversionStart_o
  -- type   : sequential
  -- inputs : clk_sys_i,  s_hold1
  -- outputs: adcConversionStart_o
  p_GenerateADCStart: process (clk_sys_i, s_hold2)
  begin  -- process p_GenerateADCStart
    if rising_edge(clk_sys_i) then  -- rising clock edge
      
      s_hold2_d1 <= s_hold2;
      s_hold2_d2 <= s_hold2_d1;
      s_hold2_d3 <= s_hold2_d2;

      s_adcConversionStart <= (not s_hold2_d2) and s_hold2_d3 ;
    end if;
  end process p_GenerateADCStart;

  adcConversionStart_o <= s_adcConversionStart;  
  
END ARCHITECTURE rtl;

