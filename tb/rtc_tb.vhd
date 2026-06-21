-- File name: uart_rx_tb.vhd
-- Description: UART RX Testbench
-- Author: Marko Gjorgjievski
-- Date created: 22.10.2025
-- Date modified: 07.06.2026
-- Recent changes: Better assertion test process.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rtc_tb is
end entity;

architecture rtc_tb_a of rtc_tb is

	component rtc_e is
		generic(
            clk_freq_c : integer := 1_000_000
        );
        port (
            cp_i            : in std_logic;
            rb_i            : in std_logic;
            upd_i           : in std_logic;
            upd_time_i      : in unsigned(16 downto 0);
            RTC_o           : out unsigned(16 downto 0)
        );
	end component;

	constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
	constant clk_period_c : time := 1000 ms/clk_freq_c;

	signal cp_s         : std_logic := '0';
	signal rb_s         : std_logic := '0';
    signal upd_s        : std_logic := '0';
    signal upd_time_s   : unsigned(16 downto 0):= (others => '0');
    signal RTC_s        : unsigned(16 downto 0);

begin

	dut : rtc_e
	port map(
		cp_i        => cp_s,
		rb_i        => rb_s,
        upd_i       => upd_s,
        upd_time_i  => upd_time_s,
        RTC_o       => RTC_s
	);

	cp_s <= not cp_s after clk_period_c / 2;

	process is
	begin

		wait for 10 us;
		rb_s <= '1';
        assert RTC_s = x"0" report "RTC not reset!" severity failure;

        wait for 1050 ms;

        wait until rising_edge(cp_s);
        upd_time_s <= to_unsigned(48_600, 17); -- 13:30:00 = 13*3600 + 30*60 = 48_600
        upd_s      <= '1';
        wait until rising_edge(cp_s);
        upd_s      <= '0';
        wait until rising_edge(cp_s);
        wait until rising_edge(cp_s); -- falling edge of upd_r is where it updates.
        assert RTC_s = upd_time_s report "Incorrect time 1." severity failure;
        
        wait for 2001 ms;
        assert RTC_s = (upd_time_s + 2) report "Incorrect time 1.5." severity failure;

        wait until rising_edge(cp_s);
        upd_time_s <= to_unsigned(86_398, 17);
        upd_s      <= '1';
        wait until rising_edge(cp_s);
        upd_s      <= '0';
        wait until rising_edge(cp_s);
        wait until rising_edge(cp_s);
        assert RTC_s = to_unsigned(86_398, 17) report "Incorrect time 2." severity failure;

        wait for 2001 ms;
        assert RTC_s = to_unsigned(1, 17) report "Incorrect time 3." severity failure;
		-- Test end.
		-- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
		report "Test Complete" severity failure;

	end process;

end architecture;