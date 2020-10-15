--=============================================================================
--! @file neighbourTriggerIO_rtl.vhd
--=============================================================================
--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.all;

--! Package containing type definition and constants for MAROC interface
--use work.fiveMaroc.all;


library UNISIM;
use UNISIM.vcomponents.all;

entity neighbourTriggerIO is
  
  generic (
    g_NHDMI_SIGNALS : positive := 4;
    g_NMAROC : positive := 5
    );

  port (
    clk_8x_i           : in    std_logic;  -- ! Clock to register signals
    boardType_na_b_i     : in    std_logic;  -- ! indicates which direction for signals to/from
                                             -- neighbour. 0 = type-A
    hdmi_inout_signals_p : inout std_logic_vector(g_NHDMI_SIGNALS-1 downto 0);  -- ! In/output signals to HDMI cabl
    hdmi_inout_signals_n : inout std_logic_vector(g_NHDMI_SIGNALS-1 downto 0);  -- ! In/output signals to HDMI cabl
    or1_from_neighbour_o : out   std_logic;  -- ! Signal received onto board *from* neighbour
    or1_to_neighbour_i   : in    std_logic_vector(g_NMAROC-1 downto 0);
    or2_from_neighbour_o : out   std_logic;  -- ! Signal received onto board *from* neighbour
    or2_to_neighbour_i   : in    std_logic_vector(g_NMAROC-1 downto 0)
    
    );  -- ! Signal that will be send *to* neighbour

end neighbourTriggerIO;


architecture rtl of neighbourTriggerIO is

    signal s_signal_from_iobufds , s_signal_to_iobufds , s_set_iobufds_direction :  std_logic_vector(g_NHDMI_SIGNALS-1 downto 0) := (others => '0');

    signal s_or1_to_neighbour , s_or2_to_neighbour     : std_logic := '0';  -- ! OR of the OR1 , OR2 signals
    signal s_or1_to_neighbour_d1 , s_or2_to_neighbour_d1     : std_logic := '0';  -- ! OR of the OR1 , OR2 signals
    
begin  -- rtl
  
------------------------------------------------------------------------------------------------------------------------------------
-- Combine OR1 , OR2 signals together and send them off chip.
-- Receive OR1 , OR2 signals from neighbouring FPGA
-- Control the direction of I/O buffers based on boardType_na_b_i
------------------------------------------------------------------------------------------------------------------------------------
  process (clk_8x_i)
  begin
    if rising_edge(clk_8x_i) then
      s_or1_to_neighbour <= or1_to_neighbour_i(0) or or1_to_neighbour_i(1) or or1_to_neighbour_i(2) or or1_to_neighbour_i(3) or or1_to_neighbour_i(4);
      s_or2_to_neighbour <= or2_to_neighbour_i(0) or or2_to_neighbour_i(1) or or2_to_neighbour_i(2) or or2_to_neighbour_i(3) or or2_to_neighbour_i(4);

      -- Need extra register to avoid timing closure problems
      s_or1_to_neighbour_d1 <=  s_or1_to_neighbour;
      s_or2_to_neighbour_d1  <=  s_or2_to_neighbour;

      
      -- If flag is low then we are a type-A board
      if boardType_na_b_i = '0' then

        -- Set direction of buffer
--      s_set_iobufds_direction(0) <= '0';  -- clk is output
--      s_set_iobufds_direction(1) <= '1';  -- data0 is input
--      s_set_iobufds_direction(2) <= '0';  -- data1 is output
--      s_set_iobufds_direction(3) <= '1';  -- data2 is input

        -- Connect up signals from FPGA *to* its neighbour
        s_signal_to_iobufds(0) <= s_or1_to_neighbour_d1;
        s_signal_to_iobufds(1) <= '0';
        s_signal_to_iobufds(2) <= s_or2_to_neighbour_d1;
        s_signal_to_iobufds(3) <= '0';

        -- connect up signals to FPGA *from* its neighbour
         or1_from_neighbour_o <= s_signal_from_iobufds(1);
         or2_from_neighbour_o <= s_signal_from_iobufds(3);

        
      else
        -- If flag is high then we are a type-B board
        
 --       s_set_iobufds_direction(0) <= '1';  -- clk is input
 --       s_set_iobufds_direction(1) <= '0';  -- data0 is output
 --       s_set_iobufds_direction(2) <= '1';  -- data1 is input
 --       s_set_iobufds_direction(3) <= '0';  -- data2 is output

        s_signal_to_iobufds(0) <= '0';
        s_signal_to_iobufds(1) <= s_or1_to_neighbour_d1;
        s_signal_to_iobufds(2) <= '0';
        s_signal_to_iobufds(3) <= s_or2_to_neighbour_d1;

        -- connect up signals to FPGA *from* its neighbour
        or1_from_neighbour_o <= s_signal_from_iobufds(0);
        or2_from_neighbour_o <= s_signal_from_iobufds(2);
        
      end if;
      
    end if;
  end process;


-- Connectivity:
-- If board set to "Type A"
-- CLK   --> OR1 out  --> (0)
-- Data0 --> OR1 in   --> (1)
-- Data1 --> OR2 out  --> (2)
-- Data2 --> OR2 in   --> (3)
-- If board set to "Type B"
-- CLK   --> OR1 in  --> (0)
-- Data0 --> OR1 out   --> (1)
-- Data1 --> OR2 in  --> (2)
-- Data2 --> OR2 out   --> (3)


  s_set_iobufds_direction(0) <= '0' when ( boardType_na_b_i = '0') else '1' ;  -- clk
  s_set_iobufds_direction(1) <= '1' when ( boardType_na_b_i = '0') else '0' ;  -- data0
  s_set_iobufds_direction(2) <= '0' when ( boardType_na_b_i = '0') else '1' ;  -- data1
  s_set_iobufds_direction(3) <= '1' when ( boardType_na_b_i = '0') else '0' ;  -- data2


-- Instantiate four IOBUFDS for the four differential lines in HDMI connector
  gen_IOBUFDS : for iBuf in 0 to 3 generate

    IOBUFDS_or1_AB : IOBUFDS
      generic map (
        IOSTANDARD => "LVDS_25",
        DIFF_TERM  => true)
      port map (
        O   => s_signal_from_iobufds(iBuf),  -- Buffer output from pads to FPGA
        IO  => hdmi_inout_signals_p(iBuf),  -- Diff_p inout (connect directly to top-level port)
        IOB => hdmi_inout_signals_n(iBuf),  -- Diff_n inout (connect directly to top-level port)
        I   => s_signal_to_iobufds(iBuf),   -- Buffer input from FPGA to pads
        T   => s_set_iobufds_direction(iBuf)  -- 3-state enable input, high=input, low=output
        );

  end generate gen_IOBUFDS;




  

end rtl;
