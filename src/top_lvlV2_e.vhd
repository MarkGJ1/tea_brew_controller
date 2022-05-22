library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.top_pkg_p.all;

entity top_lvlV2_e is
  
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


end entity;
