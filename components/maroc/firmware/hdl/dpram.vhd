--! @file
--! @brief A Dual-Port RAM with configurable width and number of entries. No Xilinx specific entities.
--! @author David Cussans
--! Institute: University of Bristol
--! @date 26 April 2011

library ieee;
use ieee.std_logic_1164.all; 

use ieee.numeric_std.all;

entity dpram is
  generic (
    DATA_WIDTH : integer := 32;          --! Width of word
    RAM_ADDRESS_WIDTH  : integer := 10;            --! size of RAM = 2^ram_address_width
    g_USECOREGEN : boolean := True --! Set to True to use COREGEN DPR.
    );         -- default is 512 locations deep
  port (
    clk : in std_logic;                 --! rising edge active
    -- read/write port
    wren_a : in std_logic;                  --! write enable, active high
    address_a : in std_logic_vector(ram_address_width-1 downto 0);  --! write (port-A) address
    data_a : in std_logic_vector(DATA_WIDTH-1 downto 0);  --! data input -port A
    q_a : out std_logic_vector(DATA_WIDTH-1 downto 0);  --! data output - port A
    -- secondary port
    address_b : in std_logic_vector(ram_address_width-1 downto 0);  --! read (port-B) address
    q_b : out std_logic_vector(DATA_WIDTH-1 downto 0) --! Data output - port B
    ); 
end dpram; 

architecture syn of dpram is

  type ram_type is array (2**ram_address_width - 1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0); 
  signal RAM : ram_type;
  signal read_dpra : std_logic_vector(ram_address_width-1 downto 0);
  signal read_dprb : std_logic_vector(ram_address_width-1 downto 0);

  signal s_wea : std_logic_vector(0 downto 0) := "0";  -- ! write enable for coregen DPR
  
begin

  -- Use VHDL array to implement a dual-port-ram
  gen_dpr: if g_USECOREGEN=False generate

    begin
      
      process (clk)
      begin 
        if (clk'event and clk = '1') then
          if (wren_a = '1') then
            RAM(TO_INTEGER(unsigned(address_a))) <= data_a;
          end if;
		      
          q_b <= RAM(to_integer(unsigned(read_dprb)));
          q_a <= RAM(to_integer(unsigned(read_dpra)));
  
        end if;
      end process;

      read_dprb <= address_b;
      read_dpra <= address_a;
    end generate gen_dpr;

  -- Use a DPR produced by Coregen
  gen_coregendpr: if g_USECOREGEN=True generate
    begin

      assert DATA_WIDTH=32 report "Data width must be 32 for Coregen DPR" severity failure;
      assert RAM_ADDRESS_WIDTH=9 report "Address width must be 9 for Coregen DPR" severity failure;

      -- report "Using COREGEN DPR" severity note;
      
      s_wea(0) <= wren_a; --! Xilinx coregen DPR write enable actually a bus of
                          --! width 1.
      
      cmp_coregendDPR : entity work.dpram_coregen
        PORT MAP (
          clka  => clk,
          wea   => s_wea,
          addra => address_a,
          dina  => data_a,
          clkb  => clk,
          addrb => address_b,
          doutb => q_b
          );
    
  end generate gen_coregendpr;

  
end syn;
