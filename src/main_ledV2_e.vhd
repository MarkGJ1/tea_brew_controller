library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main_ledV2_e is 

  port(
    cp_i  : in  std_logic;
    rb_i  : in  std_logic;
    m0_i  : in  std_logic;
    m1_i  : in  std_logic;
    t0_i  : in  std_logic;
    t1_i  : in  std_logic;
    snd_i : in  std_logic;
    tx_i  : in  std_logic;
    ld1_o : out std_logic;
    ld2_o : out std_logic;
    ld3_o : out std_logic;
    ld4_o : out std_logic;
    ld5_o : out std_logic;
    ld6_o : out std_logic;
    ld7_o : out std_logic;
    ld8_o : out std_logic);

end entity;

architecture main_ledV2_a of main_ledV2_e is

component hb_led_e is

  generic (hb_halfperiod_g : integer := 6000000);
  port(
  cp_i : in std_logic;
  rb_i : in std_logic;
  d_o  : out std_logic);
  
end component;

begin
  
  ld1_o <= not rb_i;
  
  ld2_comp: hb_led_e
  port map(
  cp_i => cp_i,
  rb_i => rb_i,
  d_o  => ld2_o);
  
  ld3_o <= m0_i;
  ld4_o <= m1_i;
  ld5_o <= t0_i;
  ld6_o <= t1_i;
  ld7_o <= tx_i;
  ld8_o <= snd_i;
  
end architecture;
