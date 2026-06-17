-- File name: RTC.vhd
-- Description: Real Time Clock module.
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: 15.06.2026

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rtc_e is

    generic(
        clk_freq_c : integer := 27_000_000
    );
    port (
        cp_i            : in std_logic;
        rb_i            : in std_logic;
        upd_i           : in std_logic;
        upd_time_i      : in unsigned(16 downto 0);
        RTC_o           : out unsigned(16 downto 0)
    );

end entity;

architecture rtc_a of rtc_e is

    constant hr_wrap_c : unsigned(16 downto 0) := to_unsigned(86399, 17);

    signal RTC_r         : unsigned(16 downto 0);
    signal PPS_r         : unsigned(24 downto 0);

begin

    p_rtc: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            RTC_r <= (others => '0');
            PPS_r <= (others => '0');
        elsif rising_edge(cp_i) then
            if PPS_r < clk_freq_c then
                PPS_r <= PPS_r + 1;
            else
                RTC_r <= RTC_r + 1;
                PPS_r <= (others => '0');
            end if;

            if RTC_r >= hr_wrap_c then
                RTC_r <= (others => '0'); -- Need to wrap around 24H.
            end if;

            if upd_i = '1' then -- Must be a single strobe.
                RTC_r <= upd_time_i; -- Last signal assignment of RTC wins. Update takes priority.
            end if;
        end if;
    end process;

    RTC_o <= RTC_r;

end architecture;