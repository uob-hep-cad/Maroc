-- Version register, returns a fixed value
--
-- To be replaced by a more coherent versioning mechanism later
--
-- Dave Newbold, August 2011

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ipbus.all;

entity ipbus_ver is
	port(
		ipbus_in: in ipb_wbus;
		ipbus_out: out ipb_rbus
	);
	
end ipbus_ver;

  
architecture rtl of ipbus_ver is

  attribute mark_debug : string;
  attribute mark_debug of ipbus_in,ipbus_out : signal is "true";
  
  attribute keep: string;
  attribute keep of ipbus_in,ipbus_out: signal is "true";
 
 
begin

  ipbus_out.ipb_rdata <= X"a621" & X"1008"; -- Lower 16b are ipbus firmware build ID (temporary arrangement).
  ipbus_out.ipb_ack <= ipbus_in.ipb_strobe;
  ipbus_out.ipb_err <= '0';

end rtl;



