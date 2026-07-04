architecture ASCII_encode_a of ASCII_encode_e is

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
  
  type enc_fsm_t is (idle_st, sec_st, hh1_st, hh2_st, min1_st, min2_st, s1_st,
  s2_st, semi1_st, semi2_st, div1_st, div2_st, div3_st,div4_st, div5_st, 
  div6_st, E_st, cr_st, lf_st);
  
  signal enc_fsm_s, enc_fsmnx_s : enc_fsm_t;
  
  type tx_fsm_t is (idle_st, tx1_up_st, tx2_up_st, tx3_up_st, tx4_up_st,
  tx5_up_st, tx6_up_st, tx7_up_st, tx8_up_st, tx9_up_st, tx10_up_st,
  tx11_up_st, tx1_down_st, tx2_down_st, tx3_down_st, tx4_down_st,
  tx5_down_st, tx6_down_st, tx7_down_st, tx8_down_st, tx9_down_st,
  tx10_down_st, tx11_down_st);
  
  signal tx_fsm_s, tx_fsmnx_s : tx_fsm_t;
  
  
  signal out_byte_s : std_logic_vector(7 downto 0);
  signal seconds_s  : integer;
  signal divide_s   : integer;
  signal tx_dv_s    : std_logic;
  signal tx_start_s : std_logic;
  
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
      enc_fsm_s <= idle_st;
      tx_fsm_s  <= idle_st;
    elsif rising_edge(cp_i) then
      enc_fsm_s  <= enc_fsmnx_s;
      tx_fsm_s   <= tx_fsmnx_s;
    end if;
  end process;
  
  tx_state_p: process(tx_fsm_s, tx_done_i, tx_start_s)
  begin
    tx_fsmnx_s <= tx_fsm_s;
      case tx_fsm_s is
        when idle_st =>
          if tx_start_s = '1' then
            tx_fsmnx_s <= tx1_up_st;
          else
            tx_fsmnx_s <= idle_st;
          end if;
        when tx1_up_st    =>
          tx_fsmnx_s <= tx1_down_st;
        when tx1_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx2_up_st;
          else
            tx_fsmnx_s <= tx1_down_st;
          end if;
        when tx2_up_st    =>
          tx_fsmnx_s <= tx2_down_st;
        when tx2_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx3_up_st;
          else
            tx_fsmnx_s <= tx2_down_st;
          end if;
        when tx3_up_st    =>
          tx_fsmnx_s <= tx3_down_st;
        when tx3_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx4_up_st;
          else
            tx_fsmnx_s <= tx3_down_st;
          end if;
        when tx4_up_st    =>
          tx_fsmnx_s <= tx4_down_st;
        when tx4_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx5_up_st;
          else
            tx_fsmnx_s <= tx4_down_st;
          end if;
        when tx5_up_st    =>
          tx_fsmnx_s <= tx5_down_st;
        when tx5_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx6_up_st;
          else
            tx_fsmnx_s <= tx5_down_st;
          end if;
        when tx6_up_st    =>
          tx_fsmnx_s <= tx6_down_st;
        when tx6_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx7_up_st;
          else
            tx_fsmnx_s <= tx6_down_st;
          end if;
        when tx7_up_st    =>
          tx_fsmnx_s <= tx7_down_st;
        when tx7_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx8_up_st;
          else
            tx_fsmnx_s <= tx7_down_st;
          end if;
        when tx8_up_st    =>
          tx_fsmnx_s <= tx8_down_st;
        when tx8_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx9_up_st;
          else
            tx_fsmnx_s <= tx8_down_st;
          end if;
        when tx9_up_st    =>
          tx_fsmnx_s <= tx9_down_st;
        when tx9_down_st  =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx10_up_st;
          else
            tx_fsmnx_s <= tx9_down_st;
          end if;
        when tx10_up_st   =>
          tx_fsmnx_s <= tx10_down_st;
        when tx10_down_st =>
          if tx_done_i = '1' and tx_start_s = '1' then
            tx_fsmnx_s <= tx11_up_st;
          else
            tx_fsmnx_s <= tx10_down_st;
          end if;
        when tx11_up_st   =>
          tx_fsmnx_s <= tx11_down_st;
        when tx11_down_st => 
          if tx_done_i = '1' then
            tx_fsmnx_s <= idle_st;
          else
            tx_fsmnx_s <= tx11_down_st;
          end if;
        when others =>
          tx_fsmnx_s <= idle_st;     
      end case;
  end process;
  
  tx_en_p: process(tx_fsm_s)
  begin
      case tx_fsm_s is
        when idle_st =>       tx_dv_s <= '0';
        when tx1_up_st    =>  tx_dv_s <= '1';
        when tx1_down_st  =>  tx_dv_s <= '0';
        when tx2_up_st    =>  tx_dv_s <= '1';
        when tx2_down_st  =>  tx_dv_s <= '0';
        when tx3_up_st    =>  tx_dv_s <= '1';
        when tx3_down_st  =>  tx_dv_s <= '0';
        when tx4_up_st    =>  tx_dv_s <= '1';
        when tx4_down_st  =>  tx_dv_s <= '0';
        when tx5_up_st    =>  tx_dv_s <= '1';
        when tx5_down_st  =>  tx_dv_s <= '0';
        when tx6_up_st    =>  tx_dv_s <= '1';
        when tx6_down_st  =>  tx_dv_s <= '0';
        when tx7_up_st    =>  tx_dv_s <= '1';
        when tx7_down_st  =>  tx_dv_s <= '0';
        when tx8_up_st    =>  tx_dv_s <= '1';
        when tx8_down_st  =>  tx_dv_s <= '0';
        when tx9_up_st    =>  tx_dv_s <= '1';
        when tx9_down_st  =>  tx_dv_s <= '0';
        when tx10_up_st   =>  tx_dv_s <= '1';
        when tx10_down_st =>  tx_dv_s <= '0';
        when tx11_up_st   =>  tx_dv_s <= '1';
        when tx11_down_st =>  tx_dv_s <= '0';
      end case;
  end process;
  
  encode_state_p: process(enc_fsm_s, en_sec_i, tx_done_i)
  begin
    enc_fsmnx_s <= enc_fsm_s;
      case enc_fsm_s is
        when idle_st =>
          if en_sec_i = '1' then
            enc_fsmnx_s <= sec_st;
          else
            enc_fsmnx_s <= idle_st;
          end if;
        when sec_st =>
          enc_fsmnx_s <= div1_st;
        when div1_st =>
          enc_fsmnx_s <= hh1_st;
        when hh1_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= div2_st;
          else
            enc_fsmnx_s <= hh1_st;
          end if;
        when div2_st =>
          enc_fsmnx_s <= hh2_st;
        when hh2_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= semi1_st;
          else
            enc_fsmnx_s <= hh2_st;
          end if;
        when semi1_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= div3_st;
          else
            enc_fsmnx_s <= semi1_st;
          end if;
        when div3_st =>
          enc_fsmnx_s <= min1_st;
        when min1_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= div4_st;
          else
            enc_fsmnx_s <= min1_st;
          end if;
        when div4_st =>
          enc_fsmnx_s <= min2_st;
        when min2_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= semi2_st;
          else
            enc_fsmnx_s <= min2_st;
          end if;
        when semi2_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= div5_st;
          else
            enc_fsmnx_s <= semi2_st;
          end if;
        when div5_st =>
          enc_fsmnx_s <= s1_st;
        when s1_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= div6_st;
          else
            enc_fsmnx_s <= s1_st;
          end if;
        when div6_st =>
          enc_fsmnx_s <= s2_st;
        when s2_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= E_st;
          else
            enc_fsmnx_s <= s2_st;
          end if;
        when E_st  =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= cr_st;
          else
            enc_fsmnx_s <= E_st;
          end if;
        when cr_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= lf_st;
          else
            enc_fsmnx_s <= cr_st;
          end if;
        when lf_st =>
          if tx_done_i = '1' then
            enc_fsmnx_s <= idle_st;
          else
            enc_fsmnx_s <= lf_st;
          end if;
        when others  =>
          enc_fsmnx_s <= idle_st;
      end case;
  end process;
  
  encode_out_p: process(enc_fsm_s)
  begin
    case enc_fsm_s is
        when idle_st =>
          out_byte_s <= (others => '0');
          seconds_s  <= 0;
          divide_s   <= 0;
          tx_start_s <= '0';
          
        when sec_st =>
          out_byte_s <= (others => '0');
          seconds_s  <= sec_i;
          divide_s   <= 0;
          tx_start_s <= '0';
          
        when div1_st =>
          divide_s <= seconds_s / 36000;
          tx_start_s <= '0';
           
        when hh1_st =>
          ASCrev(out_byte_s, divide_s);
          tx_start_s <= '1';
          
        when div2_st =>
          divide_s <= (seconds_s / 3600) mod 10;
          tx_start_s <= '0';
          
        when hh2_st =>
          ASCrev(out_byte_s, divide_s);
          tx_start_s <= '1';
          
        when semi1_st =>
          out_byte_s <= bSemi_c;
          tx_start_s <= '1';
          
        when div3_st =>
          divide_s <= (seconds_s / 600) mod 6;
          tx_start_s <= '0';
          
        when min1_st =>
          ASCrev(out_byte_s, divide_s);
          tx_start_s <= '1';
          
        when div4_st =>
          divide_s <= (seconds_s / 60) mod 10;
          tx_start_s <= '0';
          
        when min2_st =>
          ASCrev(out_byte_s, divide_s);
          tx_start_s <= '1';
          
        when semi2_st =>
          out_byte_s <= bSemi_c;
          tx_start_s <= '1';
          
        when div5_st =>
          divide_s <= (seconds_s / 10) mod 6;
          tx_start_s <= '0';
          
        when s1_st =>
          ASCrev(out_byte_s, divide_s);
          tx_start_s <= '1';
          
        when div6_st =>
          divide_s <= seconds_s mod 10;
          tx_start_s <= '0';
          
        when s2_st =>
          ASCrev(out_byte_s, divide_s);
          tx_start_s <= '1';
          
        when E_st =>
          out_byte_s <= bE_c;
          tx_start_s <= '1';
          
        when cr_st =>
          out_byte_s <= bCR_c;
          tx_start_s <= '1';
          
        when lf_st =>
          out_byte_s <= bLF_c;
          tx_start_s <= '1';
       
        when others  =>
          out_byte_s <= (others => '0');
          seconds_s  <= 0;
          divide_s   <= 0;
          tx_start_s <= '0';
          
    end case;
  end process;
  
end architecture;
