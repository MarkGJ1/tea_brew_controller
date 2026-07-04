-- File name: button_debounce.vhd
-- Description: Button debouncer for start brew (sensor) and timer mode shifter.
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: 08.06.2026
-- Recent changes: Update to naming convetion.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce_e is

    generic(
        clk_freq_g : integer := 27_000_000;
        db_freq_g  : integer := 54_000 -- min. 2ms debounce
    );
    port(
        cp_i    : in std_logic;
        rb_i    : in std_logic;
        btn_i   : in std_logic;
        btn_o   : out std_logic
    );

end entity;

architecture debounce_a of debounce_e is
    
    constant db_freq_width_c : integer := 19; -- ceil(log2(clk/db))
    constant db_freq_count_c : integer := clk_freq_g / db_freq_g;

    signal tick_db_r : unsigned (db_freq_width_c-1 downto 0); -- Counter register.
    signal tick_en_r : std_logic; -- Counter enable.
    signal delay1_r, delay2_r, delay3_r : std_logic;

begin

    debounce: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            delay1_r  <= '0';
            delay2_r  <= '0';
            delay3_r  <= '0';
            tick_en_r <= '0';
            tick_db_r <= (others => '0');
        elsif rising_edge(cp_i) then
            if tick_db_r < db_freq_count_c then
                tick_db_r <= tick_db_r + 1;
                tick_en_r <= '0';
            else
                tick_db_r <= (others => '0');
                tick_en_r <= '1';
            end if;
            if tick_en_r = '1' then
                delay1_r <= btn_i;
                delay2_r <= delay1_r;
                delay3_r <= delay2_r;
            end if;
        end if;
    end process;

    btn_o <= delay1_r and delay2_r and delay3_r;

end architecture;