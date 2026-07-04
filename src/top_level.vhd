-- File name: top_level.vhd
-- Description: Top level
-- Author: Marko Gjorgjievski
-- Date created: 21.06.2026

library IEEE;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.top_package.all;

entity top_level_e is

    port (
        cp_pin    : in std_logic;
        rb_pin    : in std_logic;
        m0_pin    : in std_logic;
        m1_pin    : in std_logic;
        t0_pin    : in std_logic;
        t1_pin    : in std_logic;
        rxd_pin   : in std_logic;
        ld1_pin   : out std_logic; -- rb
        ld2_pin   : out std_logic; -- heartbeat
        ld3_pin   : out std_logic; -- m0_i
        ld4_pin   : out std_logic; -- m1_i
        ld5_pin   : out std_logic; -- t0_i
        ld6_pin   : out std_logic; -- t1_i
        ld7_pin   : out std_logic; -- txd
        ld8_pin   : out std_logic; -- snd_active
        txd_pin   : out std_logic;
        snd_pin   : out std_logic
    );

end entity;

architecture top_level_a of top_level_e is

    -- Interconnects section.
    -- UART-RX - reg88
    signal uart_rx_to_reg88_dv_s    : std_logic;
    signal uart_rx_to_reg88_byte_s  : std_logic_vector(7 downto 0);
    -- reg88 - bcd_conv
    signal reg88_to_bcd_88bytes_s   : std_logic_vector(87 downto 0);
    signal reg88_to_bcd_dv_s        : std_logic;
    -- bcd_conv - twi_tx
    signal bcd_to_twi_tx_dv_s       : std_logic;
    signal bcd_to_twi_tx_byte_s     : std_logic_vector(7 downto 0);
    signal twi_tx_to_bcd_dv_s       : std_logic;
    -- Three Wire Interface
    signal stx_s, sdv_s, sdo_s      : std_logic;
    -- twi_rx - set_rtc, string
    signal twi_rx_dv_s              : std_logic;
    signal twi_rx_byte_s            : std_logic_vector(7 downto 0);
    -- set_rtc - rtc, timer, string
    signal set_rtc_dv_s             : std_logic;
    signal set_rtc_bytes_s          : unsigned(16 downto 0);
    signal set_rtc_start_timer_s    : std_logic;
    -- RTC - timer
    signal rtc_s                    : unsigned(16 downto 0);
    -- timer - string, snd
    signal min_s, guess_s           : std_logic;
    signal done_s                   : std_logic;
    -- string - UART-TX
    signal string_to_uart_tx_byte_s : std_logic_vector(7 downto 0);
    signal string_to_uart_tx_dv_s   : std_logic;
    signal uart_tx_done_s           : std_logic;
    -- UART-TX output
    signal uart_tx_serial_s         : std_logic;
    -- SND output
    signal snd_s                    : std_logic;

begin

    dut_uart_rx: uart_rx_e
	port map(
		cp_i      => cp_pin,
		rb_i      => rb_pin,
		rxd_i     => rxd_pin,
		rx_dv_o   => uart_rx_to_reg88_dv_s,
		rx_byte_o => uart_rx_to_reg88_byte_s
	);

    dut_reg88: reg88_e
    port map(
        cp_i    => cp_pin,
        rb_i    => rb_pin,
        rx_dv_i => uart_rx_to_reg88_dv_s,
        byte_i  => uart_rx_to_reg88_byte_s,
        reg88_o => reg88_to_bcd_88bytes_s,
        rx_dv_o => reg88_to_bcd_dv_s
    );

    dut_bcd_conv: bcd_conv_e
	port map(
		cp_i     => cp_pin,
		rb_i     => rb_pin,
		dv_i     => reg88_to_bcd_dv_s,
        twi_dv_i => twi_tx_to_bcd_dv_s,
        reg88_i  => reg88_to_bcd_88bytes_s,
        byte_o   => bcd_to_twi_tx_byte_s,
        dv_o     => bcd_to_twi_tx_dv_s
	);

    dut_twi_tx: twi_tx_e
    port map(
        cp_i        => cp_pin,
        rb_i        => rb_pin,
        twi_dv_i    => bcd_to_twi_tx_dv_s,
        twi_byte_i  => bcd_to_twi_tx_byte_s,
        stx_o       => stx_s,
        sdv_o       => sdv_s,
        sdo_o       => sdo_s,
        dv_o        => twi_tx_to_bcd_dv_s
    );

    dut_twi_rx: twi_rx_e
    port map(
        cp_i        => cp_pin,
        rb_i        => rb_pin,
        stx_i       => stx_s,
        sdv_i       => sdv_s,
        sdo_i       => sdo_s,
        dv_o        => twi_rx_dv_s,
        twi_byte_o  => twi_rx_byte_s
    );

    dut_set_rtc: set_rtc_e
    port map(
        cp_i        => cp_pin,
        rb_i        => rb_pin,
        dv_i        => twi_rx_dv_s,
        twi_byte_i  => twi_rx_byte_s,
        rtc_dv_o    => set_rtc_dv_s,
        tim_dv_o    => set_rtc_start_timer_s,
        rtc_o       => set_rtc_bytes_s
    );

    dut_rtc: rtc_e
	port map(
		cp_i        => cp_pin,
		rb_i        => rb_pin,
        upd_i       => set_rtc_dv_s,
        upd_time_i  => set_rtc_bytes_s,
        RTC_o       => rtc_s
	);
    
    dut_timer: timer_e
    port map(
        cp_i        => cp_pin,
		rb_i        => rb_pin,
        t0_i        => t0_pin,
        t1_i        => t1_pin,
        rtc_i       => rtc_s,
        brew_ena_i  => set_rtc_start_timer_s,
        min_pass_o  => min_s,
        guess_o     => guess_s,
        done_o      => done_s
    );

    dut_string: string_e
    port map(
        cp_i        => cp_pin,
        rb_i        => rb_pin,
        brew_i      => set_rtc_start_timer_s,
        min_i       => min_s,
        guess_i     => guess_s,
        done_i      => done_s,
        bcd_byte_i  => twi_rx_byte_s,
        bcd_dv_i    => twi_rx_dv_s,
        tx_done_i   => uart_tx_done_s,
        byte_o      => string_to_uart_tx_byte_s,
        dv_o        => string_to_uart_tx_dv_s
    );

    dut_uart_tx: uart_tx_e
    port map(
        cp_i        => cp_pin,
        rb_i        => rb_pin,
        tx_dv_i     => string_to_uart_tx_dv_s,
        tx_byte_i   => string_to_uart_tx_byte_s,
        tx_serial_o => uart_tx_serial_s,
        tx_done_o   => uart_tx_done_s
    );

    dut_snd: snd_e
    port map(
        cp_i        => cp_pin,
        rb_i        => rb_pin,
        snd_ena_i   => done_s,
        snd_o       => snd_s
    );

    dut_led_status: led_status_e
    port map(
        cp_i    => cp_pin,
        rb_i    => rb_pin,
        m0_i    => m0_pin,
        m1_i    => m1_pin,
        t0_i    => t0_pin,
        t1_i    => t1_pin,
        txd_i   => uart_tx_serial_s,
        snd_i   => snd_s,
        ld1_o   => ld1_pin,
        ld2_o   => ld2_pin,
        ld3_o   => ld3_pin,
        ld4_o   => ld4_pin,
        ld5_o   => ld5_pin,
        ld6_o   => ld6_pin,
        ld7_o   => ld7_pin,
        ld8_o   => ld8_pin
    );

    txd_pin <= uart_tx_serial_s;
    snd_pin <= snd_s;

end architecture;