library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCII_decode_e is
  
  port(
    cp_i      : in  std_logic;
    rb_i      : in  std_logic;
    rx_dv_i   : in  std_logic;
    rx_byte_i : in  std_logic_vector(7 downto 0);
    sum_i     : in  integer;
    en_sum_i  : in  std_logic;
    sec_o     : out integer;
    en_sec_o  : out std_logic);

end entity;
