library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uartV2_tx_e is

  generic(baud_g  : integer := 1250);
  port(
    cp_i        : in  std_logic;
    rb_i        : in  std_logic;
    tx_dv_i     : in  std_logic;
    tx_byte_i   : in  std_logic_vector(7 downto 0);
    tx_active_o : out std_logic;
    tx_serial_o : out std_logic;
    tx_done_o   : out std_logic);
end entity;

architecture uartV2_tx_a of uartV2_tx_e is

  type tx_fsm_t is (idle_st, bitST_st, bit1_st, bit2_st, bit3_st, bit4_st,
  bit5_st, bit6_st, bit7_st, bit8_st, bitD_st, bitD2_st, clean_st);
  
  signal tx_fsm_s, tx_fsmnx_s : tx_fsm_t;
  signal baud_s     : integer range 0 to baud_g-1;
  signal tx_data_s  : std_logic_vector(7 downto 0);
  signal nx_s       : std_logic;
  signal activ_s    : std_logic;
  signal tx_done_s  : std_logic;
  

begin

  tx_active_o <= activ_s;
  tx_done_o   <= tx_done_s;

  tx_takt_p: process(cp_i, rb_i, activ_s)
  begin
    if rb_i = '0' then
      tx_fsm_s <= idle_st;
    elsif rising_edge(cp_i) then
      tx_fsm_s <= tx_fsmnx_s;
      
      if activ_s = '1' then
        if baud_s < baud_g-1 then
          baud_s <= baud_s + 1;
          nx_s   <= '0';
        else
          baud_s <= 0;
          nx_s   <= '1';
        end if;
      else
        baud_s <= 0;
        nx_s   <= '0';
      end if;
    end if;  
  end process;
  

  tx_fsmf_p: process(tx_fsm_s, tx_dv_i, nx_s)
  begin
    tx_fsmnx_s <= tx_fsm_s;
    
    case tx_fsm_s is
      when idle_st =>
        if tx_dv_i = '1' then
          tx_fsmnx_s <= bitST_st;
        else
          tx_fsmnx_s <= idle_st;
        end if;
      when bitST_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit1_st;
        else
          tx_fsmnx_s <= bitST_st;
        end if;
      when bit1_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit2_st;
        else
          tx_fsmnx_s <= bit1_st;
        end if;
      when bit2_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit3_st;
        else
          tx_fsmnx_s <= bit2_st;
        end if;
      when bit3_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit4_st;
        else
          tx_fsmnx_s <= bit3_st;
        end if;
      when bit4_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit5_st;
        else
          tx_fsmnx_s <= bit4_st;
        end if;
      when bit5_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit6_st;
        else
          tx_fsmnx_s <= bit5_st;
        end if;
      when bit6_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit7_st;
        else
          tx_fsmnx_s <= bit6_st;
        end if;
      when bit7_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bit8_st;
        else
          tx_fsmnx_s <= bit7_st;
        end if;
      when bit8_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bitD_st;
        else
          tx_fsmnx_s <= bit8_st;
        end if;
      when bitD_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= bitD2_st;
        else
          tx_fsmnx_s <= bitD_st;
        end if;
      when bitD2_st =>
        if nx_s = '1' then
          tx_fsmnx_s <= clean_st;
        else
          tx_fsmnx_s <= bitD2_st;
        end if;
      when clean_st =>
        tx_fsmnx_s <= idle_st;
      when others =>
        tx_fsmnx_s <= idle_st;
   
    end case;
  end process;
  
  tx_out_p: process(tx_fsm_s)
  begin
  
    case tx_fsm_s is
      when idle_st =>
        activ_s     <= '0';
        tx_data_s   <= (others => '0');
        tx_serial_o <= '1';
        tx_done_s   <= '0';
        
      when bitST_st =>
        activ_s <= '1';
        tx_serial_o <= '0';
        tx_data_s   <= tx_byte_i;
        
      when bit1_st =>
        tx_serial_o <= tx_data_s(0);
      when bit2_st =>
        tx_serial_o <= tx_data_s(1);
      when bit3_st =>
        tx_serial_o <= tx_data_s(2);
      when bit4_st =>
        tx_serial_o <= tx_data_s(3);
      when bit5_st =>
        tx_serial_o <= tx_data_s(4);
      when bit6_st =>
        tx_serial_o <= tx_data_s(5);
      when bit7_st =>
        tx_serial_o <= tx_data_s(6);
      when bit8_st =>
        tx_serial_o <= tx_data_s(7);
      when bitD_st =>
        tx_serial_o <= '1';
      when bitD2_st =>
        tx_serial_o <= '1';
        
      when clean_st =>
        tx_serial_o <= '1';
        tx_done_s   <= '1';
        activ_s     <= '0';
        tx_data_s   <= (others => '0');
      when others =>
        activ_s     <= '0';
        tx_data_s   <= (others => '0');
        tx_serial_o <= '1';
        tx_done_s   <= '0';
    end case;
  
  end process;
end architecture;
