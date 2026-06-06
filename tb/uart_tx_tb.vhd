-- File name: snd_tb.vhd
-- Description: testbench for the sound module.
-- Author: Marko Gjorgjievski
-- Date created: 22.10.2025
-- Date modified: 23.10.2025, Finished module.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_tb is
end entity;

architecture uart_tx_tb_a of uart_tx_tb is

    component uart_tx_e is
    generic(
        baud_rate  : integer := 104 -- 27MHz / 9600 baud = 104.16 us
    );
    port (
        cp_i            : in std_logic;
        rb_i            : in std_logic;
        tx_dv_i         : in std_logic;
        tx_byte_i       : in std_logic_vector (7 downto 0);
        tx_serial_o     : out std_logic;
        tx_done_o       : out std_logic
    );
    end component;

    constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    -- constant baud_bit_period : time := 104.166 us;

    signal cp_s        : std_logic := '0';
    signal rb_s        : std_logic := '0';
    signal tx_dv_s     : std_logic := '0';
    signal tx_byte_s   : std_logic_vector (7 downto 0) := (others => '0');
    signal tx_serial_s : std_logic;
    signal tx_done_s   : std_logic;

begin

    dut : uart_tx_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        tx_dv_i => tx_dv_s,
        tx_byte_i => tx_byte_s,
        tx_serial_o => tx_serial_s,
        tx_done_o => tx_done_s
    );

    cp_s <= not cp_s after clk_period_c / 2;

    process is
    begin

        wait for 100 us;
        rb_s <= '1';

        wait until rising_edge(cp_s);
        tx_byte_s <= X"AB"; -- Byte to be transmitted.
        wait until rising_edge(cp_s);
        tx_dv_s   <= '1'; -- Byte valid, start transmit.

        wait for 52 us; -- baud_rate / 2 to assert at middle of bit.

        assert tx_serial_s = '0' report "Start bit missing." severity error;

        wait for 104 us;

        for ii in 0 to 7 loop -- Assert loop for every bit transmitted.
            report "Current bit is " & std_logic'image(tx_serial_s) & " ." severity note;
            assert tx_serial_s = tx_byte_s(ii) report "Incorrect bit. Bit = " & std_logic'image(tx_serial_s) severity error;
            wait for 104 us;
        end loop;

        for ii in 0 to 1 loop -- Stop bit check loop.
            assert tx_serial_s = '1' report "Stop bit missing." severity error;
            wait for 104 us;
        end loop;

        
        wait until rising_edge(cp_s);
        tx_dv_s   <= '0';
        wait until tx_done_s = '1';

        -- Second test transmission to check if UART blocks.
        ---------------------------------------------------------------
        wait for 200 us;
        tx_byte_s <= X"FF";
        wait until rising_edge(cp_s);
        tx_dv_s   <= '1';
        wait until rising_edge(cp_s);
        tx_dv_s   <= '0';
        wait until tx_done_s = '1';
        
        wait for 50 us;
        ---------------------------------------------------------------

        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;