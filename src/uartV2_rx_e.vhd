library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartV2_rx_e is

  generic(baud_g  : integer := 1250);
  port(
    cp_i      : in  std_logic;
    rb_i      : in  std_logic;
    rxd_i     : in  std_logic;
    rx_dv_o   : out  std_logic;
    rx_byte_o : out  std_logic_vector(7 downto 0));

end entity;
