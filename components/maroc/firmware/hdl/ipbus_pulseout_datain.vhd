--@file ipbus_pulseout_datain
--
-- @brief
-- When written to produces a single cycle pulse on one or more bits, as
-- dictated by q_out.
-- When read from returns the value of d_in
--
--
-- David Cussans, May 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.all;

entity ipbus_pulseout_datain is
  generic(g_BUSWIDTH : natural := 32);
  port(
    clk: in STD_LOGIC;
    ipbus_in: in ipb_wbus;
    ipbus_out: out ipb_rbus;
    q_out: out STD_LOGIC_VECTOR(g_BUSWIDTH-1 downto 0);
    d_in: in STD_LOGIC_VECTOR(g_BUSWIDTH-1 downto 0)
    );
	
end ipbus_pulseout_datain;

architecture rtl of ipbus_pulseout_datain is

  signal reg: std_logic_vector(g_BUSWIDTH-1 downto 0);
  signal ack: std_logic;
  signal s_datain : std_logic_vector(d_in'range) := (others => '0');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      reg <= ( others => '0');
      if ipbus_in.ipb_strobe='1' and ipbus_in.ipb_write='1' then
        reg <= ipbus_in.ipb_wdata;      -- register is set high for one cycle
                                        -- then returns low.
      end if;

      -- Register input data
      s_datain <= d_in;
      ipbus_out.ipb_rdata <= s_datain;
      
      ack <= ipbus_in.ipb_strobe and not ack;
      
    end if;
  end process;
	
  ipbus_out.ipb_ack <= ack;
  ipbus_out.ipb_err <= '0';

  q_out <= reg;
  
end rtl;
