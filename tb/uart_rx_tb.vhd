-- File name: uart_rx_tb.vhd
-- Description: UART RX Testbench
-- Author: Marko Gjorgjievski
-- Date created: 22.10.2025
-- Date modified: 07.06.2026
-- Recent changes: Better assertion test process.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx_tb is
end entity;

architecture uart_rx_tb_a of uart_rx_tb is

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

	constant baud_bit_period : time := 104.166 us;

	signal cp_s : std_logic := '0';
	signal rb_s : std_logic := '0';
	signal rxd_s : std_logic := '1';
	signal rx_dv_s : std_logic;
	signal rx_byte_s : std_logic_vector (7 downto 0);

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

	dut : uart_rx_e
	port map(
		cp_i => cp_s,
		rb_i => rb_s,
		rxd_i => rxd_s,
		rx_dv_o => rx_dv_s,
		rx_byte_o => rx_byte_s
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

		-- Test end.
		-- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
		report "Test Complete" severity failure;

	end process;

end architecture uart_rx_tb_a;