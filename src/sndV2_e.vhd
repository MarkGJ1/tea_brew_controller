library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sndV2_e is

  generic(second_g  : integer := 12000000;
          freq_g    : integer := 12000;
          len_g     : integer := 2);
  port(
    cp_i  : in  std_logic;
    rb_i  : in  std_logic;
    en_i  : in  std_logic;
    snd_o : out std_logic;
    act_o : out std_logic);

end entity;

    
