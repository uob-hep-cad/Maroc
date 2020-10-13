--=============================================================================
--! @file clocks_s6_extclk.vhd
--=============================================================================
--@brief Generates a 125MHz ethernet clock , 250MHz fast clock and
--!31.25MHz ipbus clock from a 25MHz reference
--!Includes reset logic for ipbus
--
--! Produced using Xilinx clock wizard.
------------------------------------------------------------------------------
-- "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
-- "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
------------------------------------------------------------------------------
-- CLK_OUT1___125.000______0.000______50.0______302.457____260.517
-- CLK_OUT2____31.250______0.000______50.0______428.143____260.517
-- CLK_OUT3___250.000______0.000______50.0______260.138____260.517
--
------------------------------------------------------------------------------
-- "Input Clock   Freq (MHz)    Input Jitter (UI)"
------------------------------------------------------------------------------
-- __primary__________25.000____________0.010

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clocks_s6_extclk is
port
 (-- Clock in ports
  extclk_P         : in     std_logic;
  extclk_N         : in     std_logic;
  -- Clock out ports
  clko_125          : out    std_logic;
  clko_ipb          : out    std_logic;
  clko_ipb_n       : out    std_logic;
  clko_fast        : out    std_logic;
  clko_2x_fast     : out    std_logic;  --! twice speed of fast clock
  clko_fast_strobe : out    std_logic;  --! strobes every other clko_2x_fast cycle. Use for ISERDES
  -- Status and control signals
  LOCKED           : out    std_logic;
  rsto_125         : out    std_logic;
  rsto_ipb         : out    std_logic;
  onehz            : out    std_logic

 );
end clocks_s6_extclk;

architecture rtl of clocks_s6_extclk is

  -- Input clock buffering / unused connectors
  signal extclk      : std_logic;
  -- Output clock buffering / unused connectors
  signal clkfbout         : std_logic;
  signal clk_125_s          : std_logic;
  signal clk_ipb_s , clk_ipb_n_s : std_logic;
  signal clk_fast_s , clk_2x_fast_s ,  clk_fast_internal : std_logic;
  signal clk_2x_fast_internal   : std_logic;
  signal s_clkfbin_buf    : std_logic;
  signal clkout5_unused   : std_logic;

  signal d25, d25_d, pll_locked , bufpll_locked: std_logic;
  signal rst: std_logic := '1';

  signal clk_ipb_b, clk_ipb_n_b , clk_125_b: std_logic;
  
  component clock_divider_s6 port(
    clk: in std_logic;
    d25: out std_logic;
    d28: out std_logic
    );
  end component;

begin


  -- Input buffering
  --------------------------------------
  extclk_buf : IBUFGDS
  port map
   (O  => extclk,
    I  => extclk_P,
    IB => extclk_N);


  -- Clocking primitive
  --------------------------------------
  -- Instantiation of the PLL primitive
  --    * Unused inputs are tied off
  --    * Unused outputs are labeled unused

  pll_base_inst : PLL_BASE
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
    CLKOUT2_DIVIDE       => 16,         -- 31.25 MHz, 0 deg
    CLKOUT2_PHASE        => 0.000,
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
    CLKOUT4             => clk_125_s,
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

  
  -- Output buffering
  -------------------------------------


  clk125_buf : BUFG
  port map
   (O   => clk_125_b,
    I   => clk_125_s);

  clko_125 <= clk_125_b;

  clkipb_buf : BUFG
  port map
   (O   => clk_ipb_b,
    I   => clk_ipb_s);

  clko_ipb <= clk_ipb_b;
  
  clk_fast_buf : BUFG
  port map
   (O   => clk_fast_internal,
    I   => clk_fast_s);

  clko_fast <= clk_fast_internal;
  
  clkipb_n_buf : BUFG
  port map
   (O   => clk_ipb_n_b,
    I   => clk_ipb_n_s);

  clko_ipb_n <= clk_ipb_n_b;

  -- Set up the clock for use in the serdes
--  cmp_bufio2 : BUFIO2
--    generic map (
--      DIVIDE_BYPASS => FALSE,
--      I_INVERT      => FALSE,
--      USE_DOUBLER   => FALSE,
--      DIVIDE        => 2)
--    port map (
--      DIVCLK       => clk_fast_s,
--      IOCLK        => clko_2x_fast,
--      SERDESSTROBE => clko_fast_strobe,
--      I            => clk_2x_fast_s);

  -- Use a BUFPLL to generate SERDES strobe.
  cmp_bufpll : BUFPLL
       generic map (
      DIVIDE => 2)
   port map (
     IOCLK  => clk_2x_fast_internal,            -- output, I/O clock
     LOCK   => bufpll_locked,              -- locked output
     SERDESSTROBE =>  clko_fast_strobe,  -- output to ISERDES2
     GCLK   => clk_fast_internal,
     LOCKED => pll_locked ,              -- input from PLL
     PLLIN  => clk_2x_fast_s                 -- BUFG input
     );
  
  clko_2x_fast <= clk_2x_fast_internal;
  
  clkdiv: clock_divider_s6 port map(
    clk => clk_ipb_s,
    d25 => d25,
    d28 => onehz
    );

  process(extclk)
  begin
    if rising_edge(extclk) then
      d25_d <= d25;
      if d25='1' and d25_d='0' then
        rst <= not pll_locked;
      end if;
    end if;
  end process;
	
  locked <= pll_locked;

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
  
end rtl;
