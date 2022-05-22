library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timerV2_e is

  generic(second_g : integer := 12000000);
  port(
    cp_i : in  std_logic;
    rb_i : in  std_logic;
    st_i : in  std_logic;
    t0_i : in  std_logic;
    t1_i : in  std_logic;
    en_o : out std_logic;
    sum_o: out integer);
    
end timerV2_e;
