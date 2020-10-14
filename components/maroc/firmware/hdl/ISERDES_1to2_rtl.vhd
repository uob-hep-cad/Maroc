--=============================================================================
--! @file ISERDES_1to2_rtl.vhd
--=============================================================================
--
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
-- VHDL Architecture work.ISERDES_1to2.rtl
--
--! @brief Two 1:2 Deserializers. One has input delayed w.r.t. other\n
--! by setting generic can also build with just one deserializer
--! based on TDC by Alvaro Dosil\n
--! 
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 12:06:53 11/16/12
--
--! @version v0.1
--
--! @details
--! data_o(7) is the most recently arrived data , data_o(0) is the oldest data.
--!
--! <b>Dependencies:</b>\n
--!
--! <b>References:</b>\n
--!
--! <b>Modified by: Alvaro Dosil , alvaro.dosil@usc.es </b>\n
--! <b>Modified by: David Cussans, added generic that controls if one or two
--!                 deserializers are used </b>
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo Implement a periodic calibration sequence\n
--! <another thing to do> \n
--
--------------------------------------------------------------------------------
-- 
-- Created using using Mentor Graphics HDL Designer(TM) 2010.3 (Build 21)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

library unisim ;
use unisim.vcomponents.all;


ENTITY ISERDES_1to2 IS
  generic (
    g_DUAL_ISERDES : boolean := true);  -- ! Set to FALSE to build with only one input ISERDES
   PORT( 
     serdes_reset_i : IN     std_logic;                      --! Starts recalibration sequence
     data_i         : IN     std_logic;
     fastClk_i      : IN     std_logic;                      --! 2x fabric clock. e.g. 500MHz
     fabricClk_i    : IN     std_logic;                      --! clock for output to FPGA. e.g. 250MHz
     strobe_i       : IN     std_logic;                      --! Strobes once every 2 cycles of fastClk
     data_o         : OUT    std_logic_vector (7 DOWNTO 0);  --! Deserialized data. Interleaved between prompt and delayed  serdes.
                                                             --! data_o(0) is the oldest data
     serdes_ready_o : OUT    std_logic                       --! goes low during calibration sequence.
   );

-- Declarations

END ENTITY ISERDES_1to2 ;

--
ARCHITECTURE rtl OF ISERDES_1to2 IS

  constant c_S : positive := 4;                     -- ! SERDES division ratio

  signal s_Data_i_d_p   : std_logic;
  signal s_Data_i_d_d   : std_logic;
  signal s_cal_idelay   : std_logic := '0';         --! Take high to calibrate the IDELAY components
  signal s_rst_idelay   : std_logic := '0';         -- IODELAY reset
  signal s_busy_idelay_p  : std_logic;              -- Indicates that the IDELAY isn't calibrating.
  signal s_busy_idelay_d  : std_logic;              -- Indicates that the IDELAY isn't calibrating.
  signal s_valid_iserdes_p  : std_logic;              -- Indicates that the IDELAY isn't calibrating.
  signal s_valid_iserdes_d  : std_logic;              -- Indicates that the IDELAY isn't calibrating.
  signal s_data_o       : std_logic_vector(7 downto 0);  --! Deserialized data

  
BEGIN

  --! The input circuit is ready if the IODELAY is *not* busy and the ISERDES *is* valid 
  serdes_ready_o <= (not ( s_busy_idelay_p or s_busy_idelay_d))
                    and (s_valid_iserdes_p and s_valid_iserdes_d);
  
  cmp_reset_fsm: entity work.ISERDES_cal_fsm
    port map (
      clk_i             => fabricClk_i,
      reset_i           => serdes_reset_i,
      busy_prompt_i     => s_busy_idelay_p,
      busy_delayed_i    => s_busy_idelay_d,

      reset_o    => s_rst_idelay,
      cal_o      => s_cal_idelay
      
      );
  
  --------------------------------------------------------------------------------------------------------------------------
  -- First IODELAY and ISERDES
  
  IODELAY2_Prompt : IODELAY2
  generic map (
    COUNTER_WRAPAROUND => "WRAPAROUND",  -- "STAY_AT_LIMIT" or "WRAPAROUND" 
    DATA_RATE          => "SDR",            -- "SDR" or "DDR" 
    DELAY_SRC          => "IDATAIN",        -- "IO", "ODATAIN" or "IDATAIN" 
    IDELAY_MODE        => "NORMAL",         -- "NORMAL" or "PCI" 
	 --SERDES_MODE   	  => "MASTER", 			-- <NONE>, MASTER, SLAVE
    IDELAY_TYPE        => "VARIABLE_FROM_HALF_MAX",          -- "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
                              --  or "DIFF_PHASE_DETECTOR" 
    IDELAY_VALUE     => 0,                -- Amount of taps for fixed input delay (0-255)
    IDELAY2_VALUE    => 0,                -- Delay value when IDELAY_MODE="PCI" (0-255)
    ODELAY_VALUE     => 0                -- Amount of taps fixed output delay (0-255)
    --SIM_TAPDELAY_VALUE=> 50               -- Per tap delay used for simulation in ps
   )
  port map (
    BUSY     => s_busy_idelay_p,  -- 1-bit output: Busy output after CAL
    DATAOUT  => s_Data_i_d_p,     -- 1-bit output: Delayed data output to ISERDES/input register
    DATAOUT2 => open,             -- 1-bit output: Delayed data output to general FPGA fabric
    DOUT     => open,             -- 1-bit output: Delayed data output
    TOUT     => open,             -- 1-bit output: Delayed 3-state output
    CAL      => s_cal_idelay,     -- 1-bit input: Initiate calibration input
    CE       => '0',              -- 1-bit input: Enable INC input
    CLK      => fabricClk_i,      -- 1-bit input: Clock input
    IDATAIN  => data_i,           -- 1-bit input: Data input (connect to top-level port or I/O buffer)
    INC      => '0',              -- 1-bit input: Increment / decrement input
    IOCLK0   => fastClk_i,        -- 1-bit input: Input from the I/O clock network
    IOCLK1   => '0',              -- 1-bit input: Input from the I/O clock network
    ODATAIN  => '0',              -- 1-bit input: Output data input from output register or OSERDES2.
    RST      => s_rst_idelay,            -- 1-bit input: reset_i to zero or 1/2 of total delay period
    T        => '0'               -- 1-bit input: 3-state input signal
   );

  ISERDES2_Prompt : ISERDES2
  generic map (
    BITSLIP_ENABLE => FALSE,         -- Enable Bitslip Functionality (TRUE/FALSE)
    DATA_RATE      => "SDR",         -- Data-rate ("SDR" or "DDR")
    DATA_WIDTH     => c_S,           -- Parallel data width selection (2-8)
    INTERFACE_TYPE => "RETIMED",     -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
    SERDES_MODE    => "NONE"         -- "NONE", "MASTER" or "SLAVE" 
   )
  port map (
    -- Q1 - Q4: 1-bit (each) output Registered outputs to FPGA logic
	 Q1     => s_Data_o(0),           -- oldest data
    Q2     => s_Data_o(2),
    Q3     => s_Data_o(4),
    Q4     => s_Data_o(6),           -- most recent data
    --SHIFTOUT => SHIFTOUTsig,       -- 1-bit output Cascade output signal for master/slave I/O
    VALID   => s_valid_iserdes_p,                 -- 1-bit output Output status of the phase detector
    BITSLIP => '0',                  -- 1-bit input Bitslip enable input
    CE0     => '1',                  -- 1-bit input Clock enable input
    CLK0    => fastClk_i,            -- 1-bit input I/O clock network input
    CLK1    => '0',                  -- 1-bit input Secondary I/O clock network input
    CLKDIV  => fabricClk_i,          -- 1-bit input FPGA logic domain clock input
    D       => s_Data_i_d_p,         -- 1-bit input Input data
    IOCE    => strobe_i,             -- 1-bit input Data strobe_i input
    RST     => s_rst_idelay,       -- 1-bit input Asynchronous reset_i input
    SHIFTIN => '0'                   -- 1-bit input Cascade input signal for master/slave I/O
   );


  --------------------------------------------------------------------------------------------------------------------------
  -- Optional IODELAY and ISERDES. Built by default
  gen_DELAYED_ISERDES: if g_DUAL_ISERDES generate
    begin

  IODELAY2_Delayed : IODELAY2
  generic map (
    COUNTER_WRAPAROUND => "WRAPAROUND",  -- "STAY_AT_LIMIT" or "WRAPAROUND" 
    DATA_RATE          => "SDR",         -- "SDR" or "DDR" 
    DELAY_SRC          => "IDATAIN",     -- "IO", "ODATAIN" or "IDATAIN" 
    IDELAY_MODE        => "NORMAL",      -- "NORMAL" or "PCI" 
	 --SERDES_MODE   	  => "SLAVE", 			-- <NONE>, MASTER, SLAVE
    IDELAY_TYPE        => "VARIABLE_FROM_ZERO",       -- "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
                              --  or "DIFF_PHASE_DETECTOR" 
    IDELAY_VALUE       => 0,             -- Amount of taps for fixed input delay (0-255) 10->0.75nS, 11->0.825nS
    IDELAY2_VALUE      => 0,             -- Delay value when IDELAY_MODE="PCI" (0-255)
    ODELAY_VALUE       => 0              -- Amount of taps fixed output delay (0-255)
    --SIM_TAPDELAY_VALUE => 43              -- Per tap delay used for simulation in ps
   )
  port map (
    BUSY     => s_busy_idelay_d,  -- 1-bit output: Busy output after CAL
    DATAOUT  => s_Data_i_d_d,     -- 1-bit output: Delayed data output to ISERDES/input register
    DATAOUT2 => open,             -- 1-bit output: Delayed data output to general FPGA fabric
    DOUT     => open,             -- 1-bit output: Delayed data output
    TOUT     => open,             -- 1-bit output: Delayed 3-state output
    CAL      => s_cal_idelay,              -- 1-bit input: Initiate calibration input
    CE       => '0',              -- 1-bit input: Enable INC input
    CLK      => fabricClk_i,      -- 1-bit input: Clock input
    IDATAIN  => data_i,           -- 1-bit input: Data input (connect to top-level port or I/O buffer)
    INC      => '0',              -- 1-bit input: Increment / decrement input
    IOCLK0   => fastClk_i,              -- 1-bit input: Input from the I/O clock network
    IOCLK1   => '0',              -- 1-bit input: Input from the I/O clock network
    ODATAIN  => '0',              -- 1-bit input: Output data input from output register or OSERDES2.
    RST      => s_rst_idelay,            -- 1-bit input: reset_i to zero or 1/2 of total delay period
    T        => '0'               -- 1-bit input: 3-state input signal
   );

  ISERDES2_Delayed : ISERDES2
  generic map (
    BITSLIP_ENABLE => FALSE,       -- Enable Bitslip Functionality (TRUE/FALSE)
    DATA_RATE      => "SDR",       -- Data-rate ("SDR" or "DDR")
    DATA_WIDTH     => c_S,         -- Parallel data width selection (2-8)
    INTERFACE_TYPE => "RETIMED",   -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
    SERDES_MODE    => "NONE"       -- "NONE", "MASTER" or "SLAVE" 
   )
  port map (
    -- Q1 - Q4: 1-bit (each) output Registered outputs to FPGA logic
    Q1     => s_Data_o(1),         -- Oldest data
    Q2     => s_Data_o(3),
    Q3     => s_Data_o(5),
    Q4     => s_Data_o(7),         -- most recent data
    --SHIFTOUT => SHIFTOUTsig,     -- 1-bit output Cascade output signal for master/slave I/O
    VALID   => s_valid_iserdes_d,               -- 1-bit output Output status of the phase detector
    BITSLIP => '0',                -- 1-bit input Bitslip enable input
    CE0     => '1',                -- 1-bit input Clock enable input
    CLK0    => fastClk_i,          -- 1-bit input I/O clock network input
    CLK1    => '0',                -- 1-bit input Secondary I/O clock network input
    CLKDIV  => fabricClk_i,        -- 1-bit input FPGA logic domain clock input
    D       => s_Data_i_d_d,       -- 1-bit input Input data
    IOCE    => strobe_i,           -- 1-bit input Data strobe_i input
    RST     => s_rst_idelay,     -- 1-bit input Asynchronous reset_i input
    SHIFTIN => '0'                 -- 1-bit input Cascade input signal for master/slave I/O
   );

    end generate gen_DELAYED_ISERDES;
    
 -- If only one ISERDES connect up the other lines as a copy...
    gen_NODELAYED_ISERDES: if ( not g_DUAL_ISERDES) generate
    begin
      s_Data_o(1) <= s_Data_o(0);
      s_Data_o(3) <= s_Data_o(2);
      s_Data_o(5) <= s_Data_o(4);
      s_Data_o(7) <= s_Data_o(6);
    end generate gen_NODELAYED_ISERDES;
  
reg_out : process(fabricClk_i)
begin
  if rising_edge(fabricClk_i) then
    Data_o <= s_Data_o;
  end if;
end process;

END ARCHITECTURE rtl;

