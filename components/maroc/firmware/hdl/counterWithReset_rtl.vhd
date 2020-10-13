--=============================================================================
--! @file counterWithReset_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: counterWithReset (counterWithReset / rtl)
--
--! @brief Simple counter with synchronous reset
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date Feb\2012
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
--! 5/Mar/12 DGC Changed to use numeric_std\n
--! 
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
---------------------------------------------------------------------------------

--============================================================================
--! Entity declaration for counterWithReset
--============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY counterWithReset IS
  GENERIC (g_COUNTER_WIDTH : integer := 32);
  PORT
	(
		clock_i: 	IN STD_LOGIC;  --! rising edge active clock
		reset_i:       	IN STD_LOGIC;  --! syncronous with rising clk
		enable_i:       IN STD_LOGIC;  --! counts when enable=1
		result_o:	OUT STD_LOGIC_VECTOR ( g_COUNTER_WIDTH-1 downto 0) --! Unsigned integer output
                
	);
END counterWithReset;

ARCHITECTURE rtl OF counterWithReset IS
	SIGNAL s_result_reg : UNSIGNED ( g_COUNTER_WIDTH-1 downto 0);
BEGIN
	PROCESS (clock_i)
	BEGIN
		IF (clock_i'event AND clock_i = '1' ) THEN
			IF (reset_i = '1') THEN
				s_result_reg <= (others => '0');
			ELSIF (enable_i='1') THEN
				s_result_reg <= s_result_reg + 1;
			END IF;
		END IF;
	END PROCESS;

	result_o <= STD_LOGIC_VECTOR(s_result_reg);
END rtl;		
