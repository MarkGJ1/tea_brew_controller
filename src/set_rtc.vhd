-- File name: set_rtc.vhd
-- Description: Decode the incoming bytes from TWI-TX, set the RTC and start brewing timer.
-- Author: Marko Gjorgjievski
-- Date created: 19.06.2026

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity set_rtc_e is

	port (
		cp_i        : in std_logic;
        rb_i        : in std_logic;
        dv_i        : in std_logic;
        twi_byte_i  : in std_logic_vector(7 downto 0);
        rtc_dv_o    : out std_logic;             -- UPDATE command
        tim_dv_o    : out std_logic;             -- Brew start
        rtc_o       : out unsigned(16 downto 0)  -- New time
    );

end entity;

architecture set_rtc_a of set_rtc_e is

    -- Input capturing registers
    signal dv_r       : std_logic;
    signal sec_r      : unsigned(6 downto 0);  -- 0-59
    signal min_r      : unsigned(6 downto 0);  -- 0-59
    signal hour_r     : unsigned(4 downto 0);  -- 0-23

    -- Output registers
    signal rtc_r      : unsigned(16 downto 0);
    signal rtc_dv_r   : std_logic;
    signal tim_dv_r   : std_logic;

    -- Internal counting logic
    signal byte_idx_r : integer range 0 to 3; -- x"45_xx_xx_xx"

begin

    p_sample: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            dv_r       <= '0';
            rtc_dv_r   <= '0';
            tim_dv_r   <= '0';
            rtc_r      <= (others => '0');
            sec_r      <= (others => '0');
            min_r      <= (others => '0');
            hour_r     <= (others => '0');
        elsif rising_edge(cp_i) then
            dv_r    <= dv_i;
            if dv_r = '1' then
                if byte_idx_r < 3 then
                    byte_idx_r <= byte_idx_r + 1;
                else
                    byte_idx_r <= 0;
                    rtc_dv_r   <= '0';
                    tim_dv_r   <= '0';
                end if;

                case byte_idx_r is
                    when 0 =>
                        sec_r <= resize(
                            to_unsigned(10, 4) * unsigned(twi_byte_i(7 downto 4))
                            + unsigned(twi_byte_i(3 downto 0)), 7);

                    when 1 =>
                        min_r <= resize(
                            to_unsigned(10, 4) * unsigned(twi_byte_i(7 downto 4))
                            + unsigned(twi_byte_i(3 downto 0)), 7);

                    when 2 =>
                        hour_r <= resize(
                            to_unsigned(10, 4) * unsigned(twi_byte_i(7 downto 4))
                            + unsigned(twi_byte_i(3 downto 0)), 5);
                        -- compose now using inline decoded hour + already-registered min/sec
                    when 3 =>
                        rtc_r <= resize(
                            resize(hour_r, 17) * to_unsigned(3600, 12)         -- 12 bits covers 0..3600
                            + resize(min_r, 17) * to_unsigned(60, 6)
                            + resize(sec_r, 17), 17);
                        rtc_dv_r <= '1';
                    when others => null;
                end case;

                if twi_byte_i = x"45" then
                    tim_dv_r <= '1';
                end if;
            else
                rtc_dv_r   <= '0';
                tim_dv_r   <= '0';
            end if;
        end if;
    end process;

    rtc_dv_o <= rtc_dv_r;
    tim_dv_o <= tim_dv_r;
    rtc_o    <= rtc_r;

end architecture;