-- File name: top_level_tb.vhd
-- Description: testbench for the complete design.
-- Author: Marko Gjorgjievski
-- Date created: 01.07.2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.TEXTIO.all;

entity top_level_tb is
end entity;

architecture top_level_a of top_level_tb is

    component top_level_e is -- remember to accomodate for correct clock frequency in top_package.
        port (
            cp_pin : in std_logic;
            rb_pin : in std_logic;
            m0_pin : in std_logic;
            m1_pin : in std_logic;
            t0_pin : in std_logic;
            t1_pin : in std_logic;
            rxd_pin : in std_logic;
            ld1_pin : out std_logic; -- rb
            ld2_pin : out std_logic; -- heartbeat
            ld3_pin : out std_logic; -- m0_i
            ld4_pin : out std_logic; -- m1_i
            ld5_pin : out std_logic; -- t0_i
            ld6_pin : out std_logic; -- t1_i
            ld7_pin : out std_logic; -- txd
            ld8_pin : out std_logic; -- snd_active
            txd_pin : out std_logic;
            snd_pin : out std_logic
        );
    end component;

    constant clk_freq_c : integer := 27_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    signal cp_s : std_logic := '0';
    signal rb_s : std_logic := '0';
    signal m0_s : std_logic := '0';
    signal m1_s : std_logic := '0';
    signal t0_s : std_logic := '0';
    signal t1_s : std_logic := '0';
    signal rxd_s : std_logic := '1';
    signal ld1_s : std_logic;
    signal ld2_s : std_logic;
    signal ld3_s : std_logic;
    signal ld4_s : std_logic;
    signal ld5_s : std_logic;
    signal ld6_s : std_logic;
    signal ld7_s : std_logic;
    signal ld8_s : std_logic;
    signal snd_s : std_logic;
    signal txd_s : std_logic;

    constant baud_bit_period : time := 104.166 us;

    procedure UART_WRITE_BYTE (
        i_data_in : in std_logic_vector(7 downto 0);
        signal o_serial : out std_logic) is
    begin

        -- Send Start Bit
        o_serial <= '0';
        wait for baud_bit_period;

        -- Send Data Byte
        for ii in 0 to 7 loop
            o_serial <= i_data_in(ii);
            wait for baud_bit_period;
        end loop; -- ii

        -- Send Stop Bit
        o_serial <= '1';
        wait for baud_bit_period;
        wait for baud_bit_period; -- 2 Stop bits needed for 8N2.

    end UART_WRITE_BYTE;

    procedure UART_WRITE_TOA (
        i_hh_bcd : in std_logic_vector(7 downto 0); -- BCD: tens in [7:4], units in [3:0]
        i_mm_bcd : in std_logic_vector(7 downto 0);
        i_ss_bcd : in std_logic_vector(7 downto 0);
        signal o_serial : out std_logic) is

        -- local helper: BCD nibble -> ASCII digit
        function bcd_nibble_to_ascii(nib : std_logic_vector(3 downto 0)) return std_logic_vector is
        begin
            return std_logic_vector(to_unsigned(16#30#, 8) + resize(unsigned(nib), 8));
        end function;
    begin
        UART_WRITE_BYTE(x"0A", o_serial); -- LF
        UART_WRITE_BYTE(x"0D", o_serial); -- CR
        UART_WRITE_BYTE(x"45", o_serial); -- 'E'

        UART_WRITE_BYTE(bcd_nibble_to_ascii(i_ss_bcd(3 downto 0)), o_serial);
        UART_WRITE_BYTE(bcd_nibble_to_ascii(i_ss_bcd(7 downto 4)), o_serial);
        UART_WRITE_BYTE(x"3A", o_serial); -- ':'

        UART_WRITE_BYTE(bcd_nibble_to_ascii(i_mm_bcd(3 downto 0)), o_serial);
        UART_WRITE_BYTE(bcd_nibble_to_ascii(i_mm_bcd(7 downto 4)), o_serial);
        UART_WRITE_BYTE(x"3A", o_serial); -- ':'

        UART_WRITE_BYTE(bcd_nibble_to_ascii(i_hh_bcd(3 downto 0)), o_serial);
        UART_WRITE_BYTE(bcd_nibble_to_ascii(i_hh_bcd(7 downto 4)), o_serial);
    end UART_WRITE_TOA;

begin

    dut_top_level : top_level_e
    port map(
        cp_pin => cp_s,
        rb_pin => rb_s,
        m0_pin => m0_s,
        m1_pin => m1_s,
        t0_pin => t0_s,
        t1_pin => t1_s,
        rxd_pin => rxd_s,
        ld1_pin => ld1_s,
        ld2_pin => ld2_s,
        ld3_pin => ld3_s,
        ld4_pin => ld4_s,
        ld5_pin => ld5_s,
        ld6_pin => ld6_s,
        ld7_pin => ld7_s,
        ld8_pin => ld8_s,
        txd_pin => txd_s,
        snd_pin => snd_s
    );

    cp_s <= not cp_s after clk_period_c / 2;

    process is
    begin

        wait for 10 us;
        rb_s <= '1';
        wait until rising_edge(cp_s);

        -- Reset condition check --
        assert ld1_s = '1' report "Incorrect LED1 value: " & std_logic'image(ld1_s) severity error;
        assert ld2_s = '0' report "Incorrect LED2 value: " & std_logic'image(ld2_s) severity error;
        assert ld3_s = '1' report "Incorrect LED3 value: " & std_logic'image(ld3_s) severity error;
        assert ld4_s = '1' report "Incorrect LED4 value: " & std_logic'image(ld4_s) severity error;
        assert ld5_s = '1' report "Incorrect LED5 value: " & std_logic'image(ld5_s) severity error;
        assert ld6_s = '1' report "Incorrect LED6 value: " & std_logic'image(ld6_s) severity error;
        assert ld7_s = '1' report "Incorrect LED7 value: " & std_logic'image(ld7_s) severity error;
        assert ld8_s = '1' report "Incorrect LED8 value: " & std_logic'image(ld8_s) severity error;
        assert txd_s = '1' report "Incorrect UART-TX output!" severity error;
        assert snd_s = '0' report "Incorrect Sound value!" severity error;
        report "Reset condition test passed!";

        wait until rising_edge(cp_s);
        wait until rising_edge(cp_s);
        UART_WRITE_TOA(x"13", x"30", x"00", rxd_s);
        -- Repeatability test --

        -- report "Repeatability test passed!";
        wait for 2.1 min;

        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;