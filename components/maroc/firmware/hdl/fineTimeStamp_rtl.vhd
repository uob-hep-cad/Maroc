--=============================================================================
--! @file fineTimeStamp_rtl.vhd
--=============================================================================
-------------------------------------------------------------------------------
-- --
-- University of Bristol, High Energy Physics Group.
-- --
------------------------------------------------------------------------------- --
--
--! @brief Measures arrival time using ISERDES and IDELAY primitives.
--!        outputs trigger synchronized to 1x clock and 8x clock.
--!        when an event trigger is received the fine-grain timestamps
--!        are captured.
--!        N.B. Have to compile with VHDL-2008 ( if/else generate)
--
--! @author David Cussans , David.Cussans@bristol.ac.uk
--
--! @date 25\2\2013
--
--! @version v0.1
--
--! @details
--!
--!
--! <b>Dependencies:</b>\n
--! Instantiates dualSERDES_1to2
--!
--! <b>References:</b>\n
--! referenced by ipbusFiveMarocTriggerGenerator \n
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

--! Standard library
library IEEE;
--! Standard packages
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use work.fiveMaroc.all;

--! Package containing type definition and constants for IPBUS
use work.ipbus.all;

entity fineTimeStamp is
  
  generic (
    g_BUSWIDTH : positive := 32;
    g_ADDR_WIDTH : positive := 10;
    g_NMAROC   : positive := 5;
    g_NTIMESTAMP_BITS: positive := 5;
    g_NCLKS : positive := 3;
    --                                              0      , 1      , 2      , 3      , 4
    --                                              5      , 6      , 7      , 8      , 9
    g_CLOCK_DOMAIN :  t_integer_array(0 to 9) := ( 0      , 0      , 0      , 0      , 0
                                                  , 0      , 0      , 0      , 0      , 0)
    );
  port (
    clk_1x_i           : in  std_logic;    --! IPBus clock ( 31.25MHz )
    clk_8x_i           : in  std_logic;    --! 4 x IPBus clock ( 250 MHz )
    --clk_8x_strobe_i    : in  std_logic;    --! Strobes every other cycle of clk_8x
    --clk_16x_i          : in  std_logic;    --! eight time IPBus clock freq
    clk_16x_i          : in  std_logic_vector(g_NCLKS-1 downto 0);    --! eight time IPBus clock freq
    reset_i            : in  std_logic;  --! Resets pointers, active high, synchronous with clk_1x
    event_trig_i       : in  std_logic;  --! Goes high for one cycle of clk_1x for each event. Causes fine timestamps to be written to buffer
    trigger_number_i   : in  std_logic_vector(g_BUSWIDTH-1 downto 0);  --!Current trigger number
    coarse_timestamp_i : in  std_logic_vector(g_BUSWIDTH-1 downto 0);  --! Timestamp clocked with clk_1x_i
    trig_in_a_i        : in  std_logic_vector(g_NMAROC-1 downto 0);    --! async trigger inputs
    trig_out_8x_o      : out std_logic_vector(g_NMAROC-1 downto 0);      --! trigger syncronized onto clk_8x
    trig_out_1x_o      : out std_logic_vector(g_NMAROC-1 downto 0);      --! trigger syncronized onto clk_1x

    write_address_o    : out std_logic_vector(g_ADDR_WIDTH-1 downto 0); --! next location in dual-port buffer memory that will get written to

    -- IPBus for access to DPR
    ipbus_clk_i : in std_logic;
    ipbus_i : in  ipb_wbus;
    ipbus_o : out ipb_rbus

    );   

end fineTimeStamp;

architecture rtl of fineTimeStamp is

  subtype t_finetimestamp_value is std_logic_vector(g_NTIMESTAMP_BITS-1 downto 0) ;  -- ! Subtype to allow an array of timestamps
  type t_finetimestamp_array is array (0 to g_NMAROC-1) of t_finetimestamp_value;  -- ! Type for array of finetimestamps
  signal s_finetimestamps : t_finetimestamp_array;

--  subtype t_timestamp_value is std_logic_vector(g_BUSWIDTH-1 downto 0);  -- ! Subtype to allow an array of timestamps
--  type t_timestamp_array is array (0 to g_NMAROC-1) of t_timestamp_value;  -- ! Type for array of timestamps
  signal s_timestamps : t_dual_timestamp_array;

  signal s_trig_out_1x : std_logic_vector(trig_out_1x_o'range) := ( others => '0') ;  
                                        -- internal copy of trigger on 1x clock domain. Needed since can't read output port...
begin  -- rtl

  -----------------------------------------------------------------------------
  -- Start of generate loop
  gen_inputs: for iMaroc in 0 to g_NMAROC-1 generate

    begin

      -- Instantiate an input time-stamping circuit. Because of limitations in
      -- FPGA fabric need different clock domains and not all input circuits
      -- can use two ISERDES.
      cmp_singleFineTimeStamp : entity work.singleFineTimeStamp
        generic map (
          g_BUSWIDTH => g_BUSWIDTH
          )
        port map (
          clk_1x_i           => clk_1x_i,
          clk_8x_i           => clk_8x_i,
          clk_8x_strobe_i    => clk_8x_strobe_i( g_CLOCK_DOMAIN(iMaroc) ),
          clk_16x_i          => clk_16x_i( g_CLOCK_DOMAIN(iMaroc) ),
          reset_i            => reset_i,
          timestamp_o        => s_finetimestamps(iMaroc),
          trig_in_a_i        => trig_in_a_i(iMaroc),
          trig_out_8x_o      => trig_out_8x_o(iMaroc),
          trig_out_1x_o      => s_trig_out_1x(iMaroc)
          );
         
      -- purpose: combines the coarse timestamp (32ns resolution) with the fine-grain timestamp (1ns resolution)
      -- type   : combinational
      -- inputs : clk_1x_i , s_finetimestamps
      -- outputs: s_timestamps
      proc_combine_coarse_fine: process (clk_1x_i)
      begin  -- process proc_combine_coarse_fine
        if rising_edge(clk_1x_i) and (s_trig_out_1x(iMaroc)='1') then
          s_timestamps(iMaroc) <= coarse_timestamp_i( (g_BUSWIDTH-g_NTIMESTAMP_BITS-1) downto 0) &  s_finetimestamps(iMaroc)  ;
        end if;
      end process proc_combine_coarse_fine;
              
    end generate gen_inputs;
-------------------------------------------------------------------------------
    
    trig_out_1x_o <= s_trig_out_1x;

    -- Instantiate a buffer to store timestamps.
    cmp_timeStampDPRAM : entity work.timeStampDPRAM
      generic map (
        g_BUSWIDTH  => g_BUSWIDTH,
        g_ADDRWIDTH => g_ADDR_WIDTH)
      port map (
        clk_i           => clk_1x_i,
        reset_i         => reset_i,
        event_trigger_i => event_trig_i,
        trigger_number_i=> trigger_number_i,
        timestamp_i     => s_timestamps,
        event_timestamp_i => coarse_timestamp_i,
        write_pointer_o => write_address_o,

        ipbus_clk       => ipbus_clk,
        ipbus_i         => ipbus_i,
        ipbus_o         => ipbus_o
        
        );

end rtl;
