-- File name: uart_tx
-- Description: UART TX Module for sending data to UART Receiver. Fixed 9600 Baud on 27MHz. 8N2 UART.
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: 06.06.2026
-- Newest changes: Assertion loops and reports for testing.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx_e is

    generic(
        baud_rate  : integer := 2813 -- 27e6 / 9600
    );
    port (
        cp_i            : in std_logic;
        rb_i            : in std_logic; 
        tx_dv_i         : in std_logic; -- Data ready to be transferred.
        tx_byte_i       : in std_logic_vector (7 downto 0); -- Byte to be transferred.
        tx_active_o     : out std_logic; 
        tx_serial_o     : out std_logic;
        tx_done_o       : out std_logic
    );

end entity;

architecture uart_tx_a of uart_tx_e is

    constant baud_width : integer := 12; -- ceil(log2(2813))
    constant baud_count : integer := baud_rate; -- TODO: Replace constant and just use generic throughout file.

    type uart_fsm_t is (IDLE, START, DATA, STOP_B, DONE);
    signal uart_fsm, uart_fsm_next : uart_fsm_t;
    
    signal baud_s   : unsigned(baud_width-1 downto 0); -- optimal sizing. alternative: signal baud_cnt : integer range 0 to baud_rate;
    signal baud_tick: std_logic; -- Used for state transitions. Completely fine and synchronous to FSM clock.
    signal baud_ena : std_logic; -- Used for enabling baud and indicating TX status.

    signal tx_dv_s       : std_logic; -- Data (input) valid signal.
    signal tx_done_s     : std_logic; -- Data (output) valid signal.
    signal tx_serial_ff  : std_logic; -- Output TX register.
    signal tx_byte_reg   : std_logic_vector(7 downto 0); -- Input Byte Register.
    signal stop_index    : integer range 0 to 1; -- Two stop bits.
    signal bit_index     : integer range 0 to 7;

begin

    p_baud_gen: process(rb_i, cp_i) -- Generating the baud rate from the clock using a counter. 
    begin
        if rb_i = '0' then
            baud_s <= (others => '0');
            baud_tick <= '0';
        elsif rising_edge(cp_i) then
            if baud_ena = '1' then
                if baud_s = baud_count then
                    baud_s <= (others => '0');
                    baud_tick <= '1';
                else
                    baud_s <= baud_s + 1;
                    baud_tick <= '0';
                end if;
            else
                baud_s <= (others => '0');
                baud_tick <= '0';
            end if;
        end if;
    end process;

    p_counter_logic: process(cp_i, rb_i) -- Counting the amount of bits to stay in the DATA and STOP states, respectively.
    begin
        if rb_i = '0' then
            bit_index  <= 0;
            stop_index <= 0;
        elsif rising_edge(cp_i) then
            if baud_tick = '1' then
                case uart_fsm is
                    when DATA =>
                        if bit_index = 7 then
                            bit_index <= 0;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    when STOP_B =>
                        if stop_index = 1 then
                            stop_index <= 0;
                        else
                            stop_index <= stop_index + 1;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    p_bit_transmit: process(rb_i, cp_i) -- Output register of UART_TX.
    begin
        if rb_i = '0' then
            tx_serial_ff <= '1';
            tx_dv_s <= '0';
            tx_byte_reg <= (others => '0');
        elsif rising_edge(cp_i) then
            tx_dv_s <= tx_dv_i;

            if tx_dv_s = '1' then
                tx_byte_reg <= tx_byte_i;
            end if;

            case uart_fsm is
                when IDLE | DONE =>  tx_serial_ff <= '1';
                when START  => tx_serial_ff <= '0';
                when DATA   => tx_serial_ff <= tx_byte_reg(bit_index);
                when STOP_B => tx_serial_ff <= '1';
                when others => tx_serial_ff <= '1'; 
            end case;
        end if;
    end process;

    p_fsm_clocked: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            uart_fsm <= IDLE;
        elsif rising_edge(cp_i) then
            uart_fsm <= uart_fsm_next;
        end if;
    end process;

    p_fsm_transition: process(uart_fsm, tx_dv_s, baud_tick, bit_index, stop_index)
    begin
        uart_fsm_next <= uart_fsm; -- default: hold current state
        case uart_fsm is
            when IDLE =>
                if tx_dv_s = '1' then
                    uart_fsm_next <= START;
                end if;
            when START =>
                if baud_tick = '1' then
                    uart_fsm_next <= DATA;
                end if;
            when DATA =>
                if baud_tick = '1' and bit_index = 7 then
                    uart_fsm_next <= STOP_B; 
                end if;
            when STOP_B =>
                if baud_tick = '1' and stop_index = 1 then
                    uart_fsm_next <= DONE;
                end if;
            when DONE =>
                uart_fsm_next <= IDLE;
            when others =>
                uart_fsm_next <= IDLE;
        end case;
    end process;

    p_fsm_output: process(uart_fsm)
    begin
        baud_ena  <= '0';
        tx_done_s <= '0';
        case uart_fsm is
            when IDLE   => null;
            when START | DATA | STOP_B => baud_ena <= '1';
            when DONE   => tx_done_s <= '1';
            when others => null;
        end case;
    end process;

    tx_done_o   <= tx_done_s;
    tx_serial_o <= tx_serial_ff;
    tx_active_o <= baud_ena;
    
end architecture;