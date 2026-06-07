-- File name: debounce_tb.vhd
-- Description: testbench for the button debounce module.
-- Author: Marko Gjorgjievski
-- Date created: 22.10.2025
-- Date modified: 08.06.2026
-- Recent changes: Update to assertions and naming conventions.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce_tb_e is
end entity;

architecture debounce_tb_a of debounce_tb_e is

    component debounce_e is

        generic(clk_freq_g : integer := 1_000_000;
                db_freq_g  : integer := 1000 -- finds closest power of 2 to divide clock for closest 100Hz simulation.
        );
        port (cp_i        : in std_logic;
              rb_i        : in std_logic;
              btn_i       : in std_logic;
              btn_o       : out std_logic
        );

    end component;

    constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    signal cp_s          : std_logic := '0';
    signal rb_s          : std_logic := '0';
    signal btn_si        : std_logic := '0';
    signal btn_so        : std_logic := '0';
    signal tick_s        : std_logic := '0';

begin

    dut : debounce_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        btn_i => btn_si,
        btn_o => btn_so
    );

    cp_s <= not cp_s after clk_period_c / 2;

    process is
    begin

        wait for 1 ms;
        rb_s <= '1';

        wait for 500 us;
        btn_si <= '1';
        
        wait for 5 ms;
        assert btn_so = '1' report "Debounce fail" & std_logic'image(btn_so) severity failure;

        wait for 1 ms;
        btn_si <= '0';

        wait for 1 ms;
        btn_si <= '1';
        wait for 5 ms;
        assert btn_so = '1' report "Debounce fail" & std_logic'image(btn_so) severity failure;
        
        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;