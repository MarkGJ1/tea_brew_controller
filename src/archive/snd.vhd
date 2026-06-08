library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sndV2_e is

  generic(second_g  : integer := 12000000;
          freq_g    : integer := 12000;
          len_g     : integer := 2);
  port(
    cp_i  : in  std_logic;
    rb_i  : in  std_logic;
    en_i  : in  std_logic;
    snd_o : out std_logic;
    act_o : out std_logic);

end entity;

architecture sndV2_a of sndV2_e is

  signal sec_s  : integer range 0 to second_g-1;
  signal len_s  : integer range 0 to len_g-1;
  signal freq_s : integer range 0 to freq_g-1;
  signal snd_s  : std_logic;
  signal gen_s  : std_logic;
  signal en_s   : std_logic;
  signal act_s  : std_logic;

begin

  snd_takt_p: process(cp_i, rb_i)
  begin
    if rb_i = '0' then
      snd_s <= '0';
      gen_s <= '0';
      en_s  <= '0';
      act_s <= '0';
      freq_s<= 0;
    elsif rising_edge(cp_i) then
    en_s <= en_i;
    
      if (en_i = '1' and en_s = '0') then
        act_s <= '1';
      elsif (en_i = '0' and en_s = '1') then
        act_s <= '0';
      end if;
      
        if freq_s < (freq_g/2)-1 then
          freq_s <= freq_s + 1;
        else
          freq_s <= 0;
          gen_s <= not gen_s;
        end if;
          
      
      if en_s = '1' then
        
        if sec_s < second_g-1 then
          sec_s <= sec_s + 1;
        else
          sec_s <= 0;
          if len_s < len_g-1 then
            len_s <= len_s + 1;
          else
            len_s <= 0;
            act_s <= '0';
          end if;
        end if;
        
      else
        snd_s <= '0';
        en_s <= '0';
      end if;
      
      if act_s = '1' then
        snd_s <= gen_s;
      else
        snd_s <= '0';
      end if;
      
    end if;
  end process;
  
  act_o <= act_s;  
  snd_o <= snd_s;

end sndV2_a;
