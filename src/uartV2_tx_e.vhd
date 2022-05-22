library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartV2_tx_e is

  generic(baud_g  : integer := 1250);
  port(
    cp_i        : in  std_logic;
    rb_i        : in  std_logic;
    tx_dv_i     : in  std_logic;
    tx_byte_i   : in  std_logic_vector(7 downto 0);
    tx_active_o : out std_logic;
    tx_serial_o : out std_logic;
    tx_done_o   : out std_logic);
end entity;
