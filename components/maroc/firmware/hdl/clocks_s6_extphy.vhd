-- clocks_s6_extphy
--
-- Generates a 125MHz ethernet clock and 31MHz ipbus clock from the 200MHz reference
-- Includes reset logic for ipbus
--
-- Dave Newbold, April 2011
--
-- $Id$

library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.VComponents.all;

entity clocks_s6_extphy is port(
	sysclk_p, sysclk_n: in std_logic;
	clko_125: out std_logic;
	clko_ipb: out std_logic;
	clko_fast: out std_logic;
	locked: out std_logic;
	rsto_125: out std_logic;
	rsto_ipb: out std_logic;
	onehz: out std_logic
	);

end clocks_s6_extphy;

architecture rtl of clocks_s6_extphy is

	signal clk_ipb_i, clk_ipb_b, clk_125_i, clk_125_b, sysclk: std_logic;
	signal d25, d25_d, dcm_locked: std_logic;
	signal rst: std_logic := '1';
	signal clk_400: std_logic;
	
	component clock_divider_s6 port(
		clk: in std_logic;
		d25: out std_logic;
		d28: out std_logic
	);
	end component;
	
begin

	ibufgds0: IBUFGDS port map(
		i => sysclk_p,
		ib => sysclk_n,
		o => sysclk
	);

	bufg_125: BUFG port map(
		i => clk_125_i,
		o => clk_125_b
	);
	
	clko_125 <= clk_125_b;
	
	bufg_ipb: BUFG port map(
		i => clk_ipb_i,
		o => clk_ipb_b
	);
	
	clko_ipb <= clk_ipb_b;

	dcm0: DCM_CLKGEN
		generic map(
			CLKIN_PERIOD => 5.0,
			CLKFX_MULTIPLY => 5,
			CLKFX_DIVIDE => 8,
			CLKFXDV_DIVIDE => 4
		)
		port map(
			clkin => sysclk,
			clkfx => clk_125_i,
			clkfxdv => clk_ipb_i,
			locked => dcm_locked,
			rst => '0'
		);
		
	clkdiv: clock_divider_s6 port map(
		clk => sysclk,
		d25 => d25,
		d28 => onehz
	);
	
	dcm1: DCM_SP
   generic map (
     CLKIN_DIVIDE_BY_2 => FALSE,            -- CLKIN divide by two (TRUE/FALSE)
     CLKIN_PERIOD => 5.0,                  -- Input clock period specified in nS
     STARTUP_WAIT => TRUE                  -- Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
   )
   port map (
      --CLK2X => clko_fast,       -- 1-bit output: 2X clock frequency clock output
		CLK0 => clko_fast,       -- 1-bit output: 1X clock frequency clock output
      CLKIN => sysclk       -- 1-bit input: Clock input
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
	
	locked <= dcm_locked;

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
