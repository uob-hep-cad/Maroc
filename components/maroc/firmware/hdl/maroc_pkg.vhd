--=============================================================================
--! @file maroc_pkg.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- unit name: maroc
--
--! @brief User defined types for MAROC readout code.
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
--! referenced by marocShiftReg \n
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package maroc is

  constant c_NUMADC : integer := 64;  --! number of ADCs in a MAROC
  constant c_NUMADCBITS : integer := 12;  --! Number of bits for each ADC

  constant c_NWORDS : integer := 26;    --! number of 32-bit words carrying data to/from MAROC shift register

  constant c_BUSWIDTH : integer := 32;  --! Width of IPBus bus

  constant c_NBITS : integer := 829;    -- ! Number of bits to shift out
  
  --! Define a type to pass data to/from MAROC shift register interface. 
--  type t_wordarray is array (c_NWORDS-1 downto 0) of std_logic_vector(c_BUSWIDTH-1 downto 0);
    type t_wordarray is array (31 downto 0) of std_logic_vector(c_BUSWIDTH-1 downto 0);

  constant c_NMAROC : integer := 1;     -- -! Number of MAROC chips
  
  type maroc_input_signals is record          -- Signals going to MAROC
    CK_40M:  STD_LOGIC;
    HOLD2_2V5:  STD_LOGIC;
    HOLD1_2V5:  STD_LOGIC;
    EN_OTAQ_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    CTEST_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    START_ADC_2V5_N:  STD_LOGIC;
    RST_ADC_2V5_N:  STD_LOGIC;
    RST_SC_2V5_N:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    D_SC_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    RST_R_2V5_N:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    D_R_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    CK_R_2V5:  STD_LOGIC;
    CK_SC_2V5:  STD_LOGIC;
  end record;

  type maroc_output_signals is record          -- Signals going from MAROC
    CK_40M_OUT_2V5:  STD_LOGIC;
    OR1_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    OR0_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    ADC_DAV_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    OUT_ADC_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    Q_SC_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    Q_R_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
  end record;

end maroc;
