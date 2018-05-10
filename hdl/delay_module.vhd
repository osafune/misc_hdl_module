-- ===================================================================
-- TITLE : Data delay module
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2018/02/09 -> 2018/05/05
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


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity delay_module is
	generic(
		DATA_BITWIDTH		: integer := 8;		-- データのビット幅 
		DELAY_CLOCKNUMBER	: integer := 10		-- 遅延させるクロック数(1以上) 
	);
	port(
		clk			: in  std_logic;
		enable		: in  std_logic := '1';

		data_in		: in  std_logic_vector(DATA_BITWIDTH-1 downto 0);
		data_out	: out std_logic_vector(DATA_BITWIDTH-1 downto 0)
	);
end delay_module;

architecture RTL of delay_module is
	type DLY_ARRAY is array(0 to DELAY_CLOCKNUMBER-1) of std_logic_vector(DATA_BITWIDTH-1 downto 0);
	signal d_reg : DLY_ARRAY;

begin

	process (clk) begin
		if rising_edge(clk) then
			if (enable = '1') then
				d_reg(0) <= data_in;

				if (DELAY_CLOCKNUMBER > 1) then
					for i in 1 to DELAY_CLOCKNUMBER-1 loop
						d_reg(i) <= d_reg(i-1);
					end loop;
				end if;
			end if;
		end if;
	end process;

	data_out <= d_reg(DELAY_CLOCKNUMBER-1);



end RTL;
