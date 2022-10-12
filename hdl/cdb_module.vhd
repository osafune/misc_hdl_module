-- ===================================================================
-- TITLE : Clock domain bridge module
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2018/05/10 -> 2018/05/10
--
--     UPDATE : 2022/08/05 S.OSAFUNE
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
--  Simple level-signal bridge module
----------------------------------------------------------------------
--  レベル信号のブリッジ 

library IEEE;
use IEEE.std_logic_1164.all;

entity cdb_signal_module is
	port(
		in_rst			: in  std_logic := '0';
		in_clk			: in  std_logic;
		in_sig			: in  std_logic;

		out_rst			: in  std_logic := '0';
		out_clk			: in  std_logic;
		out_sig			: out std_logic;
		out_riseedge	: out std_logic;
		out_falledge	: out std_logic
	);
end cdb_signal_module;

architecture RTL of cdb_signal_module is
	signal in_reg		: std_logic;
	signal out_reg		: std_logic_vector(2 downto 0);

	attribute altera_attribute : string;
	attribute altera_attribute of RTL : architecture is
	(
		"-name SDC_STATEMENT ""set_false_path -from [get_registers *cdb_signal_module:*\|in_reg] -to [get_registers *cdb_signal_module:*\|out_reg\[0\]]"""
	);

begin

	process (in_clk, in_rst) begin
		if (in_rst = '1') then
			in_reg <= '0';
		elsif rising_edge(in_clk) then
			in_reg <= in_sig;
		end if;
	end process;

	process (out_clk, out_rst) begin
		if (out_rst = '1') then
			out_reg <= "000";
		elsif rising_edge(out_clk) then
			out_reg <= out_reg(1 downto 0) & in_reg;
		end if;
	end process;

	out_sig <= out_reg(1);

	out_riseedge <= '1' when(out_reg(1) = '1' and out_reg(2) = '0') else '0';
	out_falledge <= '1' when(out_reg(1) = '0' and out_reg(2) = '1') else '0';


end RTL;



----------------------------------------------------------------------
--  Stream signal bridge module
----------------------------------------------------------------------
--  AvalonST信号のブリッジ 

library IEEE;
use IEEE.std_logic_1164.all;

entity cdb_stream_module is
	port(
		in_rst		: in  std_logic := '0';
		in_clk		: in  std_logic;
		in_valid	: in  std_logic;
		in_ready	: out std_logic;

		out_rst		: in  std_logic := '0';
		out_clk		: in  std_logic;
		out_valid	: out std_logic;
		out_ready	: in  std_logic := '1'
	);
end cdb_stream_module;

architecture RTL of cdb_stream_module is
	signal inready_reg		: std_logic;
	signal in_dat_reg		: std_logic;
	signal out_dat_reg		: std_logic_vector(1 downto 0);

	signal outvalid_reg		: std_logic;
	signal out_ack_reg		: std_logic;
	signal in_ack_reg		: std_logic_vector(1 downto 0);

	attribute altera_attribute : string;
	attribute altera_attribute of RTL : architecture is
	(
		"-name SDC_STATEMENT ""set_false_path -from [get_registers *cdb_stream_module:*\|in_dat_reg] -to [get_registers *cdb_stream_module:*\|out_dat_reg\[0\]]"";" & 
		"-name SDC_STATEMENT ""set_false_path -from [get_registers *cdb_stream_module:*\|out_ack_reg] -to [get_registers *cdb_stream_module:*\|in_ack_reg\[0\]]"""
	);

begin

	process (in_clk, in_rst) begin
		if (in_rst = '1') then
			inready_reg <= '0';
			in_dat_reg <= '0';
			in_ack_reg <= "00";

		elsif rising_edge(in_clk) then
			in_ack_reg <= in_ack_reg(0) & out_ack_reg;

			if (inready_reg = '1') then
				if (in_valid = '1') then
					inready_reg <= '0';
					in_dat_reg <= '1';
				end if;
			else
				if (in_dat_reg = '1' and in_ack_reg(1) = '1') then
					in_dat_reg <= '0';
				elsif (in_dat_reg = '0' and in_ack_reg(1) = '0') then
					inready_reg <= '1';
				end if;
			end if;

		end if;
	end process;

	in_ready <= inready_reg;


	process (out_clk, out_rst) begin
		if (out_rst = '1') then
			outvalid_reg <= '0';
			out_ack_reg <= '0';
			out_dat_reg <= "00";

		elsif rising_edge(out_clk) then
			out_dat_reg <= out_dat_reg(0) & in_dat_reg;

			if (outvalid_reg = '0') then
				if (out_ack_reg = '0' and out_dat_reg(1) = '1') then
					outvalid_reg <= '1';
				elsif (out_ack_reg = '1' and out_dat_reg(1) = '0') then
					out_ack_reg <= '0';
				end if;
			else
				if (out_ready = '1') then
					outvalid_reg <= '0';
					out_ack_reg <= '1';
				end if;
			end if;

		end if;
	end process;

	out_valid <= outvalid_reg;


end RTL;



----------------------------------------------------------------------
--  Stream data bridge module
----------------------------------------------------------------------
--  AvalonST信号のブリッジ(データ付き) 

library IEEE;
use IEEE.std_logic_1164.all;

entity cdb_data_module is
	generic(
		DATA_BITWIDTH	: integer := 8		-- データ幅 
	);
	port(
		in_rst		: in  std_logic := '0';
		in_clk		: in  std_logic;
		in_valid	: in  std_logic;
		in_data		: in  std_logic_vector(DATA_BITWIDTH-1 downto 0);
		in_ready	: out std_logic;

		out_rst		: in  std_logic := '0';
		out_clk		: in  std_logic;
		out_valid	: out std_logic;
		out_data	: out std_logic_vector(DATA_BITWIDTH-1 downto 0);
		out_ready	: in  std_logic := '1'
	);
end cdb_data_module;

architecture RTL of cdb_data_module is
	signal inready_reg		: std_logic;
	signal in_dat_reg		: std_logic;
	signal out_dat_reg		: std_logic_vector(1 downto 0);
	signal indata_reg		: std_logic_vector(DATA_BITWIDTH-1 downto 0);

	signal outvalid_reg		: std_logic;
	signal out_ack_reg		: std_logic;
	signal in_ack_reg		: std_logic_vector(1 downto 0);
	signal outdata_reg		: std_logic_vector(DATA_BITWIDTH-1 downto 0);

	attribute altera_attribute : string;
	attribute altera_attribute of RTL : architecture is
	(
		"-name SDC_STATEMENT ""set_false_path -from [get_registers *cdb_data_module:*\|in_dat_reg] -to [get_registers *cdb_data_module:*\|out_dat_reg\[0\]]"";" &
		"-name SDC_STATEMENT ""set_false_path -from [get_registers *cdb_data_module:*\|out_ack_reg] -to [get_registers *cdb_data_module:*\|in_ack_reg\[0\]]"";" &
		"-name SDC_STATEMENT ""set_false_path -from [get_registers *cdb_data_module:*\|indata_reg\[*\]] -to [get_registers *cdb_data_module:*\|outdata_reg\[*\]]"""
	);

begin

	process (in_clk, in_rst) begin
		if (in_rst = '1') then
			inready_reg <= '0';
			in_dat_reg <= '0';
			in_ack_reg <= "00";

		elsif rising_edge(in_clk) then
			in_ack_reg <= in_ack_reg(0) & out_ack_reg;

			if (inready_reg = '1') then
				if (in_valid = '1') then
					inready_reg <= '0';
					in_dat_reg <= '1';
					indata_reg <= in_data;
				end if;
			else
				if (in_dat_reg = '1' and in_ack_reg(1) = '1') then
					in_dat_reg <= '0';
				elsif (in_dat_reg = '0' and in_ack_reg(1) = '0') then
					inready_reg <= '1';
				end if;
			end if;

		end if;
	end process;

	in_ready <= inready_reg;


	process (out_clk, out_rst) begin
		if (out_rst = '1') then
			outvalid_reg <= '0';
			out_ack_reg <= '0';
			out_dat_reg <= "00";

		elsif rising_edge(out_clk) then
			out_dat_reg <= out_dat_reg(0) & in_dat_reg;

			if (outvalid_reg = '0') then
				if (out_ack_reg = '0' and out_dat_reg(1) = '1') then
					outvalid_reg <= '1';
					outdata_reg <= indata_reg;
				elsif (out_ack_reg = '1' and out_dat_reg(1) = '0') then
					out_ack_reg <= '0';
				end if;
			else
				if (out_ready = '1') then
					outvalid_reg <= '0';
					out_ack_reg <= '1';
				end if;
			end if;

		end if;
	end process;

	out_valid <= outvalid_reg;
	out_data <= outdata_reg;


end RTL;
