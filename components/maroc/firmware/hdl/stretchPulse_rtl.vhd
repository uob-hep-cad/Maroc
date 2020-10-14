--! @file stretchPulse_rtl.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.ALL;

-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- -
--! @brief looks for rising edge of input level then shifts out a pulse.
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--! @date 1/July/2013

entity stretchPulse is
  
  generic (
    --g_OUTPUT_PATTERN : std_logic_vector -- gets shifted out
    g_PULSE_LENGTH : positive := 8
    ) ;  

  port (
    clk_i     : in  std_logic;          -- active high
    level_i   : in  std_logic;          -- active high
    pulse_out : out std_logic);         -- rises high

end stretchPulse;


architecture rtl of stretchPulse is

  signal s_level_d1 , s_level_d2 : std_logic := '0';

  constant c_OUTPUT_PATTERN : std_logic_vector(0 to g_PULSE_LENGTH-1) := (others => '1');  -- Gets shifted out
  
  signal s_shiftReg : std_logic_vector( c_OUTPUT_PATTERN'range ) := ( others => '0');
  
begin  -- rtl

p_shift_data: process (clk_i)
  begin  -- process p_shift_data
    if rising_edge(clk_i) then  -- rising clock edge
      s_level_d1 <= level_i;
      s_level_d2 <= s_level_d1;

      if (s_level_d1='1' and s_level_d2='0') then
        s_shiftReg <= c_OUTPUT_PATTERN;
      else
        s_shiftReg <=  s_shiftReg( 1 to s_shiftReg'right) & '0' ;
      end if;

      pulse_out <= s_shiftReg(0);
      
    end if;
  end process p_shift_data;  

end rtl;
