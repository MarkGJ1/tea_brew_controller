library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartV2_rx_e is

  generic(baud_g  : integer := 1250);
  port(
    cp_i      : in  std_logic;
    rb_i      : in  std_logic;
    rxd_i     : in  std_logic;
    rx_dv_o   : out  std_logic;
    rx_byte_o : out  std_logic_vector(7 downto 0));

end entity;

architecture uartV2_rx_a of uartV2_rx_e is

  type rx_fsm_t is (idle_st, bitST_st, bit1_st, bit2_st, bit3_st, bit4_st,
  bit5_st, bit6_st, bit7_st, bit8_st, bitD_st, bitD2_st, clean_st,
  chk_st, baudrst_st);

  signal rxd_s, rxd2_s, rx_st_s: std_logic;
  signal rx_fsm_s, rx_fsmnx_s  : rx_fsm_t;
  signal baud_s : integer range 0 to baud_g-1;
  signal nx_s    : std_logic;
  signal rx_dv_s : std_logic;
  signal read_s  : std_logic;
  signal rx_byte_s : std_logic_vector(7 downto 0);
    
begin

rx_byte_o <= rx_byte_s;
rx_dv_o   <= rx_dv_s;


rx_takt_p: process(cp_i, rb_i, rx_st_s)
begin

  if rb_i <= '0' then
    rx_fsm_s <= idle_st;
  elsif rising_edge(cp_i) then
    rx_fsm_s <= rx_fsmnx_s;
    
    rxd_s  <= rxd_i;
    rxd2_s <= rxd_s;
   
    if rx_st_s = '1' then
      
      if baud_s = (baud_g/2)-1 then
        read_s <= '1';
      else
        read_s <= '0';
      end if;
      
      if baud_s < baud_g-1 then
        baud_s <= baud_s + 1;
        nx_s   <= '0';
      else
        baud_s <= 0;
        nx_s   <= '1';
      end if;
    else
      read_s <= '0';
      baud_s <= 0;
      nx_s   <= '0';
    end if;
    
  end if;
  
end process;

rx_fsmf_p: process(rx_fsm_s, nx_s, rxd2_s, read_s)
begin
  rx_fsmnx_s <= rx_fsm_s;
  
    case rx_fsm_s is
      
      when idle_st =>
        if rxd2_s = '0' then
          rx_fsmnx_s <= chk_st;
        else
          rx_fsmnx_s <= idle_st;
        end if;
      
      when chk_st   =>
        if read_s = '1' then
          if rxd2_s = '0' then
            rx_fsmnx_s <= baudrst_st;
          else
            rx_fsmnx_s <= idle_st;
          end if;
        else
          rx_fsmnx_s <= chk_st;
        end if;
      
      when baudrst_st =>
        rx_fsmnx_s <= bitST_st;
        
      when bitST_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit1_st;
        else
          rx_fsmnx_s <= bitST_st;
        end if;
      
      when bit1_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit2_st;
        else
          rx_fsmnx_s <= bit1_st;
        end if;
      when bit2_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit3_st;
        else
          rx_fsmnx_s <= bit2_st;
        end if;
      when bit3_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit4_st;
        else
          rx_fsmnx_s <= bit3_st;
        end if;
      when bit4_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit5_st;
        else
          rx_fsmnx_s <= bit4_st;
        end if;
      when bit5_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit6_st;
        else
          rx_fsmnx_s <= bit5_st;
        end if;
      when bit6_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit7_st;
        else
          rx_fsmnx_s <= bit6_st;
        end if;
      when bit7_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bit8_st;
        else
          rx_fsmnx_s <= bit7_st;
        end if;
      when bit8_st =>
        if nx_s = '1' then
          rx_fsmnx_s <= bitD_st;
        else
          rx_fsmnx_s <= bit8_st;
        end if;
      
      when bitD_st =>
        
        if rxd2_s = '1' then
          rx_fsmnx_s <= bitD_st;
        else
          rx_fsmnx_s <= idle_st;
        end if;
        
        if nx_s = '1' then
          rx_fsmnx_s <= bitD2_st;
        else
          rx_fsmnx_s <= bitD_st;
        end if;
        
      when bitD2_st =>
        if rxd2_s = '1' then
          rx_fsmnx_s <= clean_st;
        else
          rx_fsmnx_s <= idle_st;
        end if;
      
      when clean_st =>
        rx_fsmnx_s <= idle_st;
      
      when others =>
        rx_fsmnx_s <= idle_st;
      
    end case;
end process;
        
rx_sample_p:process(rx_fsm_s)
begin
  
  case rx_fsm_s is
    
    when idle_st =>
      rx_byte_s <= (others => '0');
      rx_st_s   <= '0';
      rx_dv_s   <= '0';
        
    when chk_st =>
      rx_byte_s <= (others => '0');
      rx_st_s   <= '1';
      rx_dv_s   <= '0';
      
    when baudrst_st =>
      rx_byte_s <= (others => '0');
      rx_st_s   <= '0';
      rx_dv_s   <= '0';
    
    when bitST_st =>
      rx_byte_s <= (others => '0');
      rx_st_s   <= '1';
      rx_dv_s   <= '0';
    
    when bit1_st =>
      rx_byte_s(0) <= rxd2_s;
      rx_st_s   <= '1';
      rx_dv_s   <= '0';  

    when bit2_st =>
      rx_byte_s(1) <= rxd2_s;
      rx_st_s   <= '1';
      rx_dv_s   <= '0'; 
         
    when bit3_st =>
      rx_byte_s(2) <= rxd2_s;
      rx_st_s   <= '1';
      rx_dv_s   <= '0';  

    when bit4_st =>
      rx_byte_s(3) <= rxd2_s;  
      rx_st_s   <= '1';
      rx_dv_s   <= '0';

    when bit5_st =>
      rx_byte_s(4) <= rxd2_s;  
      rx_st_s   <= '1';
      rx_dv_s   <= '0';

    when bit6_st =>
      rx_byte_s(5) <= rxd2_s;
      rx_st_s   <= '1';
      rx_dv_s   <= '0';  

    when bit7_st =>
      rx_byte_s(6) <= rxd2_s;
      rx_st_s   <= '1';
      rx_dv_s   <= '0';  

    when bit8_st =>
      rx_byte_s(7) <= rxd2_s;
      rx_st_s   <= '1';  
      rx_dv_s   <= '0';

    when bitD_st =>
      rx_st_s <= '1';
      rx_dv_s <= '0';
    
    when bitD2_st =>
      rx_st_s <= '1';
      rx_dv_s <= '0';
    
    when clean_st =>
      rx_st_s <= '0';
      rx_dv_s <= '1';
      
    when others =>
      rx_byte_s <= (others => '0');
      rx_dv_s <= '0';
      rx_st_s <= '0';
    
  end case;
end process;

end architecture;  
