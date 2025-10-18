library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartV2_reverse_tb_e is
end uartV2_reverse_tb_e;

architecture uartV2_reverse_tb_x of uartV2_reverse_tb_e is

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
    rx_byte_o    : out std_logic_vector(7 downto 0);
    read_o       : out std_logic);
end component;

constant clk_freq_c    : integer := 12000000;
constant clk_period_c  : time    := 1000 ms /clk_freq_c;
constant clk_per_bit_c : integer := 1250;
constant baud_freq_c   : integer := 9600;
constant bit_period_c  : time    := 1000 ms /baud_freq_c;

signal cp_s          : std_logic := '0';
signal rb_s          : std_logic;
signal tx_dv_s       : std_logic := '0';
signal tx_byte_s     : std_logic_vector(7 downto 0) := (others => '0');
signal tx_serial_s   : std_logic;
signal tx_done_s     : std_logic;
signal tx_active_s   : std_logic;
signal rx_dv_s       : std_logic;
signal rx_byte_s     : std_logic_vector(7 downto 0);
signal rxd_s         : std_logic := '1';
signal read_s        : std_logic;


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
      rxd_i       => tx_serial_s,
      rx_dv_o     => rx_dv_s,
      rx_byte_o   => rx_byte_s,
      read_o      => read_s);
      
  cp_s <= not cp_s after clk_period_c/2;
  
  process is
  begin
  
    rb_s      <= '0';
    wait until rising_edge(cp_s);
    rb_s      <= '1';
    wait until rising_edge(cp_s);
    tx_dv_s   <= '1';
    tx_byte_s <= X"FF";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"31";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"35";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"3A";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"30";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"31";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"3A";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"30";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"36";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"0D";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
    wait until rising_edge(cp_s);
    
    tx_dv_s   <= '1';
    tx_byte_s <= X"0A";
    wait until rising_edge(cp_s);
    tx_dv_s   <= '0';
    wait until tx_done_s = '1';
    
  
    if rx_byte_s = X"FF" then
      report "Test Passed - CORRECT BYTE RECEIVED" severity note;
    else
      report "Test Failed - INCORRECT BYTE RECEIVED" severity note;
    end if;
  
    wait for 600 us;
      
    assert (false) report "Test Complete" severity failure;

  end process;
end architecture;
      

