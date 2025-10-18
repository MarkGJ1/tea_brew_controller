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

architecture hb_a of hb_led_e is

  signal time_s : integer range 0 to hb_halfperiod_g-1;
  signal b_s    : std_logic;

begin
  
  timer: process (cp_i, rb_i)
  begin
  
   if rb_i = '0' then
  
   b_s <= '0';
   time_s <= 0;
  
   elsif rising_edge(cp_i) then
   
    if time_s < (hb_halfperiod_g-1) then 
      time_s <= time_s + 1;
    else
      b_s <= not b_s;
      time_s <= 0;
    end if;

   end if;
  end process;
  
  d_o <= b_s;
  
end hb_a;
