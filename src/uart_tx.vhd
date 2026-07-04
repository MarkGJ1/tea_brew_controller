-- File name: uart_tx.vhd
-- Description: UART TX Module for sending data to UART Receiver. Fixed 9600 Baud on 27MHz. 8N2 UART.
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: 07.06.2026
-- Recent changes: Greatly simplified and hard-coded uart rate (9600) for tang base clock.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_e is

    generic(
        baud_rate_g : integer := 2813 -- 27MHz / 9600 = 2812,5 ~ 2813.
    );
    port (
        cp_i        : in  std_logic;
        rb_i        : in  std_logic;
        tx_dv_i     : in  std_logic;
        tx_byte_i   : in  std_logic_vector(7 downto 0);
        tx_active_o : out std_logic;
        tx_serial_o : out std_logic;
        tx_done_o   : out std_logic
    );

end entity;

architecture uart_tx_a of uart_tx_e is

    constant baud_width_c : integer := 12; -- ceil(log2(2813))

    type uart_fsm_t is (IDLE, START, DATA, STOP_B, DONE);
    signal fsm_r, fsm_next_w : uart_fsm_t;

    signal baud_sample_r  : unsigned(baud_width_c-1 downto 0);
    signal baud_ena_w     : std_logic;
    signal baud_tick_r    : std_logic;

    signal tx_dv_r        : std_logic;
    signal tx_done_r      : std_logic;
    signal tx_serial_r    : std_logic;
    signal tx_byte_r      : std_logic_vector(7 downto 0);

    signal tx_bit_idx_r   : integer range 0 to 7;
    signal tx_stop_idx_r  : integer range 0 to 1;

begin

    p_baud_gen : process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            baud_sample_r <= (others => '0');
            baud_tick_r   <= '0';
        elsif rising_edge(cp_i) then
            if baud_ena_w = '1' then
                if baud_sample_r = baud_rate_g then
                    baud_sample_r <= (others => '0');
                    baud_tick_r   <= '1';
                else
                    baud_sample_r <= baud_sample_r + 1;
                    baud_tick_r   <= '0';
                end if;
            else
                baud_tick_r   <= '0';
                baud_sample_r <= (others => '0');
            end if;
        end if;
    end process;

    p_counter_logic : process(cp_i, rb_i)
    begin
        if rb_i = '0' then
            tx_bit_idx_r  <= 0;
            tx_stop_idx_r <= 0;
        elsif rising_edge(cp_i) then
            if baud_tick_r = '1' then
                case fsm_r is
                    when DATA =>
                        if tx_bit_idx_r < 7 then
                            tx_bit_idx_r <= tx_bit_idx_r + 1;
                        else
                            tx_bit_idx_r <= 0;
                        end if;
                    when STOP_B =>
                        if tx_stop_idx_r < 1 then
                            tx_stop_idx_r <= tx_stop_idx_r + 1;
                        else
                            tx_stop_idx_r <= 0;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    p_bit_transmit : process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            tx_serial_r <= '1';
            tx_dv_r     <= '0';
            tx_byte_r   <= (others => '0');
        elsif rising_edge(cp_i) then
            tx_dv_r <= tx_dv_i;

            if tx_dv_r = '1' then
                tx_byte_r <= tx_byte_i;
            end if;

            case fsm_r is
                when IDLE | DONE => tx_serial_r <= '1';
                when START       => tx_serial_r <= '0';
                when DATA        => tx_serial_r <= tx_byte_r(tx_bit_idx_r);
                when STOP_B      => tx_serial_r <= '1';
                when others      => tx_serial_r <= '1';
            end case;
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

    p_fsm_transition : process(fsm_r, tx_dv_r, baud_tick_r, tx_bit_idx_r, tx_stop_idx_r)
    begin
        fsm_next_w <= fsm_r;
        case fsm_r is
            when IDLE =>
                if tx_dv_r = '1' then
                    fsm_next_w <= START;
                end if;
            when START =>
                if baud_tick_r = '1' then
                    fsm_next_w <= DATA;
                end if;
            when DATA =>
                if baud_tick_r = '1' and tx_bit_idx_r = 7 then
                    fsm_next_w <= STOP_B;
                end if;
            when STOP_B =>
                if baud_tick_r = '1' and tx_stop_idx_r = 1 then
                    fsm_next_w <= DONE;
                end if;
            when DONE =>
                fsm_next_w <= IDLE;
            when others =>
                fsm_next_w <= IDLE;
        end case;
    end process;

    p_fsm_output : process(fsm_r)
    begin
        baud_ena_w  <= '0';
        tx_done_r   <= '0';
        case fsm_r is
            when IDLE   => null;
            when START | DATA | STOP_B => baud_ena_w  <= '1';
            when DONE   => tx_done_r <= '1';
            when others => null;
        end case;
    end process;

    tx_done_o   <= tx_done_r;
    tx_serial_o <= tx_serial_r;
    tx_active_o <= baud_ena_w;

end architecture;