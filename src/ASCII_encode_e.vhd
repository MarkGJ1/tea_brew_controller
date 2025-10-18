library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCII_encode_e is
  
  port(
    cp_i      : in  std_logic;
    rb_i      : in  std_logic;
    en_sec_i  : in  std_logic;
    tx_done_i : in  std_logic;
    sec_i     : in  integer;
    tx_dv_o   : out std_logic;
    tx_byte_o : out std_logic_vector(7 downto 0));
    
end entity;

architecture a2 of ASCII_encode_e is

  constant b0_c     : std_logic_vector(7 downto 0) := X"30";
  constant b1_c     : std_logic_vector(7 downto 0) := X"31";
  constant b2_c     : std_logic_vector(7 downto 0) := X"32";
  constant b3_c     : std_logic_vector(7 downto 0) := X"33";
  constant b4_c     : std_logic_vector(7 downto 0) := X"34";
  constant b5_c     : std_logic_vector(7 downto 0) := X"35";
  constant b6_c     : std_logic_vector(7 downto 0) := X"36";
  constant b7_c     : std_logic_vector(7 downto 0) := X"37";
  constant b8_c     : std_logic_vector(7 downto 0) := X"38";
  constant b9_c     : std_logic_vector(7 downto 0) := X"39";
  constant bSemi_c  : std_logic_vector(7 downto 0) := X"3A";
  constant bE_c     : std_logic_vector(7 downto 0) := X"45";
  constant bCR_c    : std_logic_vector(7 downto 0) := X"0D";
  constant bLF_c    : std_logic_vector(7 downto 0) := X"0A";
  

  type sec_fsm_t is (idle_st, sectake_st);
  
  signal sec_fsm_s, sec_fsmnx_s : sec_fsm_t;
  
  type div_fsm_t is (idle_st, div1_st, div2_st, div3_st, div4_st,
  div5_st, div6_st, clr1_st, clr2_st, clr3_st, clr4_st, clr5_st, clr6_st);
  
  signal div_fsm_s, div_fsmnx_s : div_fsm_t;
  
  type byte_fsm_t is (idle_st, hh1_st, hh2_st, min1_st, min2_st, s1_st,
  s2_st, e_st, cr_st, lf_st, semi1_st, semi2_st, clr1_st, clr2_st, 
  clr3_st, clr4_st, clr5_st, clr6_st, clr7_st, clr8_st, clr9_st,
  clr10_st, clr11_st);
  
  signal byte_fsm_s, byte_fsmnx_s : byte_fsm_t;
  
  type tx_fsm_t is (idle_st, tx1_up_st, tx2_up_st, tx3_up_st, tx4_up_st,
  tx5_up_st, tx6_up_st, tx7_up_st, tx8_up_st, tx9_up_st, tx10_up_st,
  tx11_up_st, tx1_down_st, tx2_down_st, tx3_down_st, tx4_down_st,
  tx5_down_st, tx6_down_st, tx7_down_st, tx8_down_st, tx9_down_st,
  tx10_down_st, tx11_down_st);
  
  signal tx_fsm_s, tx_fsmnx_s : tx_fsm_t;
  
  
  signal out_byte_s : std_logic_vector(7 downto 0);
  signal entx_s     : std_logic;
  signal seconds_s  : integer;
  signal ens_s      : std_logic;
  signal div_s      : integer;
  signal end_s      : std_logic;
  signal tx_dv_s    : std_logic;
  signal tx_done_s  : std_logic;
  signal tx_last_s  : std_logic;
  signal endiv_s    : std_logic;
  
  procedure ASCrev (signal byteRev  : out std_logic_vector(7 downto 0);
                    signal intRev   : in  integer) is
  begin
    case intRev is
      when 0      => byteRev <= b0_c;
      when 1      => byteRev <= b1_c;
      when 2      => byteRev <= b2_c;
      when 3      => byteRev <= b3_c;
      when 4      => byteRev <= b4_c;
      when 5      => byteRev <= b5_c;
      when 6      => byteRev <= b6_c;
      when 7      => byteRev <= b7_c;
      when 8      => byteRev <= b8_c;
      when 9      => byteRev <= b9_c;
      when others => byteRev <= b0_c;
    end case;
  end procedure;

begin

  tx_dv_o   <= tx_dv_s;
  tx_byte_o <= out_byte_s;

  encode_takt_p: process(rb_i, cp_i)
  begin
    if rb_i = '0' then
      sec_fsm_s  <= idle_st;
      tx_fsm_s   <= idle_st;
      div_fsm_s  <= idle_st;
      byte_fsm_s <= idle_st;
    elsif rising_edge(cp_i) then
      sec_fsm_s  <= sec_fsmnx_s;
      div_fsm_s  <= div_fsmnx_s;
      byte_fsm_s <= byte_fsmnx_s;
      tx_fsm_s   <= tx_fsmnx_s;
    end if;
  end process;
  
  sec_state_p: process(sec_fsm_s, en_sec_i, tx_last_s)
  begin
    sec_fsmnx_s <= sec_fsm_s;
      case sec_fsm_s is
        when idle_st    =>
          if en_sec_i = '1' then
            sec_fsmnx_s <= sectake_st;
          else
            sec_fsmnx_s <= idle_st;
          end if;
        when sectake_st =>
          if tx_last_s = '1' then
            sec_fsmnx_s <= idle_st;
          else
            sec_fsmnx_s <= sectake_st;
          end if;
        when others     =>
          sec_fsmnx_s <= idle_st;
      end case;
  end process;
  
  sec_out_p:  process(sec_fsm_s)
  begin
    case sec_fsm_s is
      when idle_st    =>
        seconds_s <= 0;
        ens_s     <= '0';
      when sectake_st =>
        seconds_s <= sec_i;
        ens_s     <= '1';
      when others     =>
        seconds_s <= 0;
        ens_s     <= '0';
    end case;
  end process;
  
  div_state_p: process(div_fsm_s, ens_s, tx_done_i, endiv_s, tx_last_s)
  begin
    div_fsmnx_s <= div_fsm_s;
      case div_fsm_s is
        when idle_st =>
          if ens_s = '1' then
            div_fsmnx_s <= div1_st;
          else
            div_fsmnx_s <= idle_st;
          end if;
        when div1_st =>
          div_fsmnx_s <= clr1_st;
        when clr1_st =>
          if tx_done_i = '1' then
            div_fsmnx_s <= div2_st;
          else
            div_fsmnx_s <= clr1_st;
          end if;
        when div2_st =>
          div_fsmnx_s <= clr2_st;
        when clr2_st =>
          if tx_done_i = '1' and endiv_s = '1' then
            div_fsmnx_s <= div3_st;
          else
            div_fsmnx_s <= clr2_st;
          end if;
        when div3_st =>
          div_fsmnx_s <= clr3_st;
        when clr3_st =>
          if tx_done_i = '1' then
            div_fsmnx_s <= div4_st;
          else
            div_fsmnx_s <= clr3_st;
          end if;
        when div4_st =>
          div_fsmnx_s <= clr4_st;
        when clr4_st =>
          if tx_done_i = '1' and endiv_s = '1' then
            div_fsmnx_s <= div5_st;
          else
            div_fsmnx_s <= clr4_st;
          end if;
        when div5_st =>
          div_fsmnx_s <= clr5_st;
        when clr5_st =>
          if tx_done_i = '1' then
            div_fsmnx_s <= div6_st;
          else
            div_fsmnx_s <= clr5_st;
          end if;
        when div6_st =>
          div_fsmnx_s <= clr6_st;
        when clr6_st =>
          if tx_last_s = '1' then
            div_fsmnx_s <= idle_st;
          else
            div_fsmnx_s <= clr6_st;
          end if;
        when others  =>
          div_fsmnx_s <= idle_st;
      end case;
  end process;
  
  div_out_p:  process(div_fsm_s)
  begin
      case div_fsm_s is
        when idle_st => end_s <= '0'; div_s <= 0;
        when div1_st => end_s <= '1'; div_s <= seconds_s / 36000;
        when clr1_st => end_s <= '0';
        when div2_st => end_s <= '1'; div_s <= (seconds_s / 3600) mod 10;
        when clr2_st => end_s <= '0';
        when div3_st => end_s <= '1'; div_s <= (seconds_s / 600) mod 6;
        when clr3_st => end_s <= '0';
        when div4_st => end_s <= '1'; div_s <= (seconds_s / 60) mod 10;
        when clr4_st => end_s <= '0';
        when div5_st => end_s <= '1'; div_s <= (seconds_s / 10) mod 6;
        when clr5_st => end_s <= '0';
        when div6_st => end_s <= '1'; div_s <= seconds_s mod 10;
        when clr6_st => end_s <= '0';
        when others  => end_s <= '0'; div_s <= 0;
      end case;
  end process;
  
  byte_state_p: process(byte_fsm_s, end_s, tx_done_i, tx_last_s)
  begin
    byte_fsmnx_s <= byte_fsm_s;
      case byte_fsm_s is
        when idle_st  =>
          if end_s = '1' then
            byte_fsmnx_s <= hh1_st;
          else
            byte_fsmnx_s <= idle_st;
          end if;
        when hh1_st   =>
          byte_fsmnx_s <= clr1_st;
        when clr1_st  =>
          if end_s = '1' then
            byte_fsmnx_s <= hh2_st;
          else
            byte_fsmnx_s <= clr1_st;
          end if;
        when hh2_st   =>
          byte_fsmnx_s <= clr2_st;
        when clr2_st  =>
          if tx_done_i = '1' then
            byte_fsmnx_s <= semi1_st;
          else
            byte_fsmnx_s <= clr2_st;
          end if;
        when semi1_st =>
          byte_fsmnx_s <= clr3_st;
        when clr3_st  =>
          if end_s = '1' then
            byte_fsmnx_s <= min1_st;
          else
            byte_fsmnx_s <= clr3_st;
          end if;
        when min1_st  =>
          byte_fsmnx_s <= clr4_st;
        when clr4_st  =>
          if end_s = '1' then
            byte_fsmnx_s <= min2_st;
          else
            byte_fsmnx_s <= clr4_st;
          end if;
        when min2_st  =>
          byte_fsmnx_s <= clr5_st;
        when clr5_st  =>
          if tx_done_i = '1' then
            byte_fsmnx_s <= semi2_st;
          else
            byte_fsmnx_s <= clr5_st;
          end if;
        when semi2_st =>
          byte_fsmnx_s <= clr6_st;
        when clr6_st  =>
          if end_s = '1' then
            byte_fsmnx_s <= s1_st;
          else
            byte_fsmnx_s <= clr6_st;
          end if;
        when s1_st    =>
          byte_fsmnx_s <= clr7_st;
        when clr7_st  =>
          if end_s = '1' then
            byte_fsmnx_s <= s2_st;
          else
            byte_fsmnx_s <= clr7_st;
          end if;
        when s2_st    =>
          byte_fsmnx_s <= clr8_st;
        when clr8_st  =>
          if tx_done_i = '1' then
            byte_fsmnx_s <= e_st;
          else
            byte_fsmnx_s <= clr8_st;
          end if;
        when e_st     =>
          byte_fsmnx_s <= clr9_st;
        when clr9_st  =>
          if tx_done_i = '1' then
            byte_fsmnx_s <= cr_st;
          else
            byte_fsmnx_s <= clr9_st;
          end if;
        when cr_st    =>
          byte_fsmnx_s <= clr10_st;
        when clr10_st =>
          if tx_done_i = '1' then
            byte_fsmnx_s <= lf_st;
          else
            byte_fsmnx_s <= clr10_st;
          end if;
        when lf_st    =>
          byte_fsmnx_s <= clr11_st;
        when clr11_st =>
          if tx_last_s = '1' then
            byte_fsmnx_s <= idle_st;
          else
            byte_fsmnx_s <= clr11_st;
          end if;
        when others   =>
          byte_fsmnx_s <= idle_st;
      end case;
  end process;
  
  byte_out_p:   process(byte_fsm_s)
  begin
      case byte_fsm_s is
        when idle_st  => entx_s <= '0'; out_byte_s <= (others => '0');
        when hh1_st   => ASCrev(out_byte_s, div_s); entx_s <= '1';
        when clr1_st  => entx_s <= '0'; 
        when hh2_st   => ASCrev(out_byte_s, div_s); entx_s <= '1';
        when clr2_st  => entx_s <= '0';
        when semi1_st => out_byte_s <= bSemi_c;     entx_s <= '1';
        when clr3_st  => entx_s <= '0';
        when min1_st  => ASCrev(out_byte_s, div_s); entx_s <= '1';
        when clr4_st  => entx_s <= '0';
        when min2_st  => ASCrev(out_byte_s, div_s); entx_s <= '1';
        when clr5_st  => entx_s <= '0';
        when semi2_st => out_byte_s <= bSemi_c;     entx_s <= '1';
        when clr6_st  => entx_s <= '0';
        when s1_st    => ASCrev(out_byte_s, div_s); entx_s <= '1';
        when clr7_st  => entx_s <= '0';
        when s2_st    => ASCrev(out_byte_s, div_s); entx_s <= '1';
        when clr8_st  => entx_s <= '0';
        when e_st     => out_byte_s <= bE_c; entx_s <= '1';
        when clr9_st  => entx_s <= '0';
        when cr_st    => out_byte_s <= bCR_c; entx_s <= '1';
        when clr10_st => entx_s <= '0';
        when lf_st    => out_byte_s <= bLF_c; entx_s <= '1';
        when clr11_st => entx_s <= '0';
        when others   => entx_s <= '0'; out_byte_s <= (others => '0');
      end case;
  end process;
  
  tx_state_p: process(tx_fsm_s, entx_s)
  begin
    tx_fsmnx_s <= tx_fsm_s;
      case tx_fsm_s is
        when idle_st =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx1_up_st;
          else
            tx_fsmnx_s <= idle_st;
          end if;
        when tx1_up_st    =>
          tx_fsmnx_s <= tx1_down_st;
        when tx1_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx2_up_st;
          else
            tx_fsmnx_s <= tx1_down_st;
          end if;
        when tx2_up_st    =>
          tx_fsmnx_s <= tx2_down_st;
        when tx2_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx3_up_st;
          else
            tx_fsmnx_s <= tx2_down_st;
          end if;
        when tx3_up_st    =>
          tx_fsmnx_s <= tx3_down_st;
        when tx3_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx4_up_st;
          else
            tx_fsmnx_s <= tx3_down_st;
          end if;
        when tx4_up_st    =>
          tx_fsmnx_s <= tx4_down_st;
        when tx4_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx5_up_st;
          else
            tx_fsmnx_s <= tx4_down_st;
          end if;
        when tx5_up_st    =>
          tx_fsmnx_s <= tx5_down_st;
        when tx5_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx6_up_st;
          else
            tx_fsmnx_s <= tx5_down_st;
          end if;
        when tx6_up_st    =>
          tx_fsmnx_s <= tx6_down_st;
        when tx6_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx7_up_st;
          else
            tx_fsmnx_s <= tx6_down_st;
          end if;
        when tx7_up_st    =>
          tx_fsmnx_s <= tx7_down_st;
        when tx7_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx8_up_st;
          else
            tx_fsmnx_s <= tx7_down_st;
          end if;
        when tx8_up_st    =>
          tx_fsmnx_s <= tx8_down_st;
        when tx8_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx9_up_st;
          else
            tx_fsmnx_s <= tx8_down_st;
          end if;
        when tx9_up_st    =>
          tx_fsmnx_s <= tx9_down_st;
        when tx9_down_st  =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx10_up_st;
          else
            tx_fsmnx_s <= tx9_down_st;
          end if;
        when tx10_up_st   =>
          tx_fsmnx_s <= tx10_down_st;
        when tx10_down_st =>
          if entx_s = '1' then
            tx_fsmnx_s <= tx11_up_st;
          else
            tx_fsmnx_s <= tx10_down_st;
          end if;
        when tx11_up_st   =>
          tx_fsmnx_s <= tx11_down_st;
        when tx11_down_st => 
          tx_fsmnx_s <= idle_st;
        when others =>
          tx_fsmnx_s <= idle_st;     
      end case;
  end process;
  
  tx_en_p: process(tx_fsm_s)
  begin
      case tx_fsm_s is
        when idle_st      =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx1_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx1_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx2_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx2_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx3_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx3_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '1';
        when tx4_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx4_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx5_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx5_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx6_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx6_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '1';
        when tx7_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx7_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx8_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx8_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx9_up_st    =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx9_down_st  =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx10_up_st   =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx10_down_st =>  tx_dv_s <= '0'; tx_last_s <= '0'; endiv_s <= '0';
        when tx11_up_st   =>  tx_dv_s <= '1'; tx_last_s <= '0'; endiv_s <= '0';
        when tx11_down_st =>  tx_dv_s <= '0'; tx_last_s <= '1'; endiv_s <= '0';
      end case;
  end process;
  
  
end architecture;

