architecture ASCconv_a of ASCconv_e is

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
  constant bE_c     : std_logic_vector(7 downto 0) := X"45";
  constant bSemi_c  : std_logic_vector(7 downto 0) := X"3A";
  constant bCR_c    : std_logic_vector(7 downto 0) := X"0D";
  constant bLF_c    : std_logic_vector(7 downto 0) := X"0A";
  constant br_c     : std_logic_vector(7 downto 0) := X"72";
  constant day_c    : integer := 86400;
  constant hr1_c    : integer := 36000;
  constant hr2_c    : integer := 3600;
  constant min1_c   : integer := 600;
  constant min2_c   : integer := 60;
  constant s1_c     : integer := 10;
  
  type rx_asc_fsm_t is (idle_st, hr1_st, hr2_st, min1_st, min2_st, s1_st, 
  s2_st, semi1_st, semi2_st, tim_st);
  
  type tx_asc_fsm_t is (idle_st, hr1_st, hr2_st, min1_st, min2_st, s1_st, 
  s2_st, semi1_st, semi2_st, cr_st, lf_st, clean_st);
  
  signal rx_asc_fsm_s, rx_asc_fsmnx_s : rx_asc_fsm_t;
  signal tx_asc_fsm_s, tx_asc_fsmnx_s : tx_asc_fsm_t;
  
  signal incByte_s : std_logic_vector(7 downto 0);
  signal seconds_s : integer;
  signal adder_s   : integer;
  signal div_s     : integer;
  signal semi_s    : std_logic;
  signal txb_s     : std_logic;
  signal txn_s     : std_logic;
  
  procedure ASCchk (signal byteChk  : in  std_logic_vector(7 downto 0);
                    signal intDec   : out integer;
                    signal semiChk  : out std_logic) is
  begin
    case byteChk is
      when b0_c    =>  intDec  <= 0; semiChk <= '0';
      when b1_c    =>  intDec  <= 1; semiChk <= '0';
      when b2_c    =>  intDec  <= 2; semiChk <= '0';
      when b3_c    =>  intDec  <= 3; semiChk <= '0';
      when b4_c    =>  intDec  <= 4; semiChk <= '0';
      when b5_c    =>  intDec  <= 5; semiChk <= '0';
      when b6_c    =>  intDec  <= 6; semiChk <= '0';
      when b7_c    =>  intDec  <= 7; semiChk <= '0';
      when b8_c    =>  intDec  <= 8; semiChk <= '0'; 
      when b9_c    =>  intDec  <= 9; semiChk <= '0';
      when bSemi_c =>  semiChk <= '1';
      when others  =>  intDec  <= 0; semiChk <= '0';
    end case;
  end procedure;
  
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

  seconds_o <= seconds_s;

  asc_takt_p: process(rb_i, cp_i)
  begin
    if rb_i = '0' then
      rx_asc_fsm_s <= idle_st;
      tx_asc_fsm_s <= idle_st;
    elsif rising_edge(cp_i) then
      rx_asc_fsm_s <= rx_asc_fsmnx_s;
      tx_asc_fsm_s <= tx_asc_fsmnx_s;
    end if;
  end process;  
  
  rx_asc_state_p: process(rx_asc_fsm_s, rx_dv_i, ensum_i)
  begin
    rx_asc_fsmnx_s <= rx_asc_fsm_s;
      
      case rx_asc_fsm_s is
        
        when idle_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= hr1_st;
          else
            rx_asc_fsmnx_s <= idle_st;
          end if;
        
        when hr1_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= hr2_st;
          else
            rx_asc_fsmnx_s <= hr1_st;
          end if;
        
        when hr2_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= semi1_st;
          else
            rx_asc_fsmnx_s <= hr2_st;
          end if;
          
        when semi1_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= min1_st;
          else
            rx_asc_fsmnx_s <= semi1_st;
          end if;
          
        when min1_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= hr1_st;
          else
            rx_asc_fsmnx_s <= idle_st;
          end if;
        
        when min2_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= hr1_st;
          else
            rx_asc_fsmnx_s <= idle_st;
          end if;
        
        when semi2_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= hr1_st;
          else
            rx_asc_fsmnx_s <= idle_st;
          end if;
        
        when s1_st =>
          if rx_dv_i = '1' then
            rx_asc_fsmnx_s <= hr1_st;
          else
            rx_asc_fsmnx_s <= idle_st;
          end if;
        
        when s2_st =>
          if ensum_i = '1' then
            rx_asc_fsmnx_s <= tim_st;
          else
            rx_asc_fsmnx_s <= s2_st;
          end if;
          
        when tim_st =>
          rx_asc_fsmnx_s <= idle_st;
        
        when others =>
          rx_asc_fsmnx_s <= idle_st;
          
      end case;
  
  end process;
  
  rx_asc_beh_p: process(rx_asc_fsm_s)
  begin
    case rx_asc_fsm_s is
      when idle_st =>
        incByte_s <= (others => '0');
        seconds_s <= 0;
        adder_s   <= 0;
        semi_s    <= '0';
        txb_s     <= '0';
      when hr1_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
        seconds_s <= seconds_s + (adder_s * hr1_c);
      when hr2_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
        seconds_s <= seconds_s + (adder_s * hr2_c);
      when semi1_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
      when min1_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
        seconds_s <= seconds_s + (adder_s * min1_c);
      when min2_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
        seconds_s <= seconds_s + (adder_s * min2_c);
      when semi2_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
      when s1_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
        seconds_s <= seconds_s + (adder_s * s1_c);
      when s2_st =>
        incByte_s <= rx_byte_i;
        ASCchk(incByte_s, adder_s, semi_s);
        seconds_s <= seconds_s + adder_s;
      when tim_st =>
        seconds_s <= seconds_s + sum_i;
        txb_s <= '1';
        seconds_s <= seconds_s mod day_c;
      when others =>
        incByte_s <= (others => '0');
        seconds_s <= 0;
        adder_s   <= 0;
        semi_s    <= '0';
        txb_s     <= '0';
    end case;
  end process;
  
  tx_asc_state_p: process(tx_asc_fsm_s, tx_done_i, txb_s) 
  begin
    tx_asc_fsmnx_s <= tx_asc_fsm_s;
      case tx_asc_fsm_s is
        when idle_st  =>
          if txb_s = '1' then
            tx_asc_fsmnx_s <= hr1_st;
          else
            tx_asc_fsmnx_s <= idle_st;
          end if;
          
        when hr1_st   =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= hr2_st;
          else
            tx_asc_fsmnx_s <= hr1_st;
          end if;
        when hr2_st   =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= semi1_st;
          else
            tx_asc_fsmnx_s <= hr2_st;
          end if;
        when semi1_st =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= min1_st;
          else
            tx_asc_fsmnx_s <= semi1_st;
          end if;
        when min1_st  =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= min2_st;
          else
            tx_asc_fsmnx_s <= min1_st;
          end if;
        when min2_st  =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= semi2_st;
          else
            tx_asc_fsmnx_s <= min2_st;
          end if;
        when semi2_st =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= s1_st;
          else
            tx_asc_fsmnx_s <= semi2_st;
          end if;
        when s1_st    =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= s2_st;
          else
            tx_asc_fsmnx_s <= s1_st;
          end if;
        when s2_st    =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= cr_st;
          else
            tx_asc_fsmnx_s <= s2_st;
          end if;
        when cr_st    =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= lf_st;
          else
            tx_asc_fsmnx_s <= cr_st;
          end if;
        when lf_st    =>
          if tx_done_i = '1' then
            tx_asc_fsmnx_s <= clean_st;
          else
            tx_asc_fsmnx_s <= lf_st;
          end if;
        when clean_st =>
          tx_asc_fsmnx_s <= idle_st;
        when others   =>
          tx_asc_fsmnx_s <= idle_st;
      end case;
  end process;
  
  tx_asc_beh_p: process(tx_asc_fsm_s)
  begin
      case tx_asc_fsm_s is
        when idle_st  =>
          div_s <= 0;
          txn_s <= '0';
        when hr1_st   =>
          div_s <= seconds_s / hr1_c;
          ASCrev(tx_byte_o, div_s);
          txn_s <= '1';
        when hr2_st   =>
          txn_s <= '0';
          div_s <= (seconds_s / hr2_c) mod 10;
          ASCrev(tx_byte_o, div_s);
          txn_s <= '1';
        when semi1_st =>
          txn_s <= '0';
          tx_byte_o <= bSemi_c;
          txn_s <= '1';
        when min1_st  =>
          txn_s <= '0';
          div_s <= (seconds_s / min1_c) mod 6;
          ASCrev(tx_byte_o, div_s);
          txn_s <= '1';
        when min2_st  =>
          txn_s <= '0';
          div_s <= (seconds_s / min2_c) mod 10;
          ASCrev(tx_byte_o, div_s);
          txn_s <= '1';
        when semi2_st =>
          txn_s <= '0';
          tx_byte_o <= bSemi_c;
          txn_s <= '1';
        when s1_st    =>
          txn_s <= '0';
          div_s <= (seconds_s / s1_c) mod 6;
          ASCrev(tx_byte_o, div_s);
          txn_s <= '1';
        when s2_st    =>
          txn_s <= '0';
          div_s <= seconds_s mod 10;
          ASCrev(tx_byte_o, div_s);
          txn_s <= '1';
        when cr_st    =>
          txn_s <= '0';
          tx_byte_o <= bCR_c;
          txn_s <= '1';
        when lf_st    =>
          txn_s <= '0';
          tx_byte_o <= bLF_c;
          txn_s <= '1';
        when clean_st =>
          txn_s <= '0';
          div_s <= 0;
        when others   =>
          txn_s <= '0';
          div_s <= 0;
      end case;
  end process;
  
  tx_dv_o <= txb_s or txn_s;
  
end architecture;
