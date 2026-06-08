library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity btnMode_e is
  
  port(
    rb_i  : in  std_logic;
    ch_i  : in  std_logic;
    t0_o  : out std_logic;
    t1_o  : out std_logic);

end entity;
