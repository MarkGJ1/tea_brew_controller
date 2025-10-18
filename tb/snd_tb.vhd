library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity sndV2_tb_e is
end sndV2_tb_e;

architecture sndV2_tb_a of sndV2_tb_e is

  component sndV2_e is

  generic(second_g  : integer := 12000000;
          freq_g    : integer := 12000;
          len_g     : integer := 1);
  port(
    cp_i  : in  std_logic;
    rb_i  : in  std_logic;
    en_i  : in  std_logic;
    snd_o : out std_logic;
    act_o : out std_logic);

  end component;
   
   constant clk_freq_c   : integer := 12000000;
   constant clk_period_c : time    := 1000 ms/clk_freq_c;
   
   signal cp_s      : std_logic := '0';
   signal rb_s      : std_logic := '0';
   signal en_s      : std_logic := '0';
   signal snd_s     : std_logic;
   signal act_s     : std_logic;
   
begin

  snd: sndV2_e 
  port map(
    cp_i  =>  cp_s,
    rb_i  =>  rb_s,
    en_i  =>  en_s,
    snd_o =>  snd_s,
    act_o =>  act_s);
    
  cp_s <= not cp_s after clk_period_c/2;
  
  process is
  begin
  
  wait for 300 ms;
  rb_s  <=  '1';
  
  wait for 20 ms;
  en_s  <=  '1';
  
  wait for 2002 ms;
  assert (snd_s = '0') report "Wrong output, snd still on" severity warning;
  
  wait;
  
  end process;
end architecture;
   

