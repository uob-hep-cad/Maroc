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
   PORT( 
     serdes_reset_i : IN     std_logic;                      --! Starts recalibration sequence
     data_i         : IN     std_logic;                      --! Data from trigger input
     fastClk_i      : IN     std_logic;                      --! 2x fabric clock. e.g. 500MHz
     fabricClk_i    : IN     std_logic;                      --! clock for output to FPGA. e.g. 250MHz
     -- strobe_i       : IN     std_logic;                      --! Strobes once every 2 cycles of fastClk
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


ISERDESE2_inst : ISERDESE2
   generic map (
      DATA_RATE => "DDR",           -- DDR, SDR
      DATA_WIDTH => 8,              -- Parallel data width (2-8,10,14)
      DYN_CLKDIV_INV_EN => "FALSE", -- Enable DYNCLKDIVINVSEL inversion (FALSE, TRUE)
      DYN_CLK_INV_EN => "FALSE",    -- Enable DYNCLKINVSEL inversion (FALSE, TRUE)
      -- INIT_Q1 - INIT_Q4: Initial value on the Q outputs (0/1)
      INIT_Q1 => '0',
      INIT_Q2 => '0',
      INIT_Q3 => '0',
      INIT_Q4 => '0',
      INTERFACE_TYPE => "NETWORKING",   -- MEMORY, MEMORY_DDR3, MEMORY_QDR, NETWORKING, OVERSAMPLE
      IOBDELAY => "NONE",           -- NONE, BOTH, IBUF, IFD
      NUM_CE => 2,                  -- Number of clock enables (1,2)
      OFB_USED => "FALSE",          -- Select OFB path (FALSE, TRUE)
      SERDES_MODE => "MASTER",      -- MASTER, SLAVE
      -- SRVAL_Q1 - SRVAL_Q4: Q output values when SR is used (0/1)
      SRVAL_Q1 => '0',
      SRVAL_Q2 => '0',
      SRVAL_Q3 => '0',
      SRVAL_Q4 => '0'
   )
   port map (
      O => open,                       -- 1-bit output: Combinatorial output
      -- Q1 - Q8: 1-bit (each) output: Registered data outputs
      Q1 => s_data_o(0),
      Q2 => s_data_o(1),
      Q3 => s_data_o(2),
      Q4 => s_data_o(3),
      Q5 => s_data_o(4),
      Q6 => s_data_o(5),
      Q7 => s_data_o(6),
      Q8 => s_data_o(7),
      -- SHIFTOUT1, SHIFTOUT2: 1-bit (each) output: Data width expansion output ports
      SHIFTOUT1 => open,
      SHIFTOUT2 => open,
      BITSLIP => '0',           -- 1-bit input: The BITSLIP pin performs a Bitslip operation synchronous to
                                    -- CLKDIV when asserted (active High). Subsequently, the data seen on the
                                    -- Q1 to Q8 output ports will shift, as in a barrel-shifter operation, one
                                    -- position every time Bitslip is invoked (DDR operation is different from
                                    -- SDR).

      -- CE1, CE2: 1-bit (each) input: Data register clock enable inputs
      CE1 => '1',
      CE2 => '1',
      CLKDIVP => '0',           -- 1-bit input: TBD
      -- Clocks: 1-bit (each) input: ISERDESE2 clock input ports
      CLK => fastClk_i,                   -- 1-bit input: High-speed clock. Drive from BUFIO
      CLKB => not fastClk_i,              -- 1-bit input: High-speed secondary clock
      CLKDIV => fabricClk_i,             -- 1-bit input: Divided clock. Drive from BUFR
      OCLK => '0',                 -- 1-bit input: High speed output clock used when INTERFACE_TYPE="MEMORY" 
      -- Dynamic Clock Inversions: 1-bit (each) input: Dynamic clock inversion pins to switch clock polarity
      DYNCLKDIVSEL => '0', -- 1-bit input: Dynamic CLKDIV inversion
      DYNCLKSEL => '0',       -- 1-bit input: Dynamic CLK/CLKB inversion
      -- Input Data: 1-bit (each) input: ISERDESE2 data input ports
      D => data_i ,                       -- 1-bit input: Data input
      DDLY => '0',                 -- 1-bit input: Serial data from IDELAYE2
      OFB => '0',                   -- 1-bit input: Data feedback from OSERDESE2
      OCLKB => '0',               -- 1-bit input: High speed negative edge output clock
      RST => serdes_reset_i,                   -- 1-bit input: Active high asynchronous reset
      -- SHIFTIN1, SHIFTIN2: 1-bit (each) input: Data width expansion input ports
      SHIFTIN1 => '0',
      SHIFTIN2 => '0'
   );

  --! The input circuit is ready if the IODELAY is *not* busy and the ISERDES *is* valid 
  serdes_ready_o <= '1';

reg_out : process(fabricClk_i)
begin
  if rising_edge(fabricClk_i) then
    Data_o <= s_Data_o;
  end if;
end process;

END ARCHITECTURE rtl;

