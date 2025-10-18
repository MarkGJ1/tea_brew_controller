library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCII_decode_e is
  
  port(
    cp_i      : in  std_logic;
    rb_i      : in  std_logic;
    rx_dv_i   : in  std_logic;
    rx_byte_i : in  std_logic_vector(7 downto 0);
    sum_i     : in  integer;
    en_sum_i  : in  std_logic;
    sec_o     : out integer;
    en_sec_o  : out std_logic);

end entity;

architecture ASCII_decode_a of ASCII_decode_e is

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
  constant bCR_c    : std_logic_vector(7 downto 0) := X"0D";
  constant bLF_c    : std_logic_vector(7 downto 0) := X"0A";
  
  type dec_fsm_t is (idle_st, hh1_st, hh2_st, min1_st, min2_st, s1_st,
  s2_st, semi1_st, semi2_st, sum_st, en_sec_st, add1_st, add2_st, add3_st,
  add4_st, add5_st, add6_st);
  signal dec_fsm_s, dec_fsmnx_s : dec_fsm_t;
  
  signal inc_byte_s : std_logic_vector(7 downto 0);
  signal seconds_s  : integer;
  signal adder_s    : integer;
  signal en_sec_s    : std_logic;
  
  procedure ASCchk (signal byteChk  : in  std_logic_vector(7 downto 0);
                    signal intDec   : out integer) is
  begin
    case byteChk is
      when b0_c    =>  intDec  <= 0; 
      when b1_c    =>  intDec  <= 1; 
      when b2_c    =>  intDec  <= 2;
      when b3_c    =>  intDec  <= 3;
      when b4_c    =>  intDec  <= 4;
      when b5_c    =>  intDec  <= 5;
      when b6_c    =>  intDec  <= 6;
      when b7_c    =>  intDec  <= 7;
      when b8_c    =>  intDec  <= 8;
      when b9_c    =>  intDec  <= 9;
      when others  =>  intDec  <= 0;
    end case;
  end procedure;

begin

  sec_o   <= seconds_s mod 86400;
  en_sec_o <= en_sec_s;

  decode_takt_p: process(rb_i, cp_i)
  begin
    if rb_i = '0' then
      dec_fsm_s <= idle_st;
    elsif rising_edge(cp_i) then
      dec_fsm_s  <= dec_fsmnx_s;
      inc_byte_s <= rx_byte_i;
    end if;
  end process;
  
  decode_state_p: process(dec_fsm_s, rx_dv_i, en_sum_i)
  begin
    dec_fsmnx_s <= dec_fsm_s;
      case dec_fsm_s is
        when idle_st  =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= hh1_st;
          else
            dec_fsmnx_s <= idle_st;
          end if;
          
        when hh1_st   =>
          dec_fsmnx_s <= add1_st;
          
        when add1_st  =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= hh2_st;
          else
            dec_fsmnx_s <= add1_st;
          end if;
          
        when hh2_st   =>
          dec_fsmnx_s <= add2_st;
          
        when add2_st  =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= semi1_st;
          else
            dec_fsmnx_s <= add2_st;
          end if;
          
        when semi1_st =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= min1_st;
          else
            dec_fsmnx_s <= semi1_st;
          end if;
          
        when min1_st  =>
          dec_fsmnx_s <= add3_st;
          
        when add3_st =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= min2_st;
          else
            dec_fsmnx_s <= add3_st;
          end if;
          
        when min2_st  =>
          dec_fsmnx_s <= add4_st;
          
        when add4_st  =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= semi2_st;
          else
            dec_fsmnx_s <= add4_st;
          end if;
          
        when semi2_st =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= s1_st;
          else
            dec_fsmnx_s <= semi2_st;
          end if;
          
        when s1_st   =>
          dec_fsmnx_s <= add5_st; 
                   
        when add5_st  =>
          if rx_dv_i = '1' then
            dec_fsmnx_s <= s2_st;
          else
            dec_fsmnx_s <= add5_st;
          end if;
          
        when s2_st   =>
          dec_fsmnx_s <= add6_st;   
               
        when add6_st  =>
          if en_sum_i = '1' then
            dec_fsmnx_s <= sum_st;
          else
            dec_fsmnx_s <= add6_st;
          end if;
          
        when sum_st   =>
          dec_fsmnx_s <= en_sec_st;
          
        when en_sec_st =>
          dec_fsmnx_s <= idle_st;
          
        when others   =>
          dec_fsmnx_s <= idle_st;
          
      end case;
  end process;
  
  decode_out_p: process(dec_fsm_s)
  begin
    case dec_fsm_s is
        when idle_st  =>
          en_sec_s <= '0';
          seconds_s <= 0;
        when hh1_st   =>
          en_sec_s <= '0';
          ASCchk(inc_byte_s, adder_s);
        when add1_st  =>
          en_sec_s <= '0';
          seconds_s <= seconds_s + (adder_s * 36000);
        when hh2_st   =>
          en_sec_s <= '0';
          ASCchk(inc_byte_s, adder_s);
        when add2_st  =>
          en_sec_s <= '0';
          seconds_s <= seconds_s + (adder_s * 3600);
        when semi1_st =>
          en_sec_s <= '0';
        when min1_st  =>
          en_sec_s <= '0';
          ASCchk(inc_byte_s, adder_s);
        when add3_st  =>
          en_sec_s <= '0';
          seconds_s <= seconds_s + (adder_s * 600);
        when min2_st  =>
          en_sec_s <= '0';
          ASCchk(inc_byte_s, adder_s);
        when add4_st  =>
          en_sec_s <= '0';
          seconds_s <= seconds_s + (adder_s * 60);
        when semi2_st =>
          en_sec_s <= '0';
        when s1_st    =>
          en_sec_s <= '0';
          ASCchk(inc_byte_s, adder_s);
        when add5_st  =>
          en_sec_s <= '0';
          seconds_s <= seconds_s + (adder_s * 10);
        when s2_st    =>
          en_sec_s <= '0';
          ASCchk(inc_byte_s, adder_s);
        when add6_st  =>
          en_sec_s <= '0';
          seconds_s <= seconds_s + adder_s;
        when sum_st   =>
          seconds_s <= seconds_s + sum_i;
          en_sec_s <= '0';
        when en_sec_st =>
          en_sec_s <= '1';
        when others   =>
          seconds_s <= 0;
          en_sec_s <= '0';
      end case;
  end process;
  
end architecture;