-- File name: led_status.vhd
-- Description: LED Status Indicator Module
-- Author: Marko Gjorgjievski
-- Date created: 15.03.2025
-- Date modified: 19.06.2026
-- Recent changes: complete overhaul of module.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_status_e is

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

end entity;

architecture led_status_a of led_status_e is

    component hb_led_e is
        generic(
            hb_halfperiod_g : natural := 500_000;
            counter_width_g : natural := 19
        );
        port(
            cp_i : in std_logic;
            rb_i : in std_logic;
            d_o : out std_logic
        );
    end component;

    component debounce_e is
        generic(
            clk_freq_g : integer := 1_000_000;
            db_freq_g  : integer := 1000 -- finds closest power of 2 to divide clock for closest 100Hz simulation.
        );
        port (
            cp_i        : in std_logic;
            rb_i        : in std_logic;
            btn_i       : in std_logic;
            btn_o       : out std_logic
        );
    end component;

begin

    ld1_o <= not rb_i;

    heartbeat: hb_led_e
    port map(
        cp_i => cp_i,
        rb_i => rb_i,
        d_o  => ld2_o
    );

    debounce1: debounce_e
    port map(
        cp_i => cp_i,
        rb_i => rb_i,
        btn_i => m0_i,
        btn_o => ld3_o
    );

    debounce2: debounce_e
    port map(
        cp_i => cp_i,
        rb_i => rb_i,
        btn_i => m1_i,
        btn_o => ld4_o
    );

    debounce3: debounce_e
    port map(
        cp_i => cp_i,
        rb_i => rb_i,
        btn_i => t0_i,
        btn_o => ld5_o
    );
    
    debounce4: debounce_e
    port map(
        cp_i => cp_i,
        rb_i => rb_i,
        btn_i => t1_i,
        btn_o => ld6_o
    );

    ld7_o <= not txd_i;
    ld8_o <= snd_i;

end architecture;