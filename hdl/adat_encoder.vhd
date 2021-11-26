-- ===================================================================
-- TITLE : ADAT Encoder
--
--     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2015/02/15 -> 2015/02/24
--            : 2015/03/04 (FIXED)
--            : 2019/08/12 ライセンスアップデート
--
-- ===================================================================
--
-- The MIT License (MIT)
-- Copyright (c) 2005-2020 J-7SYSTEM WORKS LIMITED.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity adat_encoder is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;		-- 12.288MHz (48kHz 256fs)
		clk_ena		: in  std_logic;		-- Option(clk divider)

		ch0_data	: in  std_logic_vector(23 downto 0);
		ch1_data	: in  std_logic_vector(23 downto 0);
		ch2_data	: in  std_logic_vector(23 downto 0);
		ch3_data	: in  std_logic_vector(23 downto 0);
		ch4_data	: in  std_logic_vector(23 downto 0);
		ch5_data	: in  std_logic_vector(23 downto 0);
		ch6_data	: in  std_logic_vector(23 downto 0);
		ch7_data	: in  std_logic_vector(23 downto 0);
		usercode	: in  std_logic_vector(3 downto 0);
		sync_out	: out std_logic;

		adat_tx		: out std_logic
	);
end adat_encoder;

architecture RTL of adat_encoder is
	signal bitcount			: integer range 0 to 255;
	signal syncout_reg		: std_logic;
	signal adattx_in_sig	: std_logic_vector(255 downto 0);
	signal adattx_reg		: std_logic_vector(255 downto 0);
	signal nrzi_reg			: std_logic;

begin

	----------------------------------------------
	-- ADAT bit assignment
	----------------------------------------------

	-- SYNC
	adattx_in_sig(255 downto 245) <= "10000000000";
	adattx_in_sig(244 downto 240) <= '1' & usercode;

	-- ch0
	adattx_in_sig(239 downto 235) <= '1' & ch0_data(23 downto 20);
	adattx_in_sig(234 downto 230) <= '1' & ch0_data(19 downto 16);
	adattx_in_sig(229 downto 225) <= '1' & ch0_data(15 downto 12);
	adattx_in_sig(224 downto 220) <= '1' & ch0_data(11 downto  8);
	adattx_in_sig(219 downto 215) <= '1' & ch0_data( 7 downto  4);
	adattx_in_sig(214 downto 210) <= '1' & ch0_data( 3 downto  0);

	-- ch1
	adattx_in_sig(209 downto 205) <= '1' & ch1_data(23 downto 20);
	adattx_in_sig(204 downto 200) <= '1' & ch1_data(19 downto 16);
	adattx_in_sig(199 downto 195) <= '1' & ch1_data(15 downto 12);
	adattx_in_sig(194 downto 190) <= '1' & ch1_data(11 downto  8);
	adattx_in_sig(189 downto 185) <= '1' & ch1_data( 7 downto  4);
	adattx_in_sig(184 downto 180) <= '1' & ch1_data( 3 downto  0);

	-- ch2
	adattx_in_sig(179 downto 175) <= '1' & ch2_data(23 downto 20);
	adattx_in_sig(174 downto 170) <= '1' & ch2_data(19 downto 16);
	adattx_in_sig(169 downto 165) <= '1' & ch2_data(15 downto 12);
	adattx_in_sig(164 downto 160) <= '1' & ch2_data(11 downto  8);
	adattx_in_sig(159 downto 155) <= '1' & ch2_data( 7 downto  4);
	adattx_in_sig(154 downto 150) <= '1' & ch2_data( 3 downto  0);

	-- ch3
	adattx_in_sig(149 downto 145) <= '1' & ch3_data(23 downto 20);
	adattx_in_sig(144 downto 140) <= '1' & ch3_data(19 downto 16);
	adattx_in_sig(139 downto 135) <= '1' & ch3_data(15 downto 12);
	adattx_in_sig(134 downto 130) <= '1' & ch3_data(11 downto  8);
	adattx_in_sig(129 downto 125) <= '1' & ch3_data( 7 downto  4);
	adattx_in_sig(124 downto 120) <= '1' & ch3_data( 3 downto  0);

	-- ch4
	adattx_in_sig(119 downto 115) <= '1' & ch4_data(23 downto 20);
	adattx_in_sig(114 downto 110) <= '1' & ch4_data(19 downto 16);
	adattx_in_sig(109 downto 105) <= '1' & ch4_data(15 downto 12);
	adattx_in_sig(104 downto 100) <= '1' & ch4_data(11 downto  8);
	adattx_in_sig( 99 downto  95) <= '1' & ch4_data( 7 downto  4);
	adattx_in_sig( 94 downto  90) <= '1' & ch4_data( 3 downto  0);

	-- ch5
	adattx_in_sig( 89 downto  85) <= '1' & ch5_data(23 downto 20);
	adattx_in_sig( 84 downto  80) <= '1' & ch5_data(19 downto 16);
	adattx_in_sig( 79 downto  75) <= '1' & ch5_data(15 downto 12);
	adattx_in_sig( 74 downto  70) <= '1' & ch5_data(11 downto  8);
	adattx_in_sig( 69 downto  65) <= '1' & ch5_data( 7 downto  4);
	adattx_in_sig( 64 downto  60) <= '1' & ch5_data( 3 downto  0);

	-- ch6
	adattx_in_sig( 59 downto  55) <= '1' & ch6_data(23 downto 20);
	adattx_in_sig( 54 downto  50) <= '1' & ch6_data(19 downto 16);
	adattx_in_sig( 49 downto  45) <= '1' & ch6_data(15 downto 12);
	adattx_in_sig( 44 downto  40) <= '1' & ch6_data(11 downto  8);
	adattx_in_sig( 39 downto  35) <= '1' & ch6_data( 7 downto  4);
	adattx_in_sig( 34 downto  30) <= '1' & ch6_data( 3 downto  0);

	-- ch7
	adattx_in_sig( 29 downto  25) <= '1' & ch7_data(23 downto 20);
	adattx_in_sig( 24 downto  20) <= '1' & ch7_data(19 downto 16);
	adattx_in_sig( 19 downto  15) <= '1' & ch7_data(15 downto 12);
	adattx_in_sig( 14 downto  10) <= '1' & ch7_data(11 downto  8);
	adattx_in_sig(  9 downto   5) <= '1' & ch7_data( 7 downto  4);
	adattx_in_sig(  4 downto   0) <= '1' & ch7_data( 3 downto  0);



	----------------------------------------------
	-- Serialize & NRZI encoding
	----------------------------------------------

	process (clk, reset) begin
		if (reset='1') then
			bitcount <= 0;
			syncout_reg <= '0';
			nrzi_reg <= '0';

		elsif rising_edge(clk) then
			if (clk_ena = '1') then
				if (bitcount = 255) then
					bitcount <= 0;
					adattx_reg <= adattx_in_sig;
				else
					bitcount <= bitcount + 1;
					adattx_reg <= adattx_reg(254 downto 0) & 'X';
				end if;

				if (adattx_reg(255) = '1') then
					nrzi_reg <= not nrzi_reg;
				end if;

				if (bitcount = 255) then
					syncout_reg <= '0';
				elsif (bitcount = 127) then
					syncout_reg <= '1';
				end if;

			end if;
		end if;
	end process;

	sync_out <= syncout_reg;

	adat_tx <= nrzi_reg;



end RTL;

