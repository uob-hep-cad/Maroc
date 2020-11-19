--=============================================================================
--! @file clocks_a7_extclk_multiclk_xtal.vhd
--=============================================================================
--@brief Generates a 500MHz clock for sampling input, 250MHz clock for trigger
--!logic, 31.25MHz ipbus clock from a 25MHz reference
--! Generates  a 125MHz ethernet clock from on-board Xtal.
--!Includes reset logic for ipbus
--
--! PLL setting produced using Xilinx clock wizard.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clocks_a7_extclk_multiclk_xtal is
  generic (
    g_NCLKS : positive := 3);  -- number of clocks to generate for input deserializers
  port
    (-- Clock in ports
      extclk_P         : in     std_logic; --! 25MHz clock from HDMI
      extclk_N         : in     std_logic;
      sysclk           : in     std_logic; --! system clock from on-board Xtal ( 50MHz on Enclustra AX3 )
      -- Clock out ports
      --clko_125          : out    std_logic;
      --clko_ipb          : out    std_logic;
      clko_1x          : out    std_logic; -- 31.25MHz
      clko_8x          : out    std_logic; -- 250MHz
      clko_16x         : out    std_logic_vector(g_NCLKS-1 downto 0);  --! 500MHz
      -- Status and control signals
      clock_status     : out    std_logic_vector(g_NCLKS+1 downto 0);  --! bit-0=DCM-lock , 1=PLL-lock, 2 .. g_NCLKS+1=bufpll_lock(0) .. buffpll_lock(g_NCLKS-1)
      onehz            : out    std_logic
 );
end clocks_a7_extclk_multiclk_xtal;

architecture rtl of clocks_a7_extclk_multiclk_xtal is

  -- Input clock buffering / unused connectors
  signal extclk     : std_logic;

  signal clk_1x_s : std_logic;
  signal clk_8x_s : std_logic;
  signal clk_16x_s : std_logic;
  
  signal d25, d25_d : std_logic;
  signal pll_locked : std_logic:= '0';  -- Lock status of two PLLs

  signal s_rst: std_logic := '0';
  
  component clock_divider_s6 port(
    clk: in std_logic;
    d25: out std_logic;
    d28: out std_logic
    );
  end component;

begin


  cmp_clk_gen: entity work.clk_adcs
  port map
  (
  -- Clock out ports  
  clk_1x   => clk_1x_s,
  clk_8x   => clk_8x_s,
  clk_16x   => clk_16x_s,
  -- Status and control signals               
  reset   => '0', 
  locked  => pll_locked,
 -- Clock in ports
  clk_in1_p   => extclk_P,
  clk_in1_n   => extclk_N
  );
  
  -- Output buffering for IPBus clock , 250MHz clock ( clk_fast) and
  -- 500MHz clock ( clk_2x_fast )
  -------------------------------------

  gen_BUFIO: for iBUFIO in 0 to g_NCLKS-1 generate
    begin
      cmp_BUFIO : BUFIO
   port map (
      O => clko_16x(iBUFIO), -- 1-bit output: Clock output (connect to I/O clock loads).
      I => clk_16x_s  -- 1-bit input: Clock input (connect to an IBUF or BUFMR).
   );

    end generate gen_BUFIO;


cmp_BUFR : BUFR
   generic map (
      BUFR_DIVIDE => "BYPASS",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8" 
      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES" 
   )
   port map (
      O => clko_8x,  -- 1-bit output: Clock output port
      CE => '1',     -- 1-bit input: Active high, clock enable (Divided modes only)
      CLR => s_rst,  -- 1-bit input: Active high, asynchronous clear (Divided modes only)
      I => clk_8x_s  -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
   );

  clko_1x <= clk_1x_s;


  
--  -------------------------------------------------------------------------
--  clkdiv: clock_divider_s6 port map(
--    clk => sysclk,
--    d25 => d25,
--    d28 => onehz
--    );
onehz <= '0';

  --process(sysclk)
  --begin
  --  if rising_edge(sysclk) then
  --    d25_d <= d25;
  --    if d25='1' and d25_d='0' then
  --      s_rst <= not pll_locked;
  --    end if;
  --  end if;
  --end process;

  --! bit-0=DCM-lock , 1=PLL-lock, 2 .. g_NCLKS+1=bufpll_lock(0) .. buffpll_lock(g_NCLKS-1)
  clock_status( clock_status'left downto 2 ) <= ( others => '0');
  clock_status(1 downto 0)  <= pll_locked & "0";
  
end rtl;
