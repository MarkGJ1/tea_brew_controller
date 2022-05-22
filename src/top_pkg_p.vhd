library ieee;
use ieee.std_logic_1164.ALL;

package top_pkg_p is
  
  signal en_s         : std_logic;
  signal sndak_s      : std_logic;
  signal sumtim_s     : integer;
  signal sec_s        : integer;
  signal tx_s         : std_logic;
  signal tx_dv_s      : std_logic;
  signal tx_byte_s    : std_logic_vector (7 downto 0);
  signal tx_done_s    : std_logic;
  signal en_sec_s     : std_logic;
  signal rx_byte_s    : std_logic_vector (7 downto 0);
  signal rx_dv_s      : std_logic;
  
  component timerV2_e is
    generic(second_g : integer := 12000000);

    port(cp_i : in  std_logic;
         rb_i : in  std_logic;
         st_i : in  std_logic;
         t0_i : in  std_logic;
         t1_i : in  std_logic;
         en_o : out std_logic; -- en_s
         sum_o: out integer);  -- sum_s
  end component;

  component sndV2_e is
    generic(second_g  : integer := 12000000;
            freq_g    : integer := 6000;
            len_g     : integer := 2);
    port(
     cp_i  : in  std_logic;
     rb_i  : in  std_logic;
     en_i  : in  std_logic; -- en_s
     snd_o : out std_logic; 
     act_o : out std_logic); -- sndak_s
  end component;
  
  component main_ledV2_e is
    port(
    cp_i  : in  std_logic;
    rb_i  : in  std_logic;
    m0_i  : in  std_logic;
    m1_i  : in  std_logic;
    t0_i  : in  std_logic;
    t1_i  : in  std_logic;
    snd_i : in  std_logic; -- sndak_s
    tx_i  : in  std_logic; -- tx_s
    ld1_o : out std_logic;
    ld2_o : out std_logic;
    ld3_o : out std_logic;
    ld4_o : out std_logic;
    ld5_o : out std_logic;
    ld6_o : out std_logic;
    ld7_o : out std_logic;
    ld8_o : out std_logic);
  end component;
  
  component uartV2_tx_e is
    generic(baud_g  : integer := 1250);
      port(
        cp_i        : in  std_logic;
        rb_i        : in  std_logic;
        tx_dv_i     : in  std_logic; -- conn
        tx_byte_i   : in  std_logic_vector(7 downto 0); -- conn
        tx_active_o : out std_logic;
        tx_serial_o : out std_logic;
        tx_done_o   : out std_logic);
  
  end component;
  
  component uartV2_rx_e is
    generic(baud_g  : integer := 1250);
      port(
        cp_i      : in  std_logic;
        rb_i      : in  std_logic;
        rxd_i     : in  std_logic;
        rx_dv_o   : out  std_logic; -- conn
        rx_byte_o : out  std_logic_vector(7 downto 0)); --conn
  end component;
  
  component ASCII_decode_e is
    port(
      cp_i      : in  std_logic;
      rb_i      : in  std_logic;
      rx_dv_i   : in  std_logic; -- conn
      rx_byte_i : in  std_logic_vector(7 downto 0); -- conn
      sum_i     : in  integer; -- conn
      en_sum_i  : in  std_logic; -- conn
      sec_o     : out integer; -- conn
      en_sec_o  : out std_logic); -- conn
  end component;
  
  component ASCII_encode_e is
    port(
      cp_i      : in  std_logic;
      rb_i      : in  std_logic;
      en_sec_i  : in  std_logic;
      tx_done_i : in  std_logic;
      sec_i     : in  integer;
      tx_dv_o   : out std_logic;
      tx_byte_o : out std_logic_vector(7 downto 0));
  end component;
    
end package;
