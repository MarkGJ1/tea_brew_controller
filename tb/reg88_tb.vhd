-- File name: reg88_tb.vhd
-- Description: reg88 testbench using UART-RX.
-- Author: Marko Gjorgjievski
-- Date created: 08.06.2026
-- Date modified: 13.06.2026
-- Recent changes: removed testing for TX features.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg88_tb is
end entity;

architecture reg88_tb_a of reg88_tb is

	component reg88_e is
		port (
            cp_i     : in std_logic;
            rb_i     : in std_logic;
            rx_dv_i  : in std_logic;
            byte_i   : in std_logic_vector(7 downto 0);
            reg88_o  : out std_logic_vector(87 downto 0); -- "xx:xx:xxE<CR><LF>" - 11x8 - 11 Bytes
            rx_dv_o  : out std_logic
    );
	end component;

    component uart_rx_e is
		generic (
			baud_rate_g : integer := 104 -- 1MHz / 9600 = 104.16 ~ 104 us.
		);
		port (
			cp_i : in std_logic;
			rb_i : in std_logic;
			rxd_i : in std_logic;
			rx_dv_o : out std_logic;
			rx_byte_o : out std_logic_vector(7 downto 0)
		);
	end component;

	constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
	constant clk_period_c : time := 1000 ms/clk_freq_c;

	constant baud_bit_period  : time := 104.166 us;
    constant baud_byte_period : time := baud_bit_period * 11;

	signal cp_s         : std_logic := '0';
	signal rb_s         : std_logic := '0';
	signal rxd_s        : std_logic := '1';
	signal rx_dv_s      : std_logic;
	signal rx_byte_s    : std_logic_vector (7 downto 0);

    signal reg88_s      : std_logic_vector(87 downto 0);
    signal wr_ubyte_s   : unsigned(7 downto 0) := X"0A";
    signal wr_vbyte_s   : std_logic_vector(7 downto 0) := X"0A";

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

begin

	dut1 : uart_rx_e
	port map(
		cp_i => cp_s,
		rb_i => rb_s,
		rxd_i => rxd_s,
		rx_dv_o => rx_dv_s,
		rx_byte_o => rx_byte_s
	);

    dut2 : reg88_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        rx_dv_i => rx_dv_s,
        byte_i => rx_byte_s,
        reg88_o => reg88_s,
        rx_dv_o => open
    );

	cp_s <= not cp_s after clk_period_c / 2;

	process is
	begin

		wait for 100 us;
		rb_s <= '1';

		wait until rising_edge(cp_s);
		wait until rising_edge(cp_s);
		UART_WRITE_BYTE(X"3F", rxd_s);
		wait until rising_edge(cp_s);

		assert rx_byte_s = X"3F" report "Test Failed - Incorrect Byte Received" severity failure;
		--report "RX-Byte received: " & std_logic_vector'image(rx_byte_s) severity note;
		--Only supported by VHDL 2019 (my ModelSim is not compatible).

		wait for 100 us;

		wait until rising_edge(cp_s);
		wait until rising_edge(cp_s);
		UART_WRITE_BYTE(X"AA", rxd_s);
		wait until rising_edge(cp_s);

		assert rx_byte_s = X"AA" report "Test Failed - Incorrect Byte Received" severity failure;
		--report "RX-Byte received: " & std_logic_vector'image(rx_byte_s) severity note;

		wait for 100 us;

        -- Sending over 9 remaining bytes to saturate reg88.
        ------------------------------------------------------
        for ii in 0 to 8 loop
            wr_ubyte_s <= wr_ubyte_s + 1;
            wr_vbyte_s <= std_logic_vector(wr_ubyte_s);
            UART_WRITE_BYTE(wr_vbyte_s, rxd_s);
        end loop;
        ------------------------------------------------------
        assert reg88_s = X"1211100F0E0D0C0B0AAA3F" report "Incorrect register byte sequence received" severity note; -- TODO: Fix this sequence.
        -- Transmission test
        ------------------------------------------------------

		-- Test end.
		-- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
		report "Test Complete" severity failure;

	end process;

end architecture;