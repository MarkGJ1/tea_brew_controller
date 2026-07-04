-- File name: snd_new.vhd
-- Description: sound module for brew finish.
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: /

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity snd_e is

    generic(
        clk_freq_g : natural := 27_000_000;
        ring_dur_g : natural := 3;
        snd_freq_g : natural := 1000
    );
    port (
        cp_i        : in std_logic;
        rb_i        : in std_logic;
        snd_done_i  : in std_logic;
        snd_o       : out std_logic
    );

end entity;

architecture snd_a of snd_e is

    constant ring_dur_c         : natural := clk_freq_g / ring_dur_g;
    constant snd_freq_c         : natural := clk_freq_g / snd_freq_g;
    constant ring_dur_width_c   : natural := natural(ceil(log2(real(ring_dur_c))));
    constant snd_freq_width_c   : natural := natural(ceil(log2(real(snd_freq_c))));

    signal ring_counter_s   : unsigned(ring_dur_width_c-1 downto 0);
    signal snd_counter_s    : unsigned(snd_freq_width_c-1 downto 0);
    signal snd_s            : std_logic;
    signal ring_done_s      : std_logic;

    -- snd_done_i will push snd into RINGING state
    -- state will last ring_dur_c.
    type snd_st is (IDLE, RINGING, DONE);
    signal snd_fsm, snd_fsm_next : snd_st;

begin

    snd_generate: process(cp_i, rb_i)
    begin
        if rb_i = '0' then
            ring_counter_s <= (others => '0');
            snd_counter_s  <= (others => '0');
            snd_fsm <= IDLE;
            ring_done_s <= '0';
            snd_s <= '0';
        elsif rising_edge (cp_i) then
            snd_fsm <= snd_fsm_next;    
            case (snd_fsm) is
                when IDLE =>
                    ring_counter_s <= (others => '0');
                    snd_counter_s  <= (others => '0');
                when RINGING =>
                    if ring_counter_s < to_unsigned(ring_dur_c, ring_counter_s'length) then
                        ring_counter_s <= ring_counter_s + 1;
                        ring_done_s <= '0';
                    else
                        ring_counter_s <= (others => '0');
                        ring_done_s <= '1';
                    end if;

                    if snd_counter_s < to_unsigned(snd_freq_c, snd_counter_s'length) then
                        snd_counter_s <= snd_counter_s + 1;
                    else
                        snd_counter_s <= (others <= '0');
                        snd_s <= not snd_s;
                    end if;
            end case;
        end if;
    end process;

    transition: process (snd_fsm, snd_done_i, ring_done_s)
    begin
        snd_fsm_next <= snd_fsm;
        case (snd_fsm) is
            when IDLE =>
                if snd_done_i = '1' then
                    snd_fsm_next <= RINGING;
                else
                    snd_fsm_next <= IDLE;
                end if;

            when RINGING =>
                if ring_done_s <= '1'
                    snd_fsm_next <= DONE;
                else
                    snd_fsm_next <= RINGING;
                end if;

            when DONE =>
                snd_fsm_next <= IDLE;
        end case;

    end process;

    fsm_output: process (snd_fsm)
    begin
        case (snd_fsm) is
            when IDLE =>
            when RINGING =>
            when DONE =>
        end case;
    end process;

end architecture;