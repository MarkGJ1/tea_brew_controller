-- File name: time_check.vhd
-- Description: Control signals to indicate brew start/finish.
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: /

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_e is

    port (
        cp_i            : in std_logic;
        rb_i            : in std_logic;
        t0_i            : in std_logic;
        t1_i            : in std_logic;
        rtc_i           : in unsigned(16 downto 0);
        brew_ena_i      : in std_logic;
        min_pass_o      : out std_logic;
        guess_o         : out std_logic;
        done_o          : out std_logic
    );

end entity;

architecture timer_a of timer_e is

    -- Minute constants
    -- constant one_min_c  : unsigned(5 downto 0) := 60;
    constant two_min_c  : unsigned(8 downto 0) := to_unsigned(120, 9);
    constant thr_min_c  : unsigned(8 downto 0) := to_unsigned(180, 9);
    constant fou_min_c  : unsigned(8 downto 0) := to_unsigned(240, 9);
    constant fiv_min_c  : unsigned(8 downto 0) := to_unsigned(300, 9);
    constant guess_c    : unsigned(8 downto 0) := to_unsigned(10,  9);

    -- Input registers
    signal rtc_r        : unsigned(16 downto 0);
    signal rtc_old_r    : unsigned(16 downto 0);
    signal brew_ena_r   : std_logic;
    signal brew_act_r   : std_logic;

    -- Output registers
    signal min_pass_r   : std_logic;
    signal guess_r      : std_logic;
    signal done_r       : std_logic;

    -- Brew time select wires
    signal brew_sel_w   : std_logic_vector(1 downto 0);
    signal brew_time_w  : unsigned(8 downto 0);
    signal brew_time_r  : unsigned(8 downto 0);

    -- Internal counting logic
    signal min_cnt_r    : integer range 0 to 59;
    signal total_cnt_r  : integer range 0 to 299;

begin

    brew_sel_w <= t0_i & t1_i;

    with brew_sel_w select
    brew_time_w <= two_min_c when "00",
                   thr_min_c when "01",
                   fou_min_c when "10",
                   fiv_min_c when "11",
                   two_min_c when others;

    p_compare: process(rb_i, cp_i)
        variable rtc_changed_v  : boolean;
    begin
        if rb_i = '0' then
            rtc_r        <= (others => '0');
            rtc_old_r    <= (others => '0');
            brew_time_r  <= (others => '0');
            min_cnt_r    <= 0;
            total_cnt_r  <= 0;
            brew_ena_r   <= '0';
            brew_act_r   <= '0';
            min_pass_r   <= '0';
            guess_r      <= '0';  
            done_r       <= '0';  
        elsif rising_edge(cp_i) then
            brew_ena_r   <= brew_ena_i;
            rtc_r        <= rtc_i;
            rtc_old_r    <= rtc_r;

            if brew_ena_r = '1' then
                brew_act_r  <= '1';
                brew_time_r <= brew_time_w;
                total_cnt_r <= 0;
                min_cnt_r   <= 0;
                done_r      <= '0';
            end if;            

            rtc_changed_v := not std_match(rtc_r, rtc_old_r);

            if min_cnt_r >= 59 and rtc_changed_v then
                min_pass_r <= '1';
            else
                min_pass_r <= '0';
            end if;

            if brew_act_r = '1' then
                if rtc_changed_v then
                    if min_cnt_r < 59 then
                        min_cnt_r <= min_cnt_r + 1;
                    else
                        min_cnt_r   <= 0;
                    end if;

                    if total_cnt_r < brew_time_r-1 then
                        total_cnt_r <= total_cnt_r + 1;
                        done_r      <= '0';
                    else
                        min_pass_r  <= '0';
                        total_cnt_r <= 0;
                        done_r      <= '1';
                        brew_act_r  <= '0';
                    end if;
                end if;
            else
                min_cnt_r   <= 0;
                total_cnt_r <= 0;
                min_pass_r  <= '0';
                done_r      <= '0';
                guess_r     <= '0';
            end if;

            if total_cnt_r = (brew_time_r-1-guess_c) and rtc_changed_v then
                guess_r <= '1';
            else
                guess_r <= '0';
            end if;
        end if;
    end process;

    min_pass_o  <= min_pass_r;
    guess_o     <= guess_r;
    done_o      <= done_r;

end architecture;