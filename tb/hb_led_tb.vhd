-- File name: hb_led_tb.vhd
-- Description: heartbeat LED module testbench.
-- Author: Marko Gjorgjievski
-- Date created: 20.10.2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hb_led_tb is
end entity;

architecture hb_led_tb_a of hb_led_tb is

    component hb_led_e is

        generic(hb_halfperiod_g : natural := 500_000;
                counter_width_g : natural := 19);
        port (
            cp_i : in std_logic;
            rb_i : in std_logic;
            d_o : out std_logic);

    end component;

    constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    signal cp_s : std_logic := '0';
    signal rb_s : std_logic := '0';
    signal d_s : std_logic;

begin

    dut : hb_led_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        d_o => d_s
    );

    cp_s <= not cp_s after clk_period_c / 2;

    process is
    begin

        wait for 10 ms;
        rb_s <= '1';

        -- For ModelSIM no huge difference in simulation processing when it comes to 10ns to 1fs time resolution in real time margins (a few seconds).
        -- For 1fs time resolution at 27MHz, transition is 4.238ns behind assertion time.
        wait for 500 ms; -- Make sure time resolution is accurate enough, so that drift doesn't accumulate fast and assertion lands on right signal value.
        assert (d_s = '0') report "Wrong output, LED still on" severity error;

        wait for 1 ms;
        assert (d_s = '1') report "Wrong output, LED still off" severity error;

        -- Testing wait statement with until. Waits until event has occured.
        wait until falling_edge(d_s); 
        report "Hey." severity note;

        -- Waits on signal change to do report.
        wait on cp_s;
        report "Hey again." severity note;

        wait until falling_edge(d_s); 
        report "Again." severity note;

        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;