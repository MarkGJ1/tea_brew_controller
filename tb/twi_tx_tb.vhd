-- File name : twi_tx_tb.vhd
-- Description : Three Wire Interface transmitter testbench.
-- Author : Marko Gjorgjievski
-- Date created : 14.06.2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity twi_tx_tb is
end entity;

architecture twi_tx_tb_a of twi_tx_tb is

    component twi_tx_e is
        generic(
            data_rate_g  : integer := 1_000 -- 1MHz / 1000 = 1000
        );
        port (
            cp_i        : in std_logic;
            rb_i        : in std_logic;
            twi_dv_i    : in std_logic;
            twi_byte_i  : in std_logic_vector(7 downto 0);
            stx_o       : out std_logic;
            sdv_o       : out std_logic;
            sdo_o       : out std_logic;
            dv_o        : out std_logic      
        );
    end component;

    constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    -- constant baud_bit_period : time := 104.166 us;

    signal cp_s        : std_logic := '0';
    signal rb_s        : std_logic := '0';
    signal twi_dv_s    : std_logic := '0';
    signal twi_byte_s  : std_logic_vector(7 downto 0) := (others => '0');
    signal stx_s       : std_logic;
    signal sdv_s       : std_logic;
    signal sdo_s       : std_logic;
    signal dv_s        : std_logic;
    
    procedure UART_READ_BYTE( -- TODO (Maybe): Change for TWI-TX Testing.
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

    dut : twi_tx_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        twi_dv_i => twi_dv_s,
        twi_byte_i => twi_byte_s,
        stx_o => stx_s,
        sdv_o => sdv_s,
        sdo_o => sdo_s,
        dv_o => dv_s
    );

    cp_s <= not cp_s after clk_period_c / 2;

    process is
    begin

        wait for 10 us;
        rb_s <= '1';
        -- Reset condition check --
        assert stx_s = '0' report "Serial output not reset!" severity failure;
        assert sdv_s = '0' report "Data valid not reset!" severity failure;
        assert sdo_s = '0' report "Data not reset!" severity failure;
        assert dv_s = '0' report "Byte done not reset!" severity failure;
        -- Reset condition check --
        report "Reset condition test passed!";

        wait until rising_edge(cp_s);
        twi_byte_s <= X"AA"; -- Byte to be transmitted.
        twi_dv_s   <= '1'; -- Byte valid, start transmit.
        wait until rising_edge(cp_s);
        twi_dv_s   <= '0';
        wait until dv_s = '1';

        -- Repeatability test --
        wait for 10 us;
        twi_byte_s <= X"55";
        twi_dv_s   <= '1';
        wait until rising_edge(cp_s);
        twi_dv_s   <= '0';
        wait until dv_s = '1';
        -- Repeatability test --
        report "Repeatability test passed!";

        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;