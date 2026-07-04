-- File name: snd_tb.vhd
-- Description: testbench for the sound module.
-- Author: Marko Gjorgjievski
-- Date created: 22.10.2025
-- Date modified: 23.10.2025, Finished module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity snd_tb_e is
end entity;

architecture snd_tb_a of snd_tb_e is

    component snd_e is

        generic(clk_freq_g : integer := 1_000_000;
                snd_freq_g : integer := 1000;
                ring_dur_g : integer := 1
        );
        port (cp_i        : in std_logic;
              rb_i        : in std_logic;
              snd_ena_i   : in std_logic;
              snd_o       : out std_logic
        );

    end component;

    constant clk_freq_c   : integer := 1_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    signal cp_s         : std_logic := '0';
    signal rb_s         : std_logic := '0';
    signal snd_ena_s    : std_logic := '0';
    signal snd_s        : std_logic := '0';

begin

    dut : snd_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        snd_ena_i => snd_ena_s,
        snd_o => snd_s
    );

    cp_s <= not cp_s after clk_period_c / 2;

    process is
    begin

        wait for 10 ms;
        rb_s <= '1';
        wait until rising_edge(cp_s);
        snd_ena_s <= '1';
        wait until rising_edge(cp_s);
        snd_ena_s <= '0';
        wait for 1050 ms; -- Make sure time res is 100ns.
        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;