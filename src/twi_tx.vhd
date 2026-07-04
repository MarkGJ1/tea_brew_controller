-- File name : twi_tx.vhd
-- Description : Three Wire Interface transmitter for synchronous communication with S3.
-- Author : Marko Gjorgjievski
-- Date created : 14.06.2026

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity twi_tx_e is

	generic(
		data_rate_g : integer := 27_000 -- 27MHz / 1000 = 27_000
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

end entity;

architecture twi_tx_a of twi_tx_e is

    constant twi_cnt_width_c    : integer := 15; -- ceil(log2(27_000))
    -- constant twi_cnt_mid_c      : integer := data_rate_g / 2;

    -- Moore FSM for transmission control
    type twi_fsm_t is (IDLE, DATA, DONE);
    signal fsm_r, fsm_next_w : twi_fsm_t;

    -- FSM control signals
    signal stx_w          : std_logic;
    signal dv_w           : std_logic;

    -- Internal counting logic
    signal twi_counter_r  : unsigned(twi_cnt_width_c-1 downto 0);
    signal twi_tick_r     : std_logic;
    signal bit_idx_r      : integer range 0 to 7;
    signal tick_idx_r     : integer range 0 to 2;

    -- Input registers
    signal twi_dv_r     : std_logic;
    signal twi_byte_r   : std_logic_vector(7 downto 0);

    -- Output registers
    signal sdv_r, sdo_r : std_logic;

begin

    p_data_rate: process(rb_i, cp_i)
    begin
        if rb_i = '0' then
            twi_counter_r <= (others => '0');
            twi_tick_r    <= '0';
            bit_idx_r     <=  0;
            twi_dv_r      <= '0';
            twi_byte_r    <= (others => '0');
            sdv_r         <= '0';
            sdo_r         <= '0';
        elsif rising_edge(cp_i) then
            twi_dv_r    <= twi_dv_i;
            if twi_dv_r = '1' then
                twi_byte_r  <= twi_byte_i;
            end if;

            if stx_w = '1' then
                if twi_counter_r < data_rate_g then
                    twi_counter_r <= twi_counter_r + 1;
                    twi_tick_r    <= '0';
                else
                    twi_counter_r <= (others => '0');
                    twi_tick_r    <= '1';
                end if;

                if twi_tick_r = '1' then
                    if tick_idx_r < 2 then
                        tick_idx_r <= tick_idx_r + 1;
                    else
                        tick_idx_r <= 0;
                        if bit_idx_r < 7 then 
                            bit_idx_r  <= bit_idx_r + 1;
                        else
                            tick_idx_r <= 0;
                            bit_idx_r  <= 0;
                        end if;
                    end if;
                end if;

                case tick_idx_r is
                    when 1 => sdv_r <= '1';
                    when others => sdv_r <= '0';
                end case;

                sdo_r <= twi_byte_r(bit_idx_r);
            else
                twi_counter_r <= (others => '0');
                twi_tick_r    <= '0';
                bit_idx_r     <=  0;
                sdo_r         <= '0';
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

    p_fsm_transition: process(fsm_r, twi_dv_r, twi_tick_r, bit_idx_r, tick_idx_r)
    begin
        fsm_next_w <= fsm_r;
        case fsm_r is
            when IDLE =>
                if twi_dv_r = '1' then
                    fsm_next_w <= DATA;
                end if;
            when DATA =>
                if twi_tick_r = '1' then
                    if bit_idx_r >= 7 then
                        if tick_idx_r >= 2 then
                            fsm_next_w <= DONE;
                        end if;
                    end if;
                end if;
            when DONE =>   fsm_next_w <= IDLE;
            when others => fsm_next_w <= IDLE;
        end case;
    end process;

    p_fsm_output: process(fsm_r)
    begin
        stx_w <= '0';
        dv_w  <= '0';
        case fsm_r is
        when IDLE   => null;
        when DATA   => stx_w <= '1';
        when DONE   => stx_w <= '0'; 
                       dv_w  <= '1';
        when others => stx_w <= '0';
                        dv_w <= '0';
        end case;
    end process;

    stx_o <= stx_w;
    sdv_o <= sdv_r;    
    sdo_o <= sdo_r;
    dv_o  <= dv_w;

end architecture;