-- ===================================================================
-- TITLE : Unsigned divider module
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2018/02/09 -> 2018/02/13
--
-- ===================================================================

-- The MIT License (MIT)
-- Copyright (c) 2017,2018 J-7SYSTEM WORKS LIMITED.
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
--  Divider sub module
----------------------------------------------------------------------
--  回復法で1桁分の除算を行う 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity div_submodule is
	generic(
		DIVIDEND_BITWIDTH	: integer;		-- 被除数のビット幅 
		DIVISOR_BITWIDTH	: integer		-- 除数のビット幅 
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		enable		: in  std_logic := '1';

		zr_in		: in  std_logic_vector(DIVISOR_BITWIDTH + DIVIDEND_BITWIDTH - 1 downto 0);
		dr_in		: in  std_logic_vector(DIVISOR_BITWIDTH - 1 downto 0);
		valid_in	: in  std_logic := '0';

		zr_out		: out std_logic_vector(zr_in'range);
		dr_out		: out std_logic_vector(dr_in'range);
		valid_out	: out std_logic
	);
end div_submodule;

architecture RTL of div_submodule is
	signal zr_reg		: std_logic_vector(zr_in'range);
	signal dr_reg		: std_logic_vector(dr_in'range);
	signal valid_reg	: std_logic;

	signal pr_sig		: std_logic_vector(dr_reg'length downto 0);
	signal sub_sig		: std_logic_vector(pr_sig'range);
	signal ans_sig		: std_logic_vector(dr_reg'range);
	signal bflag_sig	: std_logic;

begin

	process (clk) begin
		if rising_edge(clk) then
			if (enable = '1') then
				zr_reg <= zr_in;
				dr_reg <= dr_in;
			end if;
		end if;
	end process;

	process (clk, reset) begin
		if (reset = '1') then
			valid_reg <= '0';
		elsif rising_edge(clk) then
			if (enable = '1') then
				valid_reg <= valid_in;
			end if;
		end if;
	end process;

	pr_sig <= zr_reg(zr_reg'left downto zr_reg'left - dr_reg'length);
	sub_sig <= pr_sig - ('0' & dr_reg);
	bflag_sig <= not sub_sig(sub_sig'left);

	ans_sig <= sub_sig(sub_sig'left - 1 downto 0) when(bflag_sig = '1') else pr_sig(pr_sig'left - 1 downto 0);

	zr_out <= ans_sig & zr_reg(zr_reg'left - ans_sig'length - 1 downto 0) & bflag_sig;
	dr_out <= dr_reg;
	valid_out <= valid_reg;

end RTL;



----------------------------------------------------------------------
--  Multicycle divider sub module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.div_submodule;

entity div_multicycle_module is
	generic(
		DIVIDEND_BITWIDTH	: integer;
		DIVISOR_BITWIDTH	: integer
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		dividend	: in  std_logic_vector(DIVIDEND_BITWIDTH - 1 downto 0);
		divisor		: in  std_logic_vector(DIVISOR_BITWIDTH - 1 downto 0);
		in_valid	: in  std_logic;
		in_ready	: out std_logic;

		quotient	: out std_logic_vector(DIVIDEND_BITWIDTH - 1 downto 0);
		remainder	: out std_logic_vector(DIVISOR_BITWIDTH - 1 downto 0);
		out_valid	: out std_logic;
		out_ready	: in  std_logic
	);
end div_multicycle_module;

architecture RTL of div_multicycle_module is
	signal stagecount	: integer range 0 to DIVIDEND_BITWIDTH;
	signal enable_sig	: std_logic;
	signal dr_in_sig	: std_logic_vector(divisor'range);
	signal dr_out_sig	: std_logic_vector(divisor'range);
	signal zr_in_sig	: std_logic_vector(divisor'length + dividend'length - 1 downto 0);
	signal zr_out_sig	: std_logic_vector(zr_in_sig'range);

begin

	process (clk, reset) begin
		if (reset = '1') then
			stagecount <= 0;

		elsif rising_edge(clk) then
			if (stagecount = 0) then
				if (in_valid = '1') then
					stagecount <= DIVIDEND_BITWIDTH;
				end if;
			else
				if (stagecount = 1) then
					if (out_ready = '1') then
						stagecount <= stagecount - 1;
					end if;
				else
					stagecount <= stagecount - 1;
				end if;
			end if;

		end if;
	end process;

	in_ready <= '1' when(stagecount = 0) else '0';
	out_valid <= '1' when(stagecount = 1) else '0';

	enable_sig <= '0' when(stagecount = 1 and out_ready = '0') else '1';

	dr_in_sig <= divisor when(stagecount = 0 and in_valid = '1') else dr_out_sig;
	zr_in_sig <= conv_std_logic_vector(0, DIVISOR_BITWIDTH) & dividend when(stagecount = 0 and in_valid = '1') else zr_out_sig;

	u0 : div_submodule
	generic map(
		DIVISOR_BITWIDTH	=> DIVISOR_BITWIDTH,
		DIVIDEND_BITWIDTH	=> DIVIDEND_BITWIDTH
	)
	port map(
		reset		=> reset,
		clk			=> clk,
		enable		=> enable_sig,

		zr_in		=> zr_in_sig,
		dr_in		=> dr_in_sig,

		zr_out		=> zr_out_sig,
		dr_out		=> dr_out_sig
	);

	quotient <= zr_out_sig(quotient'range);
	remainder <= zr_out_sig(zr_out_sig'left downto zr_out_sig'left - remainder'length + 1);

end RTL;



----------------------------------------------------------------------
--  Pipelined divider sub module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.div_submodule;

entity div_pipelined_module is
	generic(
		DIVIDEND_BITWIDTH	: integer;
		DIVISOR_BITWIDTH	: integer
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		dividend	: in  std_logic_vector(DIVIDEND_BITWIDTH - 1 downto 0);
		divisor		: in  std_logic_vector(DIVISOR_BITWIDTH - 1 downto 0);
		in_valid	: in  std_logic;
		in_ready	: out std_logic;

		quotient	: out std_logic_vector(DIVIDEND_BITWIDTH - 1 downto 0);
		remainder	: out std_logic_vector(DIVISOR_BITWIDTH - 1 downto 0);
		out_valid	: out std_logic;
		out_ready	: in  std_logic
	);
end div_pipelined_module;

architecture RTL of div_pipelined_module is
	signal enable_sig	: std_logic;
	signal zr_out_sig	: std_logic_vector(divisor'length + dividend'length - 1 downto 0);

	type DEF_DR_PIPE is array(0 to DIVIDEND_BITWIDTH) of std_logic_vector(divisor'range);
	signal dr_pipe_sig	: DEF_DR_PIPE;

	type DEF_ZR_PIPE is array(0 to DIVIDEND_BITWIDTH) of std_logic_vector(zr_out_sig'range);
	signal zr_pipe_sig	: DEF_ZR_PIPE;

	type DEF_VALID_PIPE is array(0 to DIVIDEND_BITWIDTH) of std_logic;
	signal valid_pipe_sig : DEF_VALID_PIPE;

begin

	enable_sig <= '0' when(valid_pipe_sig(DIVIDEND_BITWIDTH) = '1' and out_ready = '0') else '1';
	in_ready <= '0' when(in_valid = '1' and enable_sig = '0') else '1';

	zr_pipe_sig(0) <= conv_std_logic_vector(0, DIVISOR_BITWIDTH) & dividend;
	dr_pipe_sig(0) <= divisor;
	valid_pipe_sig(0) <= in_valid;

	gen : for i in 0 to DIVIDEND_BITWIDTH - 1 generate
		u : div_submodule
		generic map(
			DIVISOR_BITWIDTH	=> DIVISOR_BITWIDTH,
			DIVIDEND_BITWIDTH	=> DIVIDEND_BITWIDTH
		)
		port map(
			reset		=> reset,
			clk			=> clk,
			enable		=> enable_sig,

			zr_in		=> zr_pipe_sig(i),
			dr_in		=> dr_pipe_sig(i),
			valid_in	=> valid_pipe_sig(i),

			zr_out		=> zr_pipe_sig(i+1),
			dr_out		=> dr_pipe_sig(i+1),
			valid_out	=> valid_pipe_sig(i+1)
		);
	end generate;

	zr_out_sig <= zr_pipe_sig(DIVIDEND_BITWIDTH);

	quotient <= zr_out_sig(quotient'range);
	remainder <= zr_out_sig(zr_out_sig'left downto zr_out_sig'left - remainder'length + 1);
	out_valid <= valid_pipe_sig(DIVIDEND_BITWIDTH);

end RTL;



----------------------------------------------------------------------
--  top module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.div_multicycle_module;
use work.div_pipelined_module;

entity div_module is
	generic(
--		DIVIDER_TYPE		: string := "MULTICYCLE";
		DIVIDER_TYPE		: string := "PIPELINED";
		DIVIDEND_BITWIDTH	: integer := 16;	-- 被除数のビット幅 
		DIVISOR_BITWIDTH	: integer := 8		-- 除数のビット幅 
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		dividend	: in  std_logic_vector(DIVIDEND_BITWIDTH - 1 downto 0);
		divisor		: in  std_logic_vector(DIVISOR_BITWIDTH - 1 downto 0);
		in_valid	: in  std_logic;
		in_ready	: out std_logic;

		quotient	: out std_logic_vector(DIVIDEND_BITWIDTH - 1 downto 0);
		remainder	: out std_logic_vector(DIVISOR_BITWIDTH - 1 downto 0);
		out_valid	: out std_logic;
		out_ready	: in  std_logic := '1'
	);
end div_module;

architecture RTL of div_module is
begin

	gen_div_multicycle : if (DIVIDER_TYPE = "MULTICYCLE") generate
		u : div_multicycle_module
		generic map(
			DIVISOR_BITWIDTH	=> DIVISOR_BITWIDTH,
			DIVIDEND_BITWIDTH	=> DIVIDEND_BITWIDTH
		)
		port map(
			reset		=> reset,
			clk			=> clk,

			dividend	=> dividend,
			divisor		=> divisor,
			in_valid	=> in_valid,
			in_ready	=> in_ready,

			quotient	=> quotient,
			remainder	=> remainder,
			out_valid	=> out_valid,
			out_ready	=> out_ready
		);
	end generate;

	gen_div_pipelined : if (DIVIDER_TYPE = "PIPELINED") generate
		u : div_pipelined_module
		generic map(
			DIVISOR_BITWIDTH	=> DIVISOR_BITWIDTH,
			DIVIDEND_BITWIDTH	=> DIVIDEND_BITWIDTH
		)
		port map(
			reset		=> reset,
			clk			=> clk,

			dividend	=> dividend,
			divisor		=> divisor,
			in_valid	=> in_valid,
			in_ready	=> in_ready,

			quotient	=> quotient,
			remainder	=> remainder,
			out_valid	=> out_valid,
			out_ready	=> out_ready
		);
	end generate;



end RTL;
