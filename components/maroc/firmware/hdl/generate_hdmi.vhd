
library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Xilinx lib for differential output buffers
Library UNISIM;
use UNISIM.vcomponents.all;

use work.fiveMaroc.all;


entity generate_hdmi is
  port (
    clk_i : in std_logic;
    hdmi_input_signals:  in  hdmi_input_signals;
    hdmi_output_signals: out hdmi_output_signals
    );
end generate_hdmi;

architecture rtl of generate_hdmi is

--  signal hdmi0_clk : std_logic;
--  signal hdmi0_data : std_logic_vector(2 downto 0);
--  signal hdmi0_clk : std_logic;
--  signal hdmi0_data : std_logic_vector(2 downto 0);

  signal counter : unsigned(7 downto 0) :=  to_unsigned(0,8);

begin  -- rtl

-- need to buffer all output signals => => => => .


  -----------------------------------------------------------------------------
  -- Connections to HDMI0
  -----------------------------------------------------------------------------
  obufds_hdmi0_clk : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi0_clk_p,
      ob => hdmi_output_signals.hdmi0_clk_n,
      i  => counter(0)
      );

  obufds_hdmi0_data0 : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi0_data_p(0),
      ob => hdmi_output_signals.hdmi0_data_n(0),
      i  => counter(1)
      );

  obufds_hdmi0_data1 : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi0_data_p(1),
      ob => hdmi_output_signals.hdmi0_data_n(1),
      i  => counter(2)
      );

  obufds_hdmi0_data2 : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi0_data_p(2),
      ob => hdmi_output_signals.hdmi0_data_n(2),
      i  => counter(3)
      );


  -----------------------------------------------------------------------------
  -- Connections to HDMI1
  -----------------------------------------------------------------------------
  obufds_hdmi1_clk : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi1_clk_p,
      ob => hdmi_output_signals.hdmi1_clk_n,
      i  => counter(4)
      );

  obufds_hdmi1_data0 : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi1_data_p(0),
      ob => hdmi_output_signals.hdmi1_data_n(0),
      i  => counter(5)
      );

  obufds_hdmi1_data1 : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi1_data_p(1),
      ob => hdmi_output_signals.hdmi1_data_n(1),
      i  => counter(6)
      );

  obufds_hdmi1_data2 : obufds
    generic map (
      iostandard => "DEFAULT")
    port map (
      o  => hdmi_output_signals.hdmi1_data_p(2),
      ob => hdmi_output_signals.hdmi1_data_n(2),
      i  => counter(7)
      );

  -----------------------------------------------------------------------------
  --
  -----------------------------------------------------------------------------

  count: process (clk_i)
  begin  -- process count
    if rising_edge(clk_i) then
      counter <= counter +1 ;      
    end if;
  end process count;

end rtl;
