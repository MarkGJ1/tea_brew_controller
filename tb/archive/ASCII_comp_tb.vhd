library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ASCII_Comp_tb_e is
end ASCII_Comp_tb_e;

architecture ASCII_Comp_tb_x of ASCII_Comp_tb_e is

  component uartV2_tx_e is 

    generic(baud_g : integer := 1250);
   
    port(
      cp_i         : in std_logic;
      rb_i         : in std_logic;
      tx_dv_i      : in std_logic;
      tx_byte_i    : in std_logic_vector(7 downto 0);
      tx_active_o  : out std_logic;
      tx_serial_o  : out std_logic;
      tx_done_o    : out std_logic);
  end component;

  component uartV2_rx_e is

    generic(baud_g : integer := 1250);
    port(
      cp_i         : in std_logic;
      rb_i         : in std_logic;
      rxd_i        : in std_logic;
      rx_dv_o      : out std_logic;
      rx_byte_o    : out std_logic_vector(7 downto 0));
  end component;
  
  component ASCII_decode_e is

    port(
    cp_i      : in  std_logic;
    rb_i      : in  std_logic;
    rx_dv_i   : in  std_logic;
    rx_byte_i : in  std_logic_vector(7 downto 0);
    sum_i     : in  integer;
    en_sum_i  : in  std_logic;
    sec_o     : out integer;
    en_sec_o  : out std_logic);
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
  

constant clk_freq_c    : integer := 12000000;
constant clk_period_c  : time    := 1000 ms /clk_freq_c;
constant clk_per_bit_c : integer := 1250;
constant baud_freq_c   : integer := 9600;
constant bit_period_c  : time    := 1000 ms /baud_freq_c;

signal cp_s          : std_logic := '0';
signal rb_s          : std_logic;
signal tx_dv_s       : std_logic;
signal tx_byte_s     : std_logic_vector(7 downto 0);
signal tx_serial_s   : std_logic;
signal tx_done_s     : std_logic;
signal tx_active_s   : std_logic;
signal rx_dv_s       : std_logic;
signal rx_byte_s     : std_logic_vector(7 downto 0);
signal rxd_s         : std_logic;
signal en_sum_s      : std_logic := '0';
signal en_sec_s      : std_logic;
signal sum_s         : integer := 120;
signal seconds_s     : integer;


procedure uart_write_byte (
  data_in_i        : in std_logic_vector(7 downto 0);
  signal serial_o  : out std_logic) is
begin
  
  serial_o <= '0';  -- start bit
  wait for bit_period_c;
  
  for ii in 0 to 7 loop
    serial_o <= data_in_i(ii);
    wait for bit_period_c;
  end loop;
  
  serial_o <= '1'; -- first stop bit
  wait for bit_period_c;
  
  serial_o <= '1'; -- second stop bit
  wait for bit_period_c;
  
end uart_write_byte;

begin
  uart_tx_inst : uartV2_tx_e
    generic map(baud_g => clk_per_bit_c)
    port map(
      cp_i        => cp_s,
      rb_i        => rb_s,
      tx_dv_i     => tx_dv_s,
      tx_byte_i   => tx_byte_s,
      tx_active_o => tx_active_s,
      tx_serial_o => tx_serial_s,
      tx_done_o   => tx_done_s);

  uart_rx_inst: uartV2_rx_e
    generic map(baud_g => clk_per_bit_c)
    port map(
      cp_i        => cp_s,
      rb_i        => rb_s,
      rxd_i       => rxd_s,
      rx_dv_o     => rx_dv_s,
      rx_byte_o   => rx_byte_s);
      
  ascii_decode_inst : ASCII_decode_e
    port map(
      cp_i        => cp_s,
      rb_i        => rb_s,
      rx_dv_i     => rx_dv_s,
      rx_byte_i   => rx_byte_s,
      sum_i       => sum_s,
      en_sum_i    => en_sum_s,
      sec_o       => seconds_s,
      en_sec_o    => en_sec_s);
  
  ascii_encode_inst : ASCII_encode_e
    port map(
      cp_i      =>  cp_s,
      rb_i      =>  rb_s,
      en_sec_i  =>  en_sec_s,
      tx_done_i =>  tx_done_s,
      sec_i     =>  seconds_s,
      tx_dv_o   =>  tx_dv_s,
      tx_byte_o =>  tx_byte_s);
      
  cp_s <= not cp_s after clk_period_c/2;
  
  process is
  begin
  
    rb_s <= '0';
    wait until rising_edge(cp_s);
    wait until rising_edge(cp_s);
    rb_s <= '1';
    wait until rising_edge(cp_s);
    
    uart_write_byte(X"31", rxd_s);
    uart_write_byte(X"34", rxd_s);
    uart_write_byte(X"3A", rxd_s);
    uart_write_byte(X"35", rxd_s);
    uart_write_byte(X"39", rxd_s);
    uart_write_byte(X"3A", rxd_s);
    uart_write_byte(X"30", rxd_s);
    uart_write_byte(X"36", rxd_s);
    
    wait for 500 us;
    en_sum_s <= '1';
    
    wait;
    
  end process;
end architecture;
      

