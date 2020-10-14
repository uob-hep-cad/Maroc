--! @file
--! @brief A Dual-Port RAM with configurable width and number of entries. No Xilinx specific entities.
--! @author David Cussans
--! Institute: University of Bristol
--! @date 26 April 2011
--
--! Modifications:
--! 10/May/13 - re-write to have an IPBus output port.
library ieee;
use ieee.std_logic_1164.all;

use ieee.numeric_std.all;

use work.ipbus.all;

entity ipbusDPRAM is
  generic (
    DATA_WIDTH        : integer := 32;  --! Width of word
    RAM_ADDRESS_WIDTH : integer := 10   --! size of RAM = 2^ram_address_width
    );                                  -- default is 512 locations deep
  port (
    clk       : in std_logic;           --! rising edge active
    -- write port
    wren_a    : in std_logic;           --! write enable, active high
    address_a : in std_logic_vector(ram_address_width-1 downto 0);  --! write (port-A) address
    data_a    : in std_logic_vector(DATA_WIDTH-1 downto 0);  --! data input -port A

    -- IPBus for read-port
    ipbus_clk : in std_logic;
    ipbus_i  : in  ipb_wbus;
    ipbus_o : out ipb_rbus

    ); 
end ipbusDPRAM;

architecture rtl of ipbusDPRAM is

  type   ram_type is array (2**ram_address_width - 1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);
  signal RAM                            : ram_type;
  signal s_ack                          : std_logic := '0';  --! IPBus ack
  signal s_readAddress , s_writeAddress : integer   := 0;
  
begin

  s_readAddress  <= to_integer(unsigned(ipbus_i.ipb_addr(ram_address_width-1 downto 0)));
  s_writeAddress <= TO_INTEGER(unsigned(address_a));

  --! Write process
  process (clk)
  begin
    if rising_edge(clk) then

      -- If write enable high then write into RAM
      if (wren_a = '1') then
        RAM(s_writeAddress) <= data_a;
      end if;

    end if;
  end process;

  --! Read process
  process (ipbus_clk)
  begin
    if rising_edge(ipbus_clk) then  
      ipbus_o.ipb_rdata <= RAM(s_readAddress);
      s_ack             <= ipbus_i.ipb_strobe and not s_ack;
end if;
end process;


  ipbus_o.ipb_ack <= s_ack;
  ipbus_o.ipb_err <= '0';
  
end rtl;
