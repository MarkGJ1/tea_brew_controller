-- File name : twi_rx.vhd
-- Description : Three Wire Interface receiver for synchronous communication with S4.
-- Author : Marko Gjorgjievski
-- Date created : 15.06.2026

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity twi_rx_e is

	port (
		cp_i        : in std_logic;
        rb_i        : in std_logic;
        stx_i       : in std_logic;
        sdv_i       : in std_logic;
        sdo_i       : in std_logic;      
        dv_o        : out std_logic;
        twi_byte_o  : out std_logic_vector(7 downto 0)
    );

end entity;

architecture twi_rx_a of twi_rx_e is

    -- Moore FSM for sampling control
    type twi_fsm_t is (IDLE, SAMPLE, DONE);
    signal fsm_r, fsm_next_w : twi_fsm_t;

    -- FSM Control Signals
    signal dv_w : std_logic;

    -- Input registers
    signal stx_r, sdv_r, sdv_2r, sdo_r : std_logic;

    -- Output registers
    signal twi_byte_r : std_logic_vector(7 downto 0);

    -- Internal counting logic
    signal bit_idx_r : integer range 0 to 7;

begin

    p_sample_bit: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            stx_r  <= '0';
            sdv_r  <= '0';
            sdo_r  <= '0';
            sdv_2r <= '0';
            twi_byte_r <= (others => '0');
        elsif rising_edge(cp_i) then
            stx_r  <= stx_i;
            sdv_r  <= sdv_i;
            sdv_2r <= sdv_r;
            sdo_r  <= sdo_i;
            if stx_r = '1' then
                if sdv_r = '1' and sdv_2r = '0' then -- need a rising edge detector.
                    twi_byte_r(bit_idx_r) <= sdo_r;
                    if bit_idx_r < 7 then
                        bit_idx_r <= bit_idx_r + 1;
                    else
                        bit_idx_r <= 0;
                    end if;
                end if;
            else
                bit_idx_r <= 0;
            end if;     
        end if;
    end process;

    p_fsm_clocked: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            fsm_r <= IDLE;
        elsif rising_edge(cp_i) then
            fsm_r <= fsm_next_w;
        end if;
    end process;

    p_fsm_transition: process(fsm_r, stx_r, sdv_r, sdv_2r, bit_idx_r)
    begin
        fsm_next_w <= fsm_r;
        case fsm_r is
            when IDLE =>
                if stx_r = '1' then
                    fsm_next_w <= SAMPLE;
                else
                    fsm_next_w <= IDLE;
                end if;
            when SAMPLE =>
                if sdv_r = '1' and sdv_2r = '0' then
                    if bit_idx_r >= 7 then
                        fsm_next_w <= DONE;
                    end if;
                end if;
            when DONE =>    fsm_next_w <= IDLE;
            when others =>  fsm_next_w <= IDLE;
        end case;
    end process;

    p_fsm_output: process(fsm_r)
    begin
        dv_w <= '0';
        case fsm_r is
            when DONE   => dv_w <= '1';
            when others => dv_w <= '0';
        end case;
    end process;

    dv_o        <= dv_w;
    twi_byte_o  <= twi_byte_r;

end architecture;