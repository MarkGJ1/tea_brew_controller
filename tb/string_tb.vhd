-- File name: string_tb.vhd
-- Description:
-- Author: Marko Gjorgjievski
-- Date created: 27.06.2026

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity string_tb is
end entity;

architecture string_tb_a of string_tb is

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

    component string_e is
        port(
            cp_i       : in  std_logic;
            rb_i       : in  std_logic;
            brew_i     : in  std_logic; -- 
            min_i      : in  std_logic; --
            guess_i    : in  std_logic; -- Timer enable signals
            done_i     : in  std_logic; -- 
            bcd_byte_i : in  std_logic_vector(7 downto 0); -- TWI-RX signals
            bcd_dv_i   : in  std_logic; 
            tx_done_i  : in  std_logic; -- UART TX signals
            byte_o     : out std_logic_vector(7 downto 0);
            dv_o       : out std_logic
        );
    end component;

    constant clk_freq_c : integer := 1_000_000; -- slower clock for faster simulation.
    constant clk_period_c : time := 1000 ms/clk_freq_c;

    signal cp_s        : std_logic := '0';
    signal rb_s        : std_logic := '0';

    -- TWI TX
    signal twi_dv_s         : std_logic := '0'; -- 
    signal twi_byte_s       : std_logic_vector(7 downto 0) := (others => '0');
    signal stx_s            : std_logic;
    signal sdv_s            : std_logic;
    signal sdo_s            : std_logic;
    signal twi_tx_done_s    : std_logic;

    -- TWI RX
    signal twi_rx_byte_s    : std_logic_vector(7 downto 0);
    signal dv_s             : std_logic;

    -- UART TX 
    signal tx_dv_s          : std_logic;
    signal tx_byte_s        : std_logic_vector(7 downto 0);
    signal tx_done_s        : std_logic;   

    -- String ROM
    signal brew_s           : std_logic := '0';
    signal min_s            : std_logic := '0';
    signal guess_s          : std_logic := '0';
    signal done_s           : std_logic := '0';


begin

    dut_twi_tx : twi_tx_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        twi_dv_i => twi_dv_s,
        twi_byte_i => twi_byte_s,
        stx_o => stx_s,
        sdv_o => sdv_s,
        sdo_o => sdo_s,
        dv_o => twi_tx_done_s -- normally open, the DV comes from TWI receiver. Should be renamed to twi_tx_done or similar
    );

    dut_twi_rx : twi_rx_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        stx_i => stx_s,
        sdv_i => sdv_s,
        sdo_i => sdo_s,
        dv_o => dv_s,
        twi_byte_o => twi_rx_byte_s
    );

    dut_uart_tx : uart_tx_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        tx_dv_i => tx_dv_s,
        tx_byte_i => tx_byte_s,
        tx_serial_o => open,
        tx_done_o => tx_done_s
    );

    dut_string : string_e
    port map(
        cp_i => cp_s,
        rb_i => rb_s,
        brew_i => brew_s,
        min_i  => min_s,
        guess_i => guess_s,
        done_i  => done_s,
        bcd_byte_i => twi_rx_byte_s,
        bcd_dv_i => dv_s,
        tx_done_i => tx_done_s,
        byte_o => tx_byte_s,
        dv_o => tx_dv_s
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
        twi_byte_s <= X"00"; -- Byte to be transmitted.
        twi_dv_s   <= '1'; -- Byte valid, start transmit.
        wait until rising_edge(cp_s);
        twi_dv_s   <= '0';
        wait until twi_tx_done_s = '1';
        assert twi_byte_s = twi_rx_byte_s report "Transmitted Bytes don't match." severity failure;

        -- Repeatability test --
        wait for 10 us;
        twi_byte_s <= X"30";
        twi_dv_s   <= '1';
        wait until rising_edge(cp_s);
        twi_dv_s   <= '0';
        wait until twi_tx_done_s = '1';
        -- Repeatability test --
        assert twi_byte_s = twi_rx_byte_s report "Transmitted Bytes don't match." severity failure;
        report "Repeatability test passed!";

        wait for 10 us;
        twi_byte_s <= X"13";
        twi_dv_s   <= '1';
        wait until rising_edge(cp_s);
        twi_dv_s   <= '0';
        wait until twi_tx_done_s = '1';

        wait for 10 us;
        twi_byte_s <= X"45";
        twi_dv_s   <= '1';
        wait until rising_edge(cp_s);
        twi_dv_s   <= '0';
        wait until twi_tx_done_s = '1';

        wait for 10 us;
        wait until rising_edge(cp_s);
        brew_s <= '1';
        wait until rising_edge(cp_s);
        brew_s <= '0';
        wait until tx_byte_s = x"0A";
        wait until tx_done_s = '1';

        wait for 2 us;
        wait until rising_edge(cp_s);
        min_s <= '1';
        wait until rising_edge(cp_s);
        min_s <= '0';
        wait until tx_byte_s = x"0A";
        wait until tx_done_s = '1';

        wait for 2 us;
        wait until rising_edge(cp_s);
        min_s <= '1';
        wait until rising_edge(cp_s);
        min_s <= '0';
        wait until tx_byte_s = x"0A";
        wait until tx_done_s = '1';

        wait for 2 us;
        wait until rising_edge(cp_s);
        min_s <= '1';
        wait until rising_edge(cp_s);
        min_s <= '0';
        wait until tx_byte_s = x"0A";
        wait until tx_done_s = '1';

        wait for 2 us;
        wait until rising_edge(cp_s);
        guess_s <= '1';
        wait until rising_edge(cp_s);
        guess_s <= '0';
        wait until tx_byte_s = x"00";
        wait until tx_done_s = '1';
        
        wait for 10 ms;
        wait until rising_edge(cp_s);
        done_s <= '1';
        wait until rising_edge(cp_s);
        done_s <= '0';
        wait until tx_byte_s = x"00";
        wait until tx_done_s = '1';
        -- Test end.
        -- Make sure to enable simulation break on severity failure in ModelSIM to stop simulation.
        report "Test Complete" severity failure;

    end process;

end architecture;