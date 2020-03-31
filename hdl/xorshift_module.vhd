-- ===================================================================
-- TITLE : Presudo-randam module (xorshift)
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2019/05/15 -> 2019/05/15
--
-- ===================================================================

-- The MIT License (MIT)
-- Copyright (c) 2017-2019 J-7SYSTEM WORKS LIMITED.
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

----------------------------------------------------------------------
--  xorshift32 sub module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity xorshift32_submodule is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		enable		: in  std_logic := '1';

		random		: out std_logic_vector(31 downto 0)
	);
end xorshift32_submodule;

architecture RTL of xorshift32_submodule is
	signal x_reg		: std_logic_vector(31 downto 0);
	signal a_sig		: std_logic_vector(31 downto 0);
	signal b_sig		: std_logic_vector(31 downto 0);
	signal c_sig		: std_logic_vector(31 downto 0);

begin

	process (clk, reset) begin
		if (reset = '1') then
			x_reg <= conv_std_logic_vector(2463534242, 32);

		elsif rising_edge(clk) then
			if (enable = '1') then
				x_reg <= c_sig;
			end if;

		end if;
	end process;

	a_sig <= x_reg xor (x_reg(18 downto 0) & "0000000000000");
	b_sig <= a_sig xor ("00000000000000000" & a_sig(31 downto 17));
	c_sig <= b_sig xor (b_sig(16 downto 0) & "000000000000000");

	random <= x_reg;


end RTL;



----------------------------------------------------------------------
--  xorshift128 sub module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity xorshift128_submodule is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		enable		: in  std_logic := '1';

		random		: out std_logic_vector(31 downto 0)
	);
end xorshift128_submodule;

architecture RTL of xorshift128_submodule is
	signal x_reg		: std_logic_vector(31 downto 0);
	signal y_reg		: std_logic_vector(31 downto 0);
	signal z_reg		: std_logic_vector(31 downto 0);
	signal w_reg		: std_logic_vector(31 downto 0);
	signal t_sig		: std_logic_vector(31 downto 0);
	signal w_sig		: std_logic_vector(31 downto 0);

begin

	process (clk, reset) begin
		if (reset = '1') then
			x_reg <= conv_std_logic_vector(123456789, 32);
			y_reg <= conv_std_logic_vector(362436069, 32);
			z_reg <= conv_std_logic_vector(521288629, 32);
			w_reg <= conv_std_logic_vector(88675123, 32);

		elsif rising_edge(clk) then
			if (enable = '1') then
				x_reg <= y_reg;
				y_reg <= z_reg;
				z_reg <= w_reg;
				w_reg <= w_sig;
			end if;

		end if;
	end process;

	t_sig <= x_reg xor (x_reg(20 downto 0) & "00000000000");
	w_sig <= (w_reg xor ("0000000000000000000" & w_reg(31 downto 19))) xor (t_sig xor ("00000000" & t_sig(31 downto 8)));

	random <= w_reg;


end RTL;



----------------------------------------------------------------------
--  fluctuator sub module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
library LPM;
use LPM.lpm_components.all;
use work.xorshift32_submodule;

entity fluctuator_submodule is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		enable		: in  std_logic := '1';

		fluctuator	: out std_logic_vector(17 downto 0);
		out_valid	: out std_logic
	);
end fluctuator_submodule;

architecture RTL of fluctuator_submodule is
	type DEF_STATE_CALC is (MULT,ADD);
	signal state		: DEF_STATE_CALC;

	signal x_reg		: std_logic_vector(17 downto 0);
	signal inv_x_sig	: std_logic_vector(18 downto 0);

	signal mul_a_reg	: std_logic_vector(17 downto 0);
	signal mul_ans_sig	: std_logic_vector(35 downto 0);

	signal rand_sig		: std_logic_vector(31 downto 0);
begin

	inv_x_sig <= conv_std_logic_vector(262144,19) - ('0' & x_reg);

	u_mult : lpm_mult
	generic map(
		lpm_type			=> "LPM_MULT",
		lpm_representation	=> "UNSIGNED",
		lpm_hint			=> "MAXIMIZE_SPEED=5",
		lpm_widtha			=> 18,
		lpm_widthb			=> 18,
		lpm_widthp			=> 36
	)
	port map(
		dataa	=> mul_a_reg,
		datab	=> mul_a_reg,
		result	=> mul_ans_sig
	);

	u_rand : xorshift32_submodule
	port map(
		reset		=> reset,
		clk			=> clk,
		enable		=> '1',
		randam		=> rand_sig
	);


	process (clk, reset) begin
		if (reset = '1') then
			state <= ADD;
			x_reg <= (others=>'0');

		elsif rising_edge(clk) then
			if (enable = '1') then

				case state is
				when MULT =>
					state <= ADD;
					if (x_reg(17) = '1') then
						mul_a_reg <= inv_x_sig(17 downto 0);
					else
						mul_a_reg <= x_reg;
					end if;

				when ADD =>
					state <= MULT;
					if (x_reg(17 downto 14) = "1111") then
						x_reg <= x_reg - ("000000" & rand_sig(11 downto 0));
					elsif (x_reg(17 downto 14) = "0000") then
						x_reg <= x_reg + ("000000" & rand_sig(11 downto 0));
					else
						if (x_reg(17) = '1') then
							x_reg <= x_reg - mul_ans_sig(34 downto 17);
						else
							x_reg <= x_reg + mul_ans_sig(34 downto 17);
						end if;
					end if;

				end case;
			end if;

		end if;
	end process;

	fluctuator <= x_reg;
	out_valid <= '1' when(state = MULT) else '0';


end RTL;
