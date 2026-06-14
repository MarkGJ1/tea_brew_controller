-- File name: bcd_conv.vhd
-- Description: Converting ASCII characters to BCD by slicing nibbles.
-- Author: Marko Gjorgjievski
-- Date created: 12.06.2026
-- Date modified: 14.06.2026
-- Recent changes: Issues such as byte indexing addressed, working module.

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_conv_e is  

    port(
        cp_i    : in std_logic;
        rb_i    : in std_logic;
        dv_i    : in std_logic;                     -- take reg88 for conversion.
        tw_dv_i : in std_logic;                     -- byte valid from TWI, go for next byte.
        reg88_i : in std_logic_vector(87 downto 0); -- xx:xx:xxE<CR><LF>, treating CR and LF as dummy data to have dv_o high.
        byte_o  : out std_logic_vector(7 downto 0);
        dv_o    : out std_logic                     -- ASCII converted, tell TWI to start transmission.
    );

end entity;

architecture bcd_conv_a of bcd_conv_e is

    signal bcd_conv_w   : std_logic_vector(31 downto 0);
    signal bcd_conv_r   : std_logic_vector(31 downto 0);
    signal bcd_byte_r   : std_logic_vector(7 downto 0);
    signal byte_idx_r   : integer range 0 to 32; -- package nibbles in bytes.
    signal dv_o_r       : std_logic; -- register for data valid to force TX to start after conversion.
    signal dv_i_r       : std_logic; -- DV register to force conversion.
    signal tw_dv_r      : std_logic; -- DV register to force byte shift.
    signal tw_repeat_r  : std_logic;


begin
    -- Example: E140203
    -- : (colons)  = 0011_1010 (ASCII)
    -- E           = 0100_0101 (ASCII)
    -- 3 (decimal) = 0011_0011 (ASCII) = 0011 (BCD)
    bcd_conv_w(3 downto 0)    <=  reg88_i(27 downto 24); 
    bcd_conv_w(7 downto 4)    <=  reg88_i(35 downto 32); 
    bcd_conv_w(11 downto 8)   <=  reg88_i(51 downto 48); 
    bcd_conv_w(15 downto 12)  <=  reg88_i(59 downto 56); 
    bcd_conv_w(19 downto 16)  <=  reg88_i(75 downto 72); 
    bcd_conv_w(23 downto 20)  <=  reg88_i(83 downto 80); 
    bcd_conv_w(31 downto 24)  <=  reg88_i(23 downto 16);

    p_update_reg: process(cp_i, rb_i)
    begin
        if rb_i = '0' then
            dv_i_r      <= '0';
            dv_o_r      <= '0';
            tw_repeat_r <= '0';
            tw_dv_r     <= '0';
            byte_idx_r  <=  8;
            bcd_conv_r  <= (others => '0');
            bcd_byte_r  <= (others => '0');
        elsif rising_edge(cp_i) then
            dv_i_r <= dv_i;
            tw_dv_r <= tw_dv_i;
            if dv_i_r = '1' then
                bcd_conv_r <= bcd_conv_w;
                bcd_byte_r <= bcd_conv_w(7 downto 0);
                byte_idx_r <=  8;
                dv_o_r     <= '1';
            elsif tw_dv_r = '1' then
                if byte_idx_r < 32 then
                    bcd_byte_r <= bcd_conv_r(byte_idx_r+7 downto byte_idx_r);
                    byte_idx_r <= byte_idx_r + 8;
                    tw_repeat_r <= '1';
                else
                    byte_idx_r  <=  8;
                    tw_repeat_r <= '0'; 
                end if;
                dv_o_r <= '0';
            else
                tw_repeat_r <= '0';
                dv_o_r     <= '0';
            end if;
        end if;
    end process;

    dv_o <= dv_o_r or tw_repeat_r;
    byte_o <= bcd_byte_r;

end architecture;