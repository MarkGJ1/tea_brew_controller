library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package top_package is

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

    component twi_tx_e is
        generic(
            data_rate_g  : integer := 27_000 -- 27_000_000 / 27_000 = 1kHz
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

    component uart_rx_e is
		generic (
			baud_rate_g : integer := 2812 -- 27MHz / 9600 = 2812
		);
		port (
			cp_i        : in std_logic;
			rb_i        : in std_logic;
			rxd_i       : in std_logic;
			rx_dv_o     : out std_logic;
			rx_byte_o   : out std_logic_vector(7 downto 0)
		);
	end component;

    component uart_tx_e is
        generic(
            baud_rate_g  : integer := 2812 -- 27MHz / 9600 = 2812
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

    component rtc_e is
		generic(
            clk_freq_c : integer := 27_000_000
        );
        port (
            cp_i            : in std_logic;
            rb_i            : in std_logic;
            upd_i           : in std_logic;
            upd_time_i      : in unsigned(16 downto 0);
            RTC_o           : out unsigned(16 downto 0)
        );
	end component;

    component set_rtc_e is
        port (
            cp_i        : in std_logic;
            rb_i        : in std_logic;
            dv_i        : in std_logic;
            twi_byte_i  : in std_logic_vector(7 downto 0);
            rtc_dv_o    : out std_logic;             -- UPDATE command
            tim_dv_o    : out std_logic;             -- Brew start
            rtc_o       : out unsigned(16 downto 0)  -- New time
        );
    end component;

    component timer_e is
        port (
            cp_i            : in std_logic;
            rb_i            : in std_logic;
            t0_i            : in std_logic;
            t1_i            : in std_logic;
            rtc_i           : in unsigned(16 downto 0);
            brew_ena_i      : in std_logic;
            min_pass_o      : out std_logic;
            guess_o         : out std_logic;
            done_o          : out std_logic
        );
    end component;

    component snd_e is
        generic(clk_freq_g : integer := 27_000_000;
                snd_freq_g : integer := 27_000; -- 10KHz Sound wave = clk_freq_g / snd_freq_g
                ring_dur_g : integer := 5 
        );
        port(cp_i       : in std_logic;
            rb_i        : in std_logic;
            snd_ena_i   : in std_logic;
            snd_o       : out std_logic
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

    component led_status_e is
        port (
            cp_i    : in std_logic;
            rb_i    : in std_logic;
            m0_i    : in std_logic;
            m1_i    : in std_logic;
            t0_i    : in std_logic;
            t1_i    : in std_logic;
            txd_i   : in std_logic;
            snd_i   : in std_logic;
            ld1_o   : out std_logic; -- rb_o
            ld2_o   : out std_logic; -- heartbeat
            ld3_o   : out std_logic; -- m0_i
            ld4_o   : out std_logic; -- m1_i
            ld5_o   : out std_logic; -- t0_i
            ld6_o   : out std_logic; -- t1_i
            ld7_o   : out std_logic; -- txd_o
            ld8_o   : out std_logic  -- snd_active
        );
    end component;

end package;