architecture top_lvlV2_a of top_lvlV2_e is
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
    sum_o =>  sumtim_s);
    
  led: main_ledV2_e
  port map(
    cp_i  => cp_i,
    rb_i  => rb_i,
    m0_i  => m0_i,
    m1_i  => m1_i,
    t0_i  => t0_i,
    t1_i  => t1_i,
    snd_i => sndak_s,
    tx_i  => tx_s,
    ld1_o => ld1_o,
    ld2_o => ld2_o,
    ld3_o => ld3_o,
    ld4_o => ld4_o,
    ld5_o => ld5_o,
    ld6_o => ld6_o,
    ld7_o => ld7_o,
    ld8_o => ld8_o);
    
  uart_rx: uartV2_rx_e
    port map(
      cp_i      =>  cp_i,
      rb_i      =>  rb_i,
      rxd_i     =>  rxd_i,
      rx_dv_o   =>  rx_dv_s,
      rx_byte_o =>  rx_byte_s);
      
  uart_tx: uartV2_tx_e
    port map(
      cp_i        =>  cp_i,
      rb_i        =>  rb_i,
      tx_dv_i     =>  tx_dv_s,
      tx_byte_i   =>  tx_byte_s,
      tx_active_o =>  tx_s,
      tx_serial_o =>  txd_o,
      tx_done_o   =>  tx_done_s);
  
  ascii_decode: ASCII_decode_e
    port map(
      cp_i        => cp_i,
      rb_i        => rb_i,
      rx_dv_i     => rx_dv_s,
      rx_byte_i   => rx_byte_s,
      sum_i       => sumtim_s,
      en_sum_i    => en_s,
      sec_o       => sec_s,
      en_sec_o    => en_sec_s);
      
  ascii_encode: ASCII_encode_e
    port map(
      cp_i        =>  cp_i,
      rb_i        =>  rb_i,
      en_sec_i    =>  en_sec_s,
      tx_done_i   =>  tx_done_s,
      sec_i       =>  sec_s,
      tx_dv_o     =>  tx_dv_s,
      tx_byte_o   =>  tx_byte_s);
    
end architecture;
