architecture top_lvlV2_a of top_lvlV2_e is

  signal en_s         : std_logic;
  signal sndak_s      : std_logic;
  
begin

  snd: sndV2_e
  port map(
    cp_i  =>  cp_i,
    rb_i  =>  rb_i,
    en_i  =>  en_s,
    snd_o =>  snd_o,  
    act_o =>  sndak_s);
    
  timer: timerV2_e
  port map(
    cp_i  =>  cp_i,
    rb_i  =>  rb_i,
    t0_i  =>  t0_i,
    t1_i  =>  t1_i,
    st_i  =>  st_i,
    en_o  =>  en_s,
    sum_o =>  open);
    
  led: main_ledV2_e
  port map(
    cp_i  => cp_i,
    rb_i  => rb_i,
    m0_i  => m0_i,
    m1_i  => m1_i,
    t0_i  => t0_i,
    t1_i  => t1_i,
    snd_i => sndak_s,
    tx_i  => open,
    ld1_o => ld1_o,
    ld2_o => ld2_o,
    ld3_o => ld3_o,
    ld4_o => ld4_o,
    ld5_o => ld5_o,
    ld6_o => ld6_o,
    ld7_o => ld7_o,
    ld8_o => ld8_o);
    
end architecture;
