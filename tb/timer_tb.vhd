-- File name : twi_rx_tb.vhd
-- Description : Three Wire Interface receiver testbench.
-- Author : Marko Gjorgjievski
-- Date created : 15.06.2026
-- TODO: Fix naming of some internal wiring.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_tb is
end entity;

architecture timer_tb_a of timer_tb is

    component rtc_e is
        generic(
            clk_freq_c : integer := 1_000
        );
        port (
            cp_i            : in std_logic;
            rb_i            : in std_logic;
            upd_i           : in std_logic;
            upd_time_i      : in unsigned(16 downto 0);
            RTC_o           : out unsigned(16 downto 0)
        );
    end component;

    component timer_e is
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
    end component;

    component snd_e is -- Testing duration of ringing.
        generic(clk_freq_g : integer := 1_000_000;
                snd_freq_g : integer := 1_000; -- 10KHz Sound wave = clk_freq_g / snd_freq_g
                ring_dur_g : integer := 5 
        );
        port(cp_i       : in std_logic;
            rb_i        : in std_logic;
            snd_ena_i   : in std_logic;
            snd_o       : out std_logic
        );
    end component;

    constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    -- Globals
    signal cp_s        : std_logic := '0';
    signal rb_s        : std_logic := '0';

    -- RTC connecting wires
    signal upd_s       : std_logic := '0';
    signal upd_time_s  : unsigned(16 downto 0) := (others => '0');

    -- Interconnects
    signal rtc_s       : unsigned(16 downto 0);

    -- Timer connecting wires
    signal t0_s        : std_logic := '0';
    signal t1_s        : std_logic := '0';
    signal brew_ena_s  : std_logic := '0';
    signal min_pass_s  : std_logic;
    signal guess_s     : std_logic;
    signal done_s      : std_logic;

    signal snd_s       : std_logic;

begin

    dut: rtc_e
	port map(
		cp_i        => cp_s,
		rb_i        => rb_s,
        upd_i       => upd_s,
        upd_time_i  => upd_time_s,
        RTC_o       => rtc_s
	);
    
    dut2: timer_e
    port map(
        cp_i        => cp_s,
		rb_i        => rb_s,
        t0_i        => t0_s,
        t1_i        => t1_s,
        rtc_i       => rtc_s,
        brew_ena_i  => brew_ena_s,
        min_pass_o  => min_pass_s,
        guess_o     => guess_s,
        done_o      => done_s
    );

    dut3_snd: snd_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        snd_ena_i => done_s,
        snd_o => snd_s
    );

    cp_s <= not cp_s after clk_period_c / 2;

    process is
    begin

        wait for 10 ms;
        rb_s <= '1';
        -- Reset condition check --
        assert rtc_s = x"0" report "RTC not reset!" severity failure;
        assert min_pass_s = '0' report "Min-pass control not reset!" severity failure;
        assert guess_s = '0' report "Guess control not reset!" severity failure;
        assert done_s = '0' report "Done control not reset!" severity failure;
        -- Reset condition check --
        report "Reset condition test passed!";

        wait until rising_edge(cp_s);
        upd_s       <= '1';
        upd_time_s  <= to_unsigned(48_600, 17);
        wait until rising_edge(cp_s);
        upd_s       <= '0';
        wait until rising_edge(cp_s);
        brew_ena_s  <= '1';
        wait until rising_edge(cp_s);
        brew_ena_s  <= '0';
        wait until rising_edge(cp_s);

        wait until done_s = '1';

        wait for 20 ms;
        wait until rising_edge(cp_s);
        t0_s        <= '0';
        t1_s        <= '1';
        brew_ena_s  <= '1';
        wait until rising_edge(cp_s);
        brew_ena_s  <= '0';
        wait until rising_edge(cp_s);

        wait for 2 min;

        --wait until done_s = '1';

        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;