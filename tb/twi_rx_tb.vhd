-- File name : twi_rx_tb.vhd
-- Description : Three Wire Interface receiver testbench.
-- Author : Marko Gjorgjievski
-- Date created : 15.06.2026
-- TODO: Fix naming of some internal wiring.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity twi_rx_tb is
end entity;

architecture twi_rx_tb_a of twi_rx_tb is

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

    component twi_rx_e is
        port (
            cp_i        : in std_logic;
            rb_i        : in std_logic;
            stx_i       : in std_logic;
            sdv_i       : in std_logic;
            sdo_i       : in std_logic;      
            dv_o        : out std_logic;
            twi_byte_o  : out std_logic_vector(7 downto 0)
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
    signal tx_dv_s     : std_logic;

    signal twi_rx_byte_s : std_logic_vector(7 downto 0);
    signal dv_s        : std_logic;

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
        dv_o => tx_dv_s -- normally open, the DV comes from TWI receiver.
    );

    dut2 : twi_rx_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        stx_i => stx_s,
        sdv_i => sdv_s,
        sdo_i => sdo_s,
        dv_o => dv_s,
        twi_byte_o => twi_rx_byte_s
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
        wait until tx_dv_s = '1';
        assert twi_byte_s = twi_rx_byte_s report "Transmitted Bytes don't match." severity failure;

        -- Repeatability test --
        wait for 10 us;
        twi_byte_s <= X"55";
        twi_dv_s   <= '1';
        wait until rising_edge(cp_s);
        twi_dv_s   <= '0';
        wait until tx_dv_s = '1';
        -- Repeatability test --
        assert twi_byte_s = twi_rx_byte_s report "Transmitted Bytes don't match." severity failure;
        report "Repeatability test passed!";

        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;