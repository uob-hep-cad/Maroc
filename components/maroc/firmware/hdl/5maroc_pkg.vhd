--=============================================================================
--! @file 5maroc_pkg.vhd
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
--! 23/March/2012 DGC Use single MAROC file as basis for 5 maroc \
--! 1/Nov/12 DGC Added Mask ( selects which MAROCs are expected to respond to trigger\
--! <extended description>
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
---------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package fiveMaroc is

  constant c_NUMADC : integer := 64;  --! number of ADCs in a MAROC
  constant c_NUMADCBITS : integer := 12;  --! Number of bits for each ADC

  constant c_NWORDS : integer := 26;    --! number of 32-bit words carrying data to/from MAROC shift register

  constant c_BUSWIDTH : integer := 32;  --! Width of IPBus bus

  constant c_NBITS : integer := 829;    -- ! Number of bits to shift out
  
  --! Define a type to pass data to/from MAROC shift register interface. 
--  type t_wordarray is array (c_NWORDS-1 downto 0) of std_logic_vector(c_BUSWIDTH-1 downto 0);
    type t_wordarray is array (31 downto 0) of std_logic_vector(c_BUSWIDTH-1 downto 0);

  constant c_NMAROC : integer := 5;     -- -! Number of MAROC chips

  -- constant c_NCLKS : positive := 2;     -- Number of fast clocks for input deserializers
  constant c_NCLKS : positive := 1;     -- Number of fast clocks for input deserializers
  
  type t_timestamp_array is array (0 to c_NMAROC-1) of std_logic_vector(c_BUSWIDTH-1 downto 0) ;
  type t_dual_timestamp_array is array (0 to (2*c_NMAROC)-1) of std_logic_vector(c_BUSWIDTH-1 downto 0);

  type t_integer_array is array (natural range <>) of integer;  -- ! Used to pass clock domain values into fineTimestap
  type t_bool_array is array (natural range <>) of boolean;  -- ! Used to pass single/dual ISERDES flag to fineTimestamp
  
  type maroc_input_signals is record          -- Signals going to MAROC
    CK_40M:  STD_LOGIC;
    HOLD2_2V5:  STD_LOGIC;
    HOLD1_2V5:  STD_LOGIC;
    EN_OTAQ_2V5:  STD_LOGIC;
    CTEST_2V5:  STD_LOGIC;
    START_ADC_2V5_N:  STD_LOGIC;
    RST_ADC_2V5_N:  STD_LOGIC;
    RST_SC_2V5_N:  STD_LOGIC;
    D_SC_2V5:  STD_LOGIC;
    RST_R_2V5_N:  STD_LOGIC;
    D_R_2V5:  STD_LOGIC;
    CK_R_2V5:  STD_LOGIC;
    CK_SC_2V5:  STD_LOGIC;
    MAROC_SELECT: STD_LOGIC_VECTOR(2 downto 0);
--    MAROC_MASK: STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
  end record;

  type maroc_output_signals is record          -- Signals going from MAROC
    CK_40M_OUT_2V5:  STD_LOGIC;
    OR1_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    OR0_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    ADC_DAV_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    OUT_ADC_2V5:  STD_LOGIC_VECTOR(c_NMAROC-1 downto 0);
    Q_SC_2V5:  STD_LOGIC;
    Q_R_2V5:  STD_LOGIC;
  end record;

  type hdmi_input_signals is record          -- Signals coming into FPGA
    HDMI0_CLK_P:  std_logic;
    HDMI0_CLK_N:  std_logic;
    HDMI1_CLK_P:  std_logic;
    HDMI1_CLK_N:  std_logic;        
    HDMI0_DATA_P:  std_logic_vector(2 downto 0);
    HDMI0_DATA_N:  std_logic_vector(2 downto 0);
    HDMI1_DATA_P:  std_logic_vector(2 downto 0);
    HDMI1_DATA_N:  std_logic_vector(2 downto 0);
  end record;

  type hdmi_output_signals is record          -- Signals going from FPGA
    HDMI0_CLK_P:  std_logic;
    HDMI0_CLK_N:  std_logic;
    HDMI1_CLK_P:  std_logic;
    HDMI1_CLK_N:  std_logic;        
    HDMI0_DATA_P:  std_logic_vector(2 downto 0);
    HDMI0_DATA_N:  std_logic_vector(2 downto 0);
    HDMI1_DATA_P:  std_logic_vector(2 downto 0);
    HDMI1_DATA_N:  std_logic_vector(2 downto 0);
  end record;

  type hdmi_inout_signals is record          -- Signals going from FPGA
    HDMI0_CLK_P:  std_logic;
    HDMI0_CLK_N:  std_logic;
    HDMI1_CLK_P:  std_logic;
    HDMI1_CLK_N:  std_logic;        
    HDMI0_DATA_P:  std_logic_vector(2 downto 0);
    HDMI0_DATA_N:  std_logic_vector(2 downto 0);
    HDMI1_DATA_P:  std_logic_vector(2 downto 0);
    HDMI1_DATA_N:  std_logic_vector(2 downto 0);
  end record;

end fiveMaroc;
