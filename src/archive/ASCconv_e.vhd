library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCconv_e is

  port(
    cp_i      : in  std_logic;
    rb_i      : in  std_logic;
    tx_done_i : in  std_logic;
    rx_dv_i   : in  std_logic;
    ensum_i   : in  std_logic;
    sum_i     : in  integer;
    rx_byte_i : in  std_logic_vector(7 downto 0);
    tx_dv_o   : out std_logic;
    seconds_o : out integer;
    tx_byte_o : out std_logic_vector(7 downto 0));

end entity;
