-- File name: uart_rx.vhd
-- Description: UART RX Module for receiving data from UART Transmitter. Fixed 9600 Baud on 27MHz. 8N2 UART.
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: 07.06.2026
-- Recent changes: Greatly simplified and hard-coded uart rate (9600) for tang base clock.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx_e is

    generic(
        baud_rate_g : integer := 2813 -- 27MHz / 9600 = 2812,5 ~ 2813.
    );
    port (
        cp_i      : in  std_logic;
        rb_i      : in  std_logic;
        rxd_i     : in  std_logic;
        rx_dv_o   : out std_logic;
        rx_byte_o : out std_logic_vector(7 downto 0)
    );

end entity;

architecture uart_rx_a of uart_rx_e is

    constant baud_width_c  : integer := 12; -- ceil(log2(2813))
    constant sample_mid_c  : integer := baud_rate_g / 2;

    type uart_fsm_t is (IDLE, START, DATA, STOP_B, DONE);
    signal fsm_r, fsm_next_w : uart_fsm_t;

    signal baud_sample_r : unsigned(baud_width_c-1 downto 0);
    signal baud_ena_w    : std_logic;
    signal baud_tick_r   : std_logic;

    signal rx_dv_r       : std_logic;
    signal rxd_ff1_r     : std_logic;
    signal rxd_ff2_r     : std_logic;
    signal rx_byte_r     : std_logic_vector(7 downto 0);

    signal rx_bit_idx_r  : integer range 0 to 7;
    signal rx_stop_idx_r : integer range 0 to 1;

begin

    p_baud_gen : process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            baud_sample_r <= (others => '0');
            baud_tick_r   <= '0';
        elsif rising_edge(cp_i) then
            if baud_ena_w = '1' then
                case fsm_r is
                    when START =>
                        if baud_sample_r < sample_mid_c then
                            baud_tick_r   <= '0';
                            baud_sample_r <= baud_sample_r + 1;
                        else
                            baud_tick_r   <= '1';
                            baud_sample_r <= (others => '0');
                        end if;
                    when DATA | STOP_B =>
                        if baud_sample_r < baud_rate_g then
                            baud_tick_r   <= '0';
                            baud_sample_r <= baud_sample_r + 1;
                        else
                            baud_tick_r   <= '1';
                            baud_sample_r <= (others => '0');
                        end if;
                    when others =>
                        baud_sample_r <= (others => '0');
                        baud_tick_r   <= '0';
                end case;
            else
                baud_tick_r   <= '0';
                baud_sample_r <= (others => '0');
            end if;
        end if;
    end process;

    p_rx_sample : process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            rxd_ff1_r <= '1';
            rxd_ff2_r <= '1';
        elsif rising_edge(cp_i) then
            rxd_ff1_r <= rxd_i;
            rxd_ff2_r <= rxd_ff1_r;
        end if;
    end process;

    p_bits_sample : process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            rx_bit_idx_r  <= 0;
            rx_stop_idx_r <= 0;
            rx_byte_r     <= (others => '0');
        elsif rising_edge(cp_i) then
            if baud_tick_r = '1' then
                case fsm_r is
                    when DATA =>
                        rx_byte_r(rx_bit_idx_r) <= rxd_ff2_r;
                        if rx_bit_idx_r < 7 then
                            rx_bit_idx_r <= rx_bit_idx_r + 1;
                        else
                            rx_bit_idx_r <= 0;
                        end if;
                    when STOP_B =>
                        if rx_stop_idx_r < 1 then
                            rx_stop_idx_r <= rx_stop_idx_r + 1;
                        else
                            rx_stop_idx_r <= 0;
                        end if;
                    when others =>
                        rx_bit_idx_r  <= 0;
                        rx_stop_idx_r <= 0;
                end case;
            end if;
        end if;
    end process;

    p_fsm_clocked : process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            fsm_r <= IDLE;
        elsif rising_edge(cp_i) then
            fsm_r <= fsm_next_w;
        end if;
    end process;

    p_fsm_transition : process(fsm_r, baud_tick_r, rxd_ff2_r, rx_bit_idx_r, rx_stop_idx_r)
    begin
        fsm_next_w <= fsm_r;
        case fsm_r is
            when IDLE =>
                if rxd_ff2_r = '0' then
                    fsm_next_w <= START;
                end if;
            when START =>
                if baud_tick_r = '1' then
                    if rxd_ff2_r = '0' then
                        fsm_next_w <= DATA;
                    else
                        fsm_next_w <= IDLE;
                    end if;
                end if;
            when DATA =>
                if baud_tick_r = '1' and rx_bit_idx_r >= 7 then
                    fsm_next_w <= STOP_B;
                end if;
            when STOP_B =>
                if baud_tick_r = '1' then
                    if rxd_ff2_r = '1' then
                        if rx_stop_idx_r >= 1 then
                            fsm_next_w <= DONE;
                        end if;
                    else
                        fsm_next_w <= IDLE;
                    end if;
                end if;
            when DONE =>
                fsm_next_w <= IDLE;
            when others =>
                fsm_next_w <= IDLE;
        end case;
    end process;

    p_fsm_output : process(fsm_r)
    begin
        baud_ena_w <= '0';
        rx_dv_r    <= '0';
        case fsm_r is
            when IDLE  => null;
            when START | DATA | STOP_B => baud_ena_w <= '1';
            when DONE  => rx_dv_r <= '1';
            when others => null;
        end case;
    end process;

    rx_dv_o   <= rx_dv_r;
    rx_byte_o <= rx_byte_r;

end architecture;