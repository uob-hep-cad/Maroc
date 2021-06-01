--=============================================================================
--! @file pulseClockDomainCrossing_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture worklib.pulseClockDomainCrossing.rtl
--
--! @brief Takes a pulse synchronized with one clock and produces a
--! pulse synchronized to another clock.
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date September/2012
--
--! @version v0.1
--
--! @details A "ring" of D-type flip-flops is used to transfer a strobe
--! from the input clock domain to the output clock domain and then back again.
--! The time taken to transit from input to output is approximately
--! two clock cycles of clock_output_i .
--! After an additional two cycles of clk_input_i another pulse can be sent
--!
--!
--! <b>Dependencies:</b>\n
--!
--! <b>References:</b>\n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity pulseClockDomainCrossing is
  port (
    clk_input_i : in std_logic;         --! clock for input
    pulse_i     : in std_logic;         --! input pulse. Active high
    clk_output_i: in std_logic;         --! clock for output
    pulse_o     : out std_logic         --! Single cycle pulse synchronized to clock_output_i
    );

end pulseClockDomainCrossing;

architecture rtl of pulseClockDomainCrossing is

  signal s_pulse_out , s_pulse_out_d1 , s_pulse_out_d2 , s_pulse_out_d3 , s_pulse_out_d4 , s_pulse_back_d1 , s_pulse_back_d2: std_logic := '0';
  
begin  -- rtl

  -- purpose: registers and flip-flop on clk_input_i
  p_input_clock_logic: process (clk_input_i)
  begin  
    if rising_edge(clk_input_i) then

      -- Register signals coming from output clock domain back to the
      -- input clock domain
      s_pulse_back_d1 <= s_pulse_out_d2;
      s_pulse_back_d2 <= s_pulse_back_d1;

      -- JK flip-flop
      if (s_pulse_back_d2 = '1')  then
        s_pulse_out <= '0';
      elsif (pulse_i = '1')  then
        s_pulse_out <= '1';
      end if;

    end if;
  end process p_input_clock_logic;

  -- purpose: registers and flip-flop on clk_output_o
  p_output_clock_logic: process (clk_output_i)
  begin  
    if rising_edge(clk_output_i) then

      -- Register signal on input clock domain onto output clock domain
      s_pulse_out_d1 <= s_pulse_out;
      s_pulse_out_d2 <= s_pulse_out_d1;

      s_pulse_out_d3 <= s_pulse_out_d2;
      s_pulse_out_d4 <= s_pulse_out_d3;

      -- Generate single clock-cycle pulse on pulse_o
      pulse_o <= s_pulse_out_d3 and ( not s_pulse_out_d4 );

    end if;
  end process p_output_clock_logic;


end rtl;
