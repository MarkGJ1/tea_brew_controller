-- File name : hb_led.vhd
-- Description : Heartbeat LED module
-- Author : Marko Gjorgjievski
-- Date created : 19.10.2025

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hb_led_e is

	generic(
		hb_halfperiod_g : integer := 13_500_000; -- generates 0.5s half period at 27MHz clock (Tang Nano 9k)
		counter_width_g : integer := 24
	);
	port (
		cp_i : in std_logic;
		rb_i : in std_logic;
		d_o : out std_logic);

end entity;

architecture hb_led_a of hb_led_e is

	signal counter_r : unsigned(counter_width_g-1 downto 0);
	signal b_r 		 : std_logic; -- LED Output Register.

begin

	timer : process (cp_i, rb_i) -- heartbeat timer process
	begin
		if rb_i = '0' then -- asynchronous reset (active low)
			b_r 	  <= '0';
			counter_r <= (others => '0');
		elsif rising_edge(cp_i) then
			if counter_r < hb_halfperiod_g then
				counter_r <= counter_r + 1; -- count upto half period
			else
				b_r 	  <= not b_r; -- flip output
				counter_r <= (others => '0');
			end if;
		end if;
	end process;

	d_o <= b_r; -- take internal register to output

end hb_led_a;