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

architecture timerV2_a of timerV2_e is

  constant min2_c : integer := 120;
  constant min3_c : integer := 180;
  constant min4_c : integer := 240;
  constant min5_c : integer := 300;

  signal second_s   : integer range 0 to second_g-1;  
  signal min_s      : integer range 0 to min5_c-1;
  signal modmin_s   : integer;
  signal mode2_s, mode3_s : std_logic;
  signal mode4_s, mode5_s : std_logic;
  signal en_s : std_logic;

begin

  mode2_s <= not t0_i and not t1_i;
  mode3_s <=     t0_i and not t1_i;
  mode4_s <= not t0_i and     t1_i;
  mode5_s <=     t0_i and     t1_i;

  tv2_takt_p: process(rb_i, cp_i)
  begin
    if rb_i = '0' then
      en_s     <= '0';
    elsif rising_edge(cp_i) then
      
      if mode2_s = '1' then
        modmin_s <= min2_c;
      elsif mode3_s = '1' then
        modmin_s <= min3_c;
      elsif mode4_s = '1' then
        modmin_s <= min4_c;
      elsif mode5_s = '1' then
        modmin_s <= min5_c;
      end if;
      
      if st_i = '1' then
        if second_s < second_g-1 then
          second_s <= second_s + 1;
        else
          second_s <= 0;
        
          if min_s < modmin_s-1 then
            min_s <= min_s + 1;
          else
            min_s <= 0;
            en_s <= '1';
          end if;
          
        end if;
      else
        en_s      <= '0';
        second_s  <= 0;
        min_s     <= 0;
      end if;
    end if;
  end process;
  
  en_o  <= en_s;
  sum_o <= modmin_s;
  
end timerV2_a;
