-- File name: snd.vhd
-- Description: sound module for brew finish.
-- Author: Marko Gjorgjievski
-- Date created: 22.10.2025
-- Date modified: 23.10.2025, Finished module.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity snd_e is

    generic(clk_freq_g : integer := 27_000_000;
            snd_freq_g : integer := 27_000; -- 1KHz Sound wave = clk_freq_g / snd_freq_g
            ring_dur_g : integer := 3 
    );
    port(cp_i       : in std_logic;
        rb_i        : in std_logic;
        snd_ena_i   : in std_logic;
        snd_o       : out std_logic
    );

end entity;

architecture snd_a of snd_e is

    constant ring_dur_c       : integer := clk_freq_g * ring_dur_g;
    constant snd_freq_c       : integer := clk_freq_g / (snd_freq_g * 2); -- multiply by a factor of 2 to get the half period where the signal changes.
    constant ring_dur_width_c : integer := 27; -- ceil(log2(27e6*3))
    constant snd_freq_width_c : integer := 15; 

    signal ring_counter_r   : unsigned(ring_dur_width_c-1 downto 0);
    signal snd_counter_r    : unsigned(snd_freq_width_c-1 downto 0);
    signal ena_ff, ena_ff2  : std_logic; -- 2FF Synchronizer
    signal snd_r            : std_logic;

    type snd_st is (IDLE, RINGING, DONE);
    signal fsm_r, fsm_next_w : snd_st;

    signal ring_ena_w : std_logic;
    signal done_r     : std_logic;

begin

    p_snd_generate: process(cp_i, rb_i)
    begin
        if rb_i = '0' then
            ena_ff          <= '0';
            ena_ff2         <= '0';
            snd_r           <= '0';
            done_r          <= '0';
            ring_counter_r  <= (others => '0');
            snd_counter_r   <= (others => '0');
        elsif rising_edge (cp_i) then
            ena_ff  <= snd_ena_i;
            ena_ff2 <= ena_ff;
            if ring_ena_w = '1' then
                if ring_counter_r < ring_dur_c then
                    done_r <= '0';
                    ring_counter_r <= ring_counter_r + 1;
                    if snd_counter_r < snd_freq_c then
                        snd_counter_r <= snd_counter_r + 1;
                    else
                        snd_counter_r <= (others => '0');
                        snd_r <= not snd_r;
                    end if;
                else
                    done_r         <= '1';
                    ring_counter_r <= (others => '0');
                    snd_counter_r  <= (others => '0');
                end if;
            else
                done_r         <= '0';
                ring_counter_r <= (others => '0');
                snd_counter_r  <= (others => '0');
            end if;
        end if;
    end process;

    p_fsm_clocked: process(cp_i, rb_i)
    begin
        if rb_i = '0' then
            fsm_r <= IDLE;
        elsif rising_edge (cp_i) then
            fsm_r <= fsm_next_w;
        end if;
    end process;

    p_fsm_transition: process (fsm_r, ena_ff2, done_r)
    begin
        fsm_next_w <= fsm_r;
        case fsm_r is
            when IDLE =>
                if ena_ff2 = '1' then
                    fsm_next_w <= RINGING;
                end if;
            when RINGING =>
                if done_r = '1' then
                    fsm_next_w <= DONE;
                end if;
            when DONE   => fsm_next_w <= IDLE;
            when others => fsm_next_w <= IDLE;
        end case;
    end process;

    p_fsm_output: process(fsm_r)
    begin
        ring_ena_w <= '0';
        case fsm_r is
            when IDLE    => null;
            when RINGING => ring_ena_w <= '1';
            when DONE    => null;
            when others  => ring_ena_w <= '0';
        end case;
    end process;

    snd_o <= snd_r;

end architecture;