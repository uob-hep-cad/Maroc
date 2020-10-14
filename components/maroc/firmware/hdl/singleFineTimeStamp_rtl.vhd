--=============================================================================
--! @file singleFineTimeStamp_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;


-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
--
--! @brief Measures arrival time using ISERDES and IDELAY primitives.
--!        outputs trigger synchronized to 1x clock and 8x clock.
--!        produces a time with resolution 1/16th of 1x clock
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 11\3\2013
--
--! @version v0.1
--
--! @details
--!
--!
--! <b>Dependencies:</b>\n
--! Instantiates dualSERDES_1to2
--! Instantiates arrivalTimeLUT
--!
--! <b>References:</b>\n
--! referenced by fineTimeStamp \n
--!
--! <b>Modified by:</b>\n
--! Author: 
-------------------------------------------------------------------------------
--! \n\n<b>Last changes:</b>\n
-------------------------------------------------------------------------------
--! @todo <next thing to do> \n
--! <another thing to do> \n
--
-------------------------------------------------------------------------------
--

entity singleFineTimeStamp is
  
  generic (
    g_BUSWIDTH : positive := 32;
    g_DUAL_ISERDES : boolean := TRUE; --! set true for two out of phase ISERDES
    g_TRIG_8x_PRELOAD : std_logic_vector(15 downto 0) := "0000111111111111" --! Pattern clocked out by 8x clock when trigger detected
    );
  port (
    clk_1x_i           : in  std_logic;    --! IPBus clock ( 31.25MHz )
    clk_8x_i           : in  std_logic;    --! 4 x IPBus clock ( 250 MHz )
    clk_8x_strobe_i    : in  std_logic;    --! Strobes every other cycle of clk_16x
    clk_16x_i           : in  std_logic;    --! eight time IPBus clock freq
    reset_i            : in std_logic;  --! Active high
    timestamp_o        : out std_logic_vector(4 downto 0);   --! Timestamp clocked with clk_1x_i.
    trig_in_a_i        : in  std_logic;    --! async trigger inputs
    trig_out_8x_o      : out std_logic;    --! trigger syncronized onto clk_8x
                                           --( and stretched )
    trig_out_1x_o      : out std_logic     --! trigger syncronized onto clk_1x
    );   

end singleFineTimeStamp;

architecture rtl of singleFineTimeStamp is
    signal parallel_data : std_logic_vector(7 downto 0);
    signal s_rising_edge , s_falling_edge , s_multi_edge : std_logic := '0';
    signal s_rising_edge_time , s_falling_edge_time: std_logic_vector(1 downto 0) := "00";
    signal s_last_rising_edge_time : std_logic_vector(s_rising_edge_time'range) := ( others => '0');  -- ! Updated everytime the rising edge flag goes high.
    signal s_sync_shift_reg ,  s_sync_shift_reg_d1 : std_logic_vector(7 downto 0) := ( others => '0' );  -- ! Shift register for s_rising_edge flag. Used to generate strobe for IPBus clock domain and coarse time
    signal s_timestamp : std_logic_vector(timestamp_o'range) := ( others => '0');
    --signal s_8x_timestamp : std_logic_vector(2 downto 0) := ( others => '0');  -- number of 250MHz clock cycles within 31.25MHz (IPBus) clock cycle
    signal s_8x_timestamp : unsigned(2 downto 0) := ( others => '0');  -- number of 250MHz clock cycles within 31.25MHz (IPBus) clock cycle
    signal serdes_ready : std_logic := '0';
    signal s_trig_out_8x_shiftreg : std_logic_vector(g_TRIG_8x_PRELOAD'range ) := ( others => '0' );  -- shift register that is connected to trig_out_8x_o
     
begin  -- rtl

  cmp_iserdes: entity work.ISERDES_1to2
    generic map (
      g_DUAL_ISERDES => g_DUAL_ISERDES)
    PORT MAP (
      serdes_reset_i => reset_i,
      data_i => trig_in_a_i,
      fastClk_i => clk_16x_i,
      fabricClk_i => clk_8x_i,
      strobe_i => clk_8x_strobe_i,
      data_o => parallel_data,
      serdes_ready_o => serdes_ready
      );
          
  -- Instantiate a look-up-table to find pulse arrival time
   cmp_arrival_time_lut : entity work.arrivalTimeLUT
     port map (
       clk_i => clk_8x_i,
       deserialized_data_i => parallel_data,
       first_rising_edge_time_o => s_rising_edge_time,
       last_falling_edge_time_o => s_falling_edge_time,
       rising_edge_o            => s_rising_edge,
       falling_edge_o           => s_falling_edge,
       multiple_edges_o         => s_multi_edge
       );

  -- purpose: update fine-grain time every time there is a rising edge
  -- type   : combinational
  -- inputs : clk_8x_i
  -- outputs: s_last_rising_edge_time
  p_fast_latch_edge_time: process (clk_8x_i)
  begin  -- process p_latch_edge_time
    if rising_edge(clk_8x_i) then
      if (s_rising_edge = '1' ) then
        s_last_rising_edge_time <= s_rising_edge_time;
      else
        s_last_rising_edge_time <= s_last_rising_edge_time;
      end if;

      -- Shift register
      -- If there is a '1' anywhere in the shift register we want to capture the
      -- fine-grain time onto the 1x clock domain.
      s_sync_shift_reg <= s_rising_edge & s_sync_shift_reg(s_sync_shift_reg'high downto 1);

      -- Add register to ease timing closure.
      s_sync_shift_reg_d1 <=  s_sync_shift_reg;
      
      if (s_rising_edge = '1') then
        s_8x_timestamp <= "111";
      else
        s_8x_timestamp <= s_8x_timestamp -1;
      end if;
      
    end if;
  end process p_fast_latch_edge_time;


  -- Combines timestamp clocked on 8x clock (s_8x_timestamp) with timestamp
  -- derived from input ISERDES ( 500MHz if one, 1000MHz effective sample rate if two)
  -- Registers result on clk_1x
  p_slow_latch_edge_time: process (clk_1x_i)
  begin  -- process p_latch_edge_time
    if rising_edge(clk_1x_i) then
      if (s_sync_shift_reg_d1 /= "00000000" ) then
        --s_timestamp <= s_8x_timestamp & s_last_rising_edge_time;
        s_timestamp <= std_logic_vector(s_8x_timestamp) & s_last_rising_edge_time;
        trig_out_1x_o <= '1';
      else
        s_timestamp <= s_timestamp;
        trig_out_1x_o <= '0';
      end if;

    end if;
  end process p_slow_latch_edge_time;

  p_shiftout_trigout_8x: process (clk_8x_i)
  begin  -- process p_shiftout_trigout_8x
    if rising_edge(clk_8x_i) then
      if s_rising_edge = '1' then
        s_trig_out_8x_shiftreg <= g_TRIG_8x_PRELOAD;
      else
        s_trig_out_8x_shiftreg <= '0' & s_trig_out_8x_shiftreg( s_trig_out_8x_shiftreg'left downto 1);

        -- Add register to help with timing closure
        trig_out_8x_o <=  s_trig_out_8x_shiftreg(0);
        
      end if;
    end if;
  end process p_shiftout_trigout_8x;
  
  timestamp_o <= s_timestamp;

  
end rtl;
