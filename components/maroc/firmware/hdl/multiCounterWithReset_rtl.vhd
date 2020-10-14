--=============================================================================
--! @file multiCounterWithReset_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: multiCounterWithReset (multiCounterWithReset / rtl)
--
--! @brief A number of simple counter with synchronous reset. Single output
--! selected by address.
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date Feb\2013
--
--! @version v0.1
--
--! @details
--!
--! <b>Dependencies:</b>\n
--! None
--!
--! <b>References:</b>\n
--! referenced by ipBusMarocTriggerGenerator \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
--! \n
--! 
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
---------------------------------------------------------------------------------

--============================================================================
--! Entity declaration for multiCounterWithReset
--============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY multiCounterWithReset IS
  GENERIC (
    g_COUNTER_WIDTH : positive := 32; --! width of counters 
    g_NUM_COUNTERS : positive := 5;  --! number of counters
    g_ADDR_WIDTH : positive := 3  --! width of address bus used to select counter
    );
  PORT (
    clock_i: 	IN STD_LOGIC;  --! rising edge active clock
    reset_i:       	IN STD_LOGIC;  --! syncronous with rising clk
    enable_i:       IN STD_LOGIC_VECTOR(g_NUM_COUNTERS-1 downto 0);  --! counts when enable=1
    result_o:	OUT STD_LOGIC_VECTOR ( g_COUNTER_WIDTH-1 downto 0); --! Unsigned integer output
    select_i:       in STD_LOGIC_VECTOR(g_ADDR_WIDTH-1 downto 0) --! selects which counter output is driven to result_o
    );
END multiCounterWithReset;

ARCHITECTURE rtl OF multiCounterWithReset IS

  subtype t_counter_type is std_logic_vector(g_COUNTER_WIDTH-1 downto 0);
  type t_counter_array is array (0 to (2**select_i'length)-1  ) of t_counter_type;  --! Define a type for an array of counters
  SIGNAL s_result_reg ,  s_result_reg_d1 : t_counter_array;
  signal s_integer_select : natural  := 0;  --! select_i converted to unsigned. Do in two stages for readability
  signal s_select_in_range : boolean := false;  -- set true when select_i points to a counter that exists.
  
BEGIN

  -- instantiate a set of counters
  gen_counters: for v_counter in 0 to g_NUM_COUNTERS-1 generate
    cmp_counter: entity work.counterWithReset 
      generic map (
        g_COUNTER_WIDTH => g_COUNTER_WIDTH)
      port map (
        clock_i  => clock_i,
        reset_i  => reset_i,
        enable_i => enable_i(v_counter),
        result_o => s_result_reg(v_counter) );

  end generate gen_counters;

  -- purpose: Register output data in a desparate attempt to fix problems with incorrect counter values being read ( skipping up and down ... )
  -- type   : combinational
  -- inputs : clock_i
  -- outputs: s_result_reg_d1
  p_register_counters: process (clock_i)
  begin  -- process p_register_counters
    if rising_edge(clock_i) then
      s_result_reg_d1 <=  s_result_reg;
    end if;
  end process p_register_counters;
  
  --! Asynchronous output of selected counter ( might need to add a register stage)
  s_integer_select <= to_integer(unsigned(select_i));
  s_select_in_range <= true when (s_integer_select < g_NUM_COUNTERS) else false;
  result_o <= STD_LOGIC_VECTOR(s_result_reg_d1(s_integer_select)) when s_select_in_range
              else (others => '1');
  
END rtl;		
