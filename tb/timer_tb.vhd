library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity timerV2_tb_e is
end timerV2_tb_e;

architecture timerV2_tb_a of timerV2_tb_e is

  component timerV2_e is

  generic(second_g : integer := 12000000);

  port(cp_i : in  std_logic;
       rb_i : in  std_logic;
       st_i : in  std_logic;
       t0_i : in  std_logic;
       t1_i : in  std_logic;
       en_o : out std_logic;
       sum_o: out integer);

  end component;
   
   constant clk_freq_c   : integer := 12000000;
   constant clk_period_c : time    := 1000 ms/clk_freq_c;
   
   signal cp_s      : std_logic := '0';
   signal rb_s      : std_logic := '0';
   signal t0_s      : std_logic := '1';
   signal t1_s      : std_logic := '0';
   signal st_s      : std_logic := '0';
   signal en_s      : std_logic;
   signal sum_s     : integer;
   
begin

  timer: timerV2_e 
  port map(
    cp_i  =>  cp_s,
    rb_i  =>  rb_s,
    t0_i  =>  t0_s,
    t1_i  =>  t1_s,
    st_i  =>  st_s,
    en_o  =>  en_s,
    sum_o =>  sum_s);
    
  cp_s <= not cp_s after clk_period_c/2;
  
  process is
  begin
  
  wait for 300 ms;
  rb_s  <=  '1';
  
  wait for 20 ms;
  st_s  <=  '1';
  
  wait for 2000 ms;
  assert(sum_s = 120) report "Wrong sum output" severity note;
  
  wait for 3000 ms;
  assert(en_s = '1') report "Wrong enable output" severity note;
  
  wait;
  
  end process;
end architecture;
   

