--=============================================================================
--! @file arrivalTimeLUT_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture work.ArivalTimeLUT.rtl
--
--! @brief Uses a look-up-table to convert the eight bits from the two 1:4 deserializers\n
--! configured as two 1:2 deserializers into into a 2-bit time
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 12:46:34 11/21/12
--
--! @version v0.1
--
--! @details
--! Based on arrivalTimeLUT_rtl from AIDA TLU code.
--! Rising and falling edge times encoded as a LUT. Contents:
--! MRFrrff ( MSb ... LSB )
--! M = multiple edges present ( more then one rising or falling edge)
--! R = at least one rising edge present
--! F = at least one falling edge present.
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
--! @todo  \n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY arrivalTimeLUT IS
   GENERIC( 
      g_NUM_FINE_BITS   : positive := 2
   );
   PORT( 
      clk_i           : IN     std_logic;   --! Rising edge active. 8 x IPBus clk
      deserialized_data_i      : IN     std_logic_vector (7 DOWNTO 0);                                    -- Output from the two 4-bit deserializers, concatenated with most recent bit of previous clock cycle. Clocked by clk_i . bit-8 is the most recent data
      first_rising_edge_time_o : OUT    std_logic_vector (g_NUM_FINE_BITS-1 DOWNTO 0);  -- Position of rising edge w.r.t. 40MHz strobe. Clocked by clk_4x_logic_i
      last_falling_edge_time_o : OUT    std_logic_vector (g_NUM_FINE_BITS-1 DOWNTO 0);  -- Position of rising edge w.r.t. 40MHz strobe. Clocked by clk_4x_logic_i
      rising_edge_o            : OUT    std_logic;                                                        -- goes high if there is a rising edge in the data. Clocked by clk_4x_logic_i
      falling_edge_o           : OUT    std_logic;                                                        -- goes high if there is a falling edge in the data.Clocked by clk_4x_logic_i
      multiple_edges_o         : OUT    std_logic                                                         -- there is more than one rising or falling edge transition.
   );

-- Declarations

END ENTITY arrivalTimeLUT ;

--
ARCHITECTURE rtl OF arrivalTimeLUT IS

  constant c_FALLING_EDGE_BIT : positive := 2*g_NUM_FINE_BITS;  --! Bit position of bit set when falling edge detected
  constant c_RISING_EDGE_BIT : positive :=  2*g_NUM_FINE_BITS+1;  --! Bit position of bit set when rising edge detected
  constant c_MULTI_EDGE_BIT : positive :=  2*g_NUM_FINE_BITS+2;  --! Bit position of bit set when rising edge detected

  signal s_LUT_entry : std_logic_vector(g_NUM_FINE_BITS*2 +3-1 downto 0);  -- stores intermediate LUT value.

  signal  s_LUT_entry_pointer : integer;  --! Entry in LUT pointed to by deserialized data
  
  type t_LUT is array (natural range <>) of std_logic_vector(g_NUM_FINE_BITS*2 + 3 -1 downto 0);
  --! Lookup table for arrival time and rising/falling edge detection (3bits
  --! for position in 8-bit deserialized data plus two bits for rising/falling 
  -- For now just bodge it up .....
  constant c_LUT : t_LUT(0 to 31) := (
    "0000000" ,
"0010000" ,
"0110001" ,
"0010001" ,
"0110110" ,
"1110110" ,
"0110010" ,
"0011010" ,
"0101011" ,
"1111011" ,
"1110011" ,
"1111011" ,
"0110111" ,
"1110111" ,
"0110011" ,
"0010011" ,
"0101100" ,
"1111100" ,
"1110001" ,
"1111101" ,
"1110110" ,
"1110110" ,
"1110010" ,
"1111110" ,
"0101000" ,
"1111000" ,
"1110001" ,
"1111001" ,
"0100100" ,
"1110100" ,
"0100000" ,
"0000000"
    
    --"0000000",                        -- 0
    -- "0000000",
    -- "0000000",
    -- "0000000",                        -- 3
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0000000",                        -- 7
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0000000",                        -- 11
    -- "0000000",
    -- "0000000",
    -- "0000000",                        -- 14
    -- "0000000",                        -- 15
    -- "0101100",                        -- 16
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0101000",                        -- 24
    -- "0000000",
    -- "0000000",
    -- "0000000",
    -- "0100100",                        -- 28
    -- "0000000",
    -- "0100000",                        -- 30
    -- "0000000"                         -- 31
    );  
  
BEGIN

  -- purpose: uses the deserialized data as a index into
  --          a lookup table holding the position of the first rising edge (if any)
  --          and if there is a rising or falling edge
  -- type   : combinational
  -- inputs : clk_i
  -- outputs: arrival_time_o , rising_edge_o , falling_edge_o
  examine_lut: process (clk_i , deserialized_data_i)
    variable v_LUT_entry_pointer : integer;  --! Entry in LUT pointed to by deserialized data
  begin  -- process examine_lut
    
    v_LUT_entry_pointer := to_integer(unsigned(deserialized_data_i(7 downto 3)));
    s_LUT_entry_pointer <= to_integer(unsigned(deserialized_data_i(7 downto 3)));

    if rising_edge(clk_i) then
--      s_LUT_entry <= c_LUT(to_integer(unsigned(deserialized_data_i(7 downto 3))));
      s_LUT_entry <= c_LUT(v_LUT_entry_pointer);
      first_rising_edge_time_o <= s_LUT_ENTRY(g_NUM_FINE_BITS*2-1 downto g_NUM_FINE_BITS);
      last_falling_edge_time_o <= s_LUT_ENTRY(g_NUM_FINE_BITS-1 downto 0);
      rising_edge_o  <= s_LUT_ENTRY(c_RISING_EDGE_BIT);
      falling_edge_o <= s_LUT_ENTRY(c_FALLING_EDGE_BIT);
      multiple_edges_o <= s_LUT_ENTRY(c_MULTI_EDGE_BIT);
    end if;

  end process examine_lut;
  
END ARCHITECTURE rtl;

