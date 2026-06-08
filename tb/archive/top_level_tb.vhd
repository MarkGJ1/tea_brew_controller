library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.top_pkg_p.all;

entity top_lvlV2_tb_e is
end top_lvlV2_tb_e;

architecture top_lvlV2_tb_a of top_lvlV2_tb_e is

  constant clk_freq_c   : integer := 12000000;
  constant clk_period_c : time    := 1000 ms/clk_freq_c;
  
  component top_lvlV2_e is
  
    port(
    cp_i  : in std_logic;
    rb_i  : in std_logic;
    m0_i  : in std_logic;
    m1_i  : in std_logic;
    t0_i  : in std_logic;
    t1_i  : in std_logic;
    st_i  : in std_logic;
    rxd_i : in std_logic;
    
    ld1_o : out std_logic;
    ld2_o : out std_logic;
    ld3_o : out std_logic;
    ld4_o : out std_logic;
    ld5_o : out std_logic;
    ld6_o : out std_logic;
    ld7_o : out std_logic;
    ld8_o : out std_logic;
    snd_o : out std_logic;
    txd_o : out std_logic);
  
  end component;
  
  signal cp_s  : std_logic  := '0';
  signal rb_s  : std_logic  := '0';
  signal t0_s  : std_logic  := '1';
  signal t1_s  : std_logic  := '0';
  signal m0_s  : std_logic  := '0';
  signal m1_s  : std_logic  := '0';
  signal st_s  : std_logic  := '0';
  signal rxd_s : std_logic  := '0';
  
  signal ld1_s  : std_logic;
  signal ld2_s  : std_logic;
  signal ld3_s  : std_logic;
  signal ld4_s  : std_logic;
  signal ld5_s  : std_logic;
  signal ld6_s  : std_logic;
  signal ld7_s  : std_logic;
  signal ld8_s  : std_logic;
  signal snd_s  : std_logic;
  signal txd_s  : std_logic;

begin

  cp_s <= not cp_s after clk_period_c/2;
  
  top_lvl: top_lvlV2_e
  port map(
    cp_i  =>  cp_s,
    rb_i  =>  rb_s,
    t0_i  =>  t0_s,
    t1_i  =>  t1_s,
    m0_i  =>  m0_s,
    m1_i  =>  m1_s,
    st_i  =>  st_s,
    rxd_i =>  rxd_s,
    ld1_o =>  ld1_s,
    ld2_o =>  ld2_s,
    ld3_o =>  ld3_s,
    ld4_o =>  ld4_s,
    ld5_o =>  ld5_s,
    ld6_o =>  ld6_s,
    ld7_o =>  open,
    ld8_o =>  ld8_s,
    snd_o =>  snd_s,
    txd_o =>  open);

  process is
  begin
    
    wait for 50 ms;
    assert(ld1_s = '1') report "Wrong led reset output" severity warning;

    
    wait for 200 ms;
    rb_s <= '1';
    assert(ld1_s = '0') report "Wrong led reset output" severity warning;
    
    wait until rising_edge(cp_s);
    st_s <= '1';
    
    wait;
    
  end process;
  
end architecture;

