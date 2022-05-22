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

