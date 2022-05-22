library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
-- 12 000 000 / 2 = 6 000 000
--
entity hb_led_e is

  generic (
  hb_halfperiod_g : integer := 6000000
  );
  
  port(
    cp_i : in std_logic;
    rb_i : in std_logic;
    d_o  : out std_logic);
	
end entity;
