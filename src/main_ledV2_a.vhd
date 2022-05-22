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
