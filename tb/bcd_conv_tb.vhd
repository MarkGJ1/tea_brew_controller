-- File name: bcd_conv_tb.vhd
-- Description: bcd_conv testbench using UART-TX.
-- Author: Marko Gjorgjievski
-- Date created: 08.06.2026
-- Date modified: 14.06.2026
-- Recent changes: UART-TX assessment procedural block. Testing procedure comments.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_conv_tb is
end entity;

architecture bcd_conv_tb_a of bcd_conv_tb is

	component bcd_conv_e is
		port(
            cp_i     : in std_logic;
            rb_i     : in std_logic;
            dv_i     : in std_logic;                     -- take reg88 for conversion.
            twi_dv_i : in std_logic;                     -- byte valid from TWI, go for next byte.
            reg88_i  : in std_logic_vector(87 downto 0); -- xx:xx:xxE<CR><LF>, treating CR and LF as dummy data to have dv_o high.
            byte_o   : out std_logic_vector(7 downto 0);
            dv_o     : out std_logic                     -- ASCII converted, tell TWI to start transmission.
        );
	end component;

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

	signal cp_s        : std_logic := '0';
    signal rb_s        : std_logic := '0';
    signal tx_dv_s     : std_logic;
    signal tx_byte_s   : std_logic_vector (7 downto 0);
    signal tx_serial_s : std_logic;
    signal tx_done_s   : std_logic;

    signal reg88_dv_s  : std_logic := '0';
    signal reg88_s : std_logic_vector(87 downto 0) := (others => '0');

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

	dut1: bcd_conv_e
	port map(
		cp_i     => cp_s,
		rb_i     => rb_s,
		dv_i     => reg88_dv_s,
        twi_dv_i => tx_done_s,
        reg88_i  => reg88_s,
        byte_o   => tx_byte_s,
        dv_o     => tx_dv_s
	);

    dut2: uart_tx_e
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
        
        -- Reset condition check --
        assert tx_byte_s = x"00" report "Output byte not reset!" severity failure;
        assert tx_dv_s   = '0'   report "Data valid not reset!" severity failure;
        -- Reset condition check --
        report "Reset condition test passed!";

        wait until rising_edge(cp_s);
        reg88_s    <= x"31_33_3A_33_30_3A_30_30_45_0D_0A"; --xx:xx:xxE<CR><LF>
        reg88_dv_s <= '1';
        wait until rising_edge(cp_s);
        reg88_dv_s <= '0';
        wait until rising_edge(cp_s);

        UART_READ_BYTE(tx_serial_s, tx_byte_s);
        report "Byte read correctly!";

        wait until tx_byte_s = x"45";
        wait until falling_edge(tx_done_s); -- wait until tx_done_s changes.
        wait until rising_edge(cp_s);

        -- Repeatability test --
        wait until rising_edge(cp_s);
        reg88_s    <= x"32_31_3A_34_36_3A_35_39_45_0D_0A"; --xx:xx:xxE<CR><LF>
        reg88_dv_s <= '1';
        wait until rising_edge(cp_s);
        reg88_dv_s <= '0';
        wait until rising_edge(cp_s);
        -- Repeatability test --
        UART_READ_BYTE(tx_serial_s, tx_byte_s);
        report "Repeatability passed! \n" & "Byte read correctly!";

        wait until tx_byte_s = x"45";
        wait until falling_edge(tx_done_s); -- wait until tx_done_s changes.
        wait until rising_edge(cp_s);
        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;