-- File name: reg88.vhd
-- Description: reg88 module for saving the TOA (ASCII) inside registers.
-- Author: Marko Gjorgjievski
-- Date created: 08.06.2026
-- Date modified: 13.06.2026
-- Recent changes: removed TX features.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg88_e is

    port (
        cp_i        : in std_logic;
        rb_i        : in std_logic;
        rx_dv_i     : in std_logic;
        byte_i      : in std_logic_vector(7 downto 0);
        reg88_o     : out std_logic_vector(87 downto 0); -- "xx:xx:xxE<CR><LF>" - 11x8 - 11 Bytes
        rx_dv_o     : out std_logic
    );

end entity;

architecture rtl of reg88_e is

    type reg_fsm_t is (IDLE_UPDATE, UPDATE_DONE);
    signal fsm_r, fsm_next_w : reg_fsm_t;

    signal reg88_r      : std_logic_vector(87 downto 0);
    signal bit_idx_r    : integer range 0 to 88;
    signal rx_dv_w      : std_logic; -- UART-RX Byte Done.

begin

    update_transmit: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            bit_idx_r <= 0;
            reg88_r   <= (others => '0');
        elsif rising_edge(cp_i) then
            case fsm_r is
                when IDLE_UPDATE =>
                    if rx_dv_i = '1' then
                        reg88_r(bit_idx_r+7 downto bit_idx_r) <= byte_i;
                        bit_idx_r <= bit_idx_r + 8;
                    end if;
                when UPDATE_DONE => bit_idx_r <= 0;
                when others => bit_idx_r <= 0;
            end case;
        end if;
    end process;

    clocked_fsm: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            fsm_r <= IDLE_UPDATE;
        elsif rising_edge(cp_i) then
            fsm_r <= fsm_next_w;
        end if;
    end process;

    p_fsm_transition: process(fsm_r, rx_dv_i, bit_idx_r)
    begin
        fsm_next_w <= fsm_r;
        case fsm_r is
            when IDLE_UPDATE   =>
                if bit_idx_r >= 88 then
                    fsm_next_w <= UPDATE_DONE;
                end if;
            when UPDATE_DONE   => fsm_next_w <= IDLE_UPDATE;
            when others        => fsm_next_w <= IDLE_UPDATE;
        end case;
    end process;

    p_fsm_output: process(fsm_r)
    begin
        rx_dv_w <= '0';
        case fsm_r is
            when IDLE_UPDATE   => null;
            when UPDATE_DONE   => rx_dv_w <= '1';
            when others        => rx_dv_w <= '0';
        end case;
    end process;

    reg88_o <= reg88_r;
    rx_dv_o <= rx_dv_w;

end architecture;