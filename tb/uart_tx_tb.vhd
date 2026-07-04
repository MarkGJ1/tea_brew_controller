-- File name: uart_tx_tb.vhd
-- Description: UART TX Testbench
-- Author: Marko Gjorgjievski
-- Date created: 22.10.2025
-- Date modified: 14.06.2026
-- Recent changes: Added the UART-TX assessmenent procedural block. New comments.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_tb is
end entity;

architecture uart_tx_tb_a of uart_tx_tb is

    component uart_tx_e is
        generic(
            baud_rate_g  : integer := 104 -- 1MHz / 9600 = 104,16 ~ 104.
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

    procedure UART_READ_BYTE(
        signal   tx_serial    : std_logic;
        constant tx_byte      : std_logic_vector(7 downto 0)
    ) is
    begin
        wait for 52 us; -- baud_rate / 2 to assert at middle of bit.
        assert tx_serial = '0' report "Start bit missing." severity error;
        wait for 104 us;

        for ii in 0 to 7 loop -- Assert loop for every bit transmitted.
            report "Current bit is " & std_logic'image(tx_serial) & " ." severity note;
            assert tx_serial = tx_byte(ii) report "Incorrect bit. Bit = " & std_logic'image(tx_serial) severity error;
            wait for 104 us;
        end loop;

        for ii in 0 to 1 loop -- Stop bit check loop.
            assert tx_serial = '1' report "Stop bit missing." severity error;
            wait for 104 us;
        end loop;
    end procedure;

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
        -- Should probably implement a initial condition test
        -- alongside filled initial statements instead of tying
        -- everything to a reset signal because of the huge fanout.
        -- This will probably be done in future designs.
        wait for 100 us;
        rb_s <= '1';
        -- Reset condition check --
        assert tx_serial_s = '1' report "Serial output not reset!" severity failure;
        assert tx_serial_s = '0' report "Data valid not reset!" severity failure;
        -- Reset condition check --

        wait until rising_edge(cp_s);
        tx_byte_s <= X"AA"; -- Byte to be transmitted.
        wait until rising_edge(cp_s);
        tx_dv_s   <= '1'; -- Byte valid, start transmit.
        wait until rising_edge(cp_s);
        tx_dv_s   <= '0';
        UART_READ_BYTE(tx_serial_s, tx_byte_s);
        wait until tx_done_s = '1';

        -- Repeatability test --
        wait for 10 us;
        tx_byte_s <= X"55";
        wait until rising_edge(cp_s);
        tx_dv_s   <= '1';
        wait until rising_edge(cp_s);
        tx_dv_s   <= '0';
        UART_READ_BYTE(tx_serial_s, tx_byte_s);
        wait until tx_done_s = '1';
        -- Repeatability test --

        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;