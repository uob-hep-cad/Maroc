--=============================================================================
--! @file clocks_s6_extclk_multiclk_xtal.vhd
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

entity clocks_s6_extclk_multiclk_xtal is
  generic (
    g_NCLKS : positive := 3);  -- number of clocks to generate for input deserializers
  port
    (-- Clock in ports
      extclk_P         : in     std_logic;
      extclk_N         : in     std_logic;
      sysclk_P         : in     std_logic;
      sysclk_N         : in     std_logic;
      -- Clock out ports
      clko_125          : out    std_logic;
      clko_ipb          : out    std_logic;
      clko_ipb_n       : out    std_logic;
      clko_fast        : out    std_logic;
      clko_2x_fast     : out    std_logic_vector(g_NCLKS-1 downto 0);  --! twice speed of fast clock
      clko_fast_strobe : out    std_logic_vector(g_NCLKS-1 downto 0);  --! strobes every other clko_2x_fast cycle. Use for ISERDES
      -- Status and control signals
      clock_status     : out    std_logic_vector(g_NCLKS+1 downto 0);  --! bit-0=DCM-lock , 1=PLL-lock, 2 .. g_NCLKS+1=bufpll_lock(0) .. buffpll_lock(g_NCLKS-1)
      rsto_125         : out    std_logic;
      rsto_ipb         : out    std_logic;
      onehz            : out    std_logic
 );
end clocks_s6_extclk_multiclk_xtal;

architecture rtl of clocks_s6_extclk_multiclk_xtal is

  -- Input clock buffering / unused connectors
  signal extclk,sysclk      : std_logic;
  -- Output clock buffering / unused connectors
  signal clkfbout         : std_logic;
  signal clk_125_s          : std_logic;
  signal clk_ipb_s , clk_ipb_n_s : std_logic;
  signal clk_fast_s : std_logic;
  signal clk_2x_fast_s ,  clk_fast_internal : std_logic;
  signal clk_2x_fast_internal   : std_logic_vector(g_NCLKS-1 downto 0);
  signal s_clkfbin_buf    : std_logic;
  signal clkout4_unused , clkout5_unused   : std_logic;

  signal d25, d25_d : std_logic;
  signal pll_locked : std_logic:= '0';  -- Lock status of two PLLs
  signal dcm_locked : std_logic:= '0';  -- Lock status of DCM
  signal bufpll_locked: std_logic_vector(g_NCLKS-1 downto 0);
  signal rst: std_logic := '1';

  signal clk_ipb_b, clk_ipb_n_b , clk_125_b: std_logic;
  
  component clock_divider_s6 port(
    clk: in std_logic;
    d25: out std_logic;
    d28: out std_logic
    );
  end component;

begin


  -- Input buffering for external clock ( on HDMI cable)
  --------------------------------------
  extclk_buf : IBUFGDS
  port map
   (O  => extclk,
    I  => extclk_P,
    IB => extclk_N);

  -- PLL for generation of IPBus clock, 250MHz clock, 500MHz clk
  --------------------------------------
  -- Instantiation of the PLL primitive
  --    * Unused inputs are tied off
  --    * Unused outputs are labeled unused

  pll_base_inst0 : PLLE2_BASE
  generic map
    (BANDWIDTH            => "OPTIMIZED",
    CLK_FEEDBACK         => "CLKFBOUT",
    COMPENSATION         => "SYSTEM_SYNCHRONOUS",
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT        => 20,
    CLKFBOUT_PHASE       => 0.000,
    CLKOUT0_DIVIDE       => 2,          -- 250 MHz
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT1_DIVIDE       => 1,          -- 500 MHz
    CLKOUT1_PHASE        => 0.000,
    CLKOUT1_DUTY_CYCLE   => 0.500,
    CLKOUT2_DIVIDE       => 16,         -- 31.25 MHz, 0 deg    CLKOUT2_PHASE        => 0.000,
    CLKOUT2_DUTY_CYCLE   => 0.500,
    CLKOUT3_DIVIDE       => 16,         -- 31.25 MHz, 180 deg
    CLKOUT3_PHASE        => 180.000,
    CLKOUT3_DUTY_CYCLE   => 0.500,
    CLKOUT4_DIVIDE       => 4,          -- 125MHz
    CLKOUT4_PHASE        => 0.000,
    CLKOUT4_DUTY_CYCLE   => 0.500,     
    CLKIN_PERIOD         => 40.0,
    REF_JITTER           => 0.010)
  port map
    -- Output clocks
   (CLKFBOUT            => clkfbout,
    CLKOUT0             => clk_fast_s,    -- 250 MHz
    CLKOUT1             => clk_2x_fast_s, -- 500 MHz
    CLKOUT2             => clk_ipb_s,     -- 31.25 MHz
    CLKOUT3             => clk_ipb_n_s,
    CLKOUT4             => clkout5_unused, -- clk_125_s,
    CLKOUT5             => clkout5_unused,
    -- Status and control signals
    LOCKED              => pll_locked,
    RST                 => '0',
    -- Input clock control
    CLKFBIN             => clkfbout, -- s_clkfbin_buf,
    CLKIN               => extclk);

  -- Feedback buffer
  -----------------------------------------------------------------------------
--  clkfb_buf : BUFIO2FB
--  port map (
--    O => s_clkfbin_buf, -- 1-bit output: Output feedback clock (connect to feedback input of DCM/PLL)
--    I => clk_2x_fast_internal  -- 1-bit input: Feedback clock input (connect to input port)
--  );

  
  -- Output buffering for IPBus clock , 250MHz clock ( clk_fast) and
  -- 500MHz clock ( clk_2x_fast )
  -------------------------------------

  clkipb_buf : BUFG
  port map
   (O   => clk_ipb_b,
    I   => clk_ipb_s);

  clko_ipb <= clk_ipb_b;
  
  clk_fast_buf0 : BUFG
  port map
   (O   => clk_fast_internal,
    I   => clk_fast_s);

  clko_fast <= clk_fast_internal;
  
  clkipb_n_buf : BUFG
  port map
   (O   => clk_ipb_n_b,
    I   => clk_ipb_n_s);

  clko_ipb_n <= clk_ipb_n_b;

  gen_BUFPLL: for iBUFPLL in 0 to g_NCLKS-1 generate
    begin
      cmp_bufpll : BUFPLL
        generic map (
          DIVIDE => 2)
        port map (
          IOCLK  => clk_2x_fast_internal(iBUFPLL),            -- output, I/O clock
          LOCK   => bufpll_locked(iBUFPLL),              -- locked output
          SERDESSTROBE =>  clko_fast_strobe(iBUFPLL),  -- output to ISERDES2
          GCLK   => clk_fast_internal,
          LOCKED => pll_locked ,              -- input from PLL
          PLLIN  => clk_2x_fast_s                 -- BUFG input
          );
    end generate gen_BUFPLL;

  clko_2x_fast <= clk_2x_fast_internal;


  -------------------------------------------------------------------------
  -- 125MHz clock for Ethernet interface.

    -- differential buffer for the xtal on-board clock.
  sysclk_buf : IBUFGDS
    port map
    (O  => sysclk,
     I  => sysclk_P,
     IB => sysclk_N);

  dcm0: DCM_CLKGEN
    generic map(
      CLKIN_PERIOD => 5.0,
      CLKFX_MULTIPLY => 5,
      CLKFX_DIVIDE => 8,
      CLKFXDV_DIVIDE => 4
      )
    port map(
      clkin => sysclk,
      clkfx => clk_125_s,
      clkfxdv => open,
      locked => dcm_locked,
      rst => '0'
      );

  clk125_buf : BUFG
    port map
    (O   => clk_125_b,
     I   => clk_125_s);

  clko_125 <= clk_125_b;
    
  -------------------------------------------------------------------------
  clkdiv: clock_divider_s6 port map(
    clk => sysclk,
    d25 => d25,
    d28 => onehz
    );

  process(sysclk)
  begin
    if rising_edge(sysclk) then
      d25_d <= d25;
      if d25='1' and d25_d='0' then
        rst <= not dcm_locked;
      end if;
    end if;
  end process;
	

  process(clk_ipb_b)
  begin
    if rising_edge(clk_ipb_b) then
      rsto_ipb <= rst;
    end if;
  end process;
	
  process(clk_125_b)
  begin
    if rising_edge(clk_125_b) then
      rsto_125 <= rst;
    end if;
  end process;

  --! bit-0=DCM-lock , 1=PLL-lock, 2 .. g_NCLKS+1=bufpll_lock(0) .. buffpll_lock(g_NCLKS-1)
  clock_status <= bufpll_locked & ( pll_locked , dcm_locked);
  
end rtl;
