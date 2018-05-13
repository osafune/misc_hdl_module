-- ===================================================================
-- TITLE : DVI Transmitter (Pseudo-differential)
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2005/10/12 -> 2005/10/13
--
--     UPDATE : 2014/10/12 MAX10 support
--            : 2018/05/13 License update
--
-- ===================================================================

-- The MIT License (MIT)
-- Copyright (c) 2005-2018 J-7SYSTEM WORKS LIMITED.
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
--  TMDS encoder
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity dvi_encoder_tmds_submodule is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		de_in		: in  std_logic;
		c1_in		: in  std_logic;
		c0_in		: in  std_logic;

		d_in		: in  std_logic_vector(7 downto 0);

		q_out		: out std_logic_vector(9 downto 0)
	);
end dvi_encoder_tmds_submodule;

architecture RTL of dvi_encoder_tmds_submodule is
	signal cnt		: integer range -8 to 8;

	signal qm_reg	: std_logic_vector(8 downto 0);
	signal de_reg	: std_logic;
	signal c_reg	: std_logic_vector(1 downto 0);
	signal qout_reg	: std_logic_vector(9 downto 0);

	-- バイト中のビット１の個数をカウント --
	function number1s(D:std_logic_vector(7 downto 0)) return integer is
		variable i,num	: integer;
	begin
		num := 0;

		for i in 0 to 7 loop
			if (D(i) = '1') then
				num := num + 1;
			end if;
		end loop;

		return num;
	end;

	-- バイト中のビット０の個数をカウント --
	function number0s(D:std_logic_vector(7 downto 0)) return integer is
		variable i,num	: integer;
	begin
		num := 0;

		for i in 0 to 7 loop
			if (D(i) = '0') then
				num := num + 1;
			end if;
		end loop;

		return num;
	end;

	-- XORエンコード --
	function encode1(D:std_logic_vector(7 downto 0)) return std_logic_vector is
		variable i		: integer;
		variable q_m	: std_logic_vector(8 downto 0);
	begin
		q_m(0) := D(0);

		for i in 1 to 7 loop
			q_m(i) := q_m(i - 1) xor D(i);
		end loop;

		q_m(8) := '1';

		return q_m;

	end;

	-- XNORエンコード --
	function encode0(D:std_logic_vector(7 downto 0)) return std_logic_vector is
		variable i		: integer;
		variable q_m	: std_logic_vector(8 downto 0);
	begin
		q_m(0) := D(0);

		for i in 1 to 7 loop
			q_m(i) := not(q_m(i - 1) xor D(i));
		end loop;

		q_m(8) := '0';

		return q_m;

	end;

begin

	-- 入力信号をラッチ --

	process (clk, reset) begin
		if (reset = '1') then
			de_reg <= '0';
			c_reg <= "00";

		elsif rising_edge(clk) then
			de_reg <= de_in;
			c_reg <= c1_in & c0_in;

			if (number1s(d_in) > 4 or (number1s(d_in) = 4 and d_in(0) = '0')) then
				qm_reg <= encode0(d_in);
			else
				qm_reg <= encode1(d_in);
			end if;

		end if;
	end process;


	-- データをTMDSにエンコード --

	process (clk, reset) begin
		if (reset = '1') then
			cnt <= 0;

		elsif rising_edge(clk) then
			if (de_reg = '1') then
				if (cnt = 0 or (number1s(qm_reg(7 downto 0)) = number0s(qm_reg(7 downto 0)))) then
					qout_reg(9) <= not qm_reg(8);
					qout_reg(8) <= qm_reg(8);

					if (qm_reg(8) = '0') then
						qout_reg(7 downto 0) <= not qm_reg(7 downto 0);
						cnt <= cnt + (number0s(qm_reg(7 downto 0)) - number1s(qm_reg(7 downto 0)));
					else
						qout_reg(7 downto 0) <= qm_reg(7 downto 0);
						cnt <= cnt + (number1s(qm_reg(7 downto 0)) - number0s(qm_reg(7 downto 0)));
					end if;

				else
					if ((cnt > 0 and number1s(qm_reg(7 downto 0)) > number0s(qm_reg(7 downto 0)))
							or (cnt < 0 and number0s(qm_reg(7 downto 0)) > number1s(qm_reg(7 downto 0)))) then
						qout_reg(9) <= '1';
						qout_reg(8) <= qm_reg(8);
						qout_reg(7 downto 0) <= not qm_reg(7 downto 0);

						if (qm_reg(8)='0') then
							cnt <= cnt + (number0s(qm_reg(7 downto 0)) - number1s(qm_reg(7 downto 0)));
						else
							cnt <= cnt + (number0s(qm_reg(7 downto 0)) - number1s(qm_reg(7 downto 0))) + 2;
						end if;

					else
						qout_reg(9) <= '0';
						qout_reg(8) <= qm_reg(8);
						qout_reg(7 downto 0) <= qm_reg(7 downto 0);

						if (qm_reg(8)='1') then
							cnt <= cnt + (number1s(qm_reg(7 downto 0)) - number0s(qm_reg(7 downto 0)));
						else
							cnt <= cnt + (number1s(qm_reg(7 downto 0)) - number0s(qm_reg(7 downto 0))) - 2;
						end if;

					end if;
				end if;

			else
				cnt <= 0;
				case c_reg is
				when "01" =>
					qout_reg <= "0010101011";
				when "10" =>
					qout_reg <= "0101010100";
				when "11" =>
					qout_reg <= "1010101011";
				when others =>
					qout_reg <= "1101010100";
				end case;

			end if;

		end if;
	end process;

	q_out <= qout_reg;


end RTL;


----------------------------------------------------------------------
-- Pseudo-differential transmitter
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity dvi_encoder_pdiff_submodule is
	generic(
		DEVICE_FAMILY	: string := "Cyclone III"	-- デバイスファミリ 
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;		-- Rise edge drive clock
		clk_x5		: in  std_logic;		-- Transmitter clock (It synchronizes with clk)

		data0_in	: in  std_logic_vector(9 downto 0);
		data1_in	: in  std_logic_vector(9 downto 0);
		data2_in	: in  std_logic_vector(9 downto 0);

		tx0_p		: out std_logic;
		tx0_n		: out std_logic;
		tx1_p		: out std_logic;
		tx1_n		: out std_logic;
		tx2_p		: out std_logic;
		tx2_n		: out std_logic;
		txc_p		: out std_logic;
		txc_n		: out std_logic
	);
end dvi_encoder_pdiff_submodule;

architecture RTL of dvi_encoder_pdiff_submodule is
	signal areset_sig	: std_logic;
	signal clk_dot_sig	: std_logic;
	signal clk_ser_sig	: std_logic;
	signal reset_n_sig	: std_logic := '0';

	signal data0_in_reg	: std_logic_vector(9 downto 0);
	signal data1_in_reg	: std_logic_vector(9 downto 0);
	signal data2_in_reg	: std_logic_vector(9 downto 0);

	signal start_reg	: std_logic_vector(4 downto 0);

	signal data0_ser_reg: std_logic_vector(9 downto 0);
	signal data1_ser_reg: std_logic_vector(9 downto 0);
	signal data2_ser_reg: std_logic_vector(9 downto 0);
	signal clock_ser_reg: std_logic_vector(9 downto 0);
	signal data_p_h_reg	: std_logic_vector(3 downto 0);
	signal data_p_l_reg	: std_logic_vector(3 downto 0);
	signal data_n_h_reg	: std_logic_vector(3 downto 0);
	signal data_n_l_reg	: std_logic_vector(3 downto 0);
	signal ddo_p_sig	: std_logic_vector(3 downto 0);
	signal ddo_n_sig	: std_logic_vector(3 downto 0);

begin

	-- クロック＆リセット生成 --

	areset_sig <= '1' when(reset = '1') else '0';

	clk_dot_sig <= clk;
	clk_ser_sig <= clk_x5;
	reset_n_sig <= not areset_sig;


	-- 内部クロックへの載せ替え --

	process (clk_dot_sig) begin
		if rising_edge(clk_dot_sig) then
			data0_in_reg <= data0_in;
			data1_in_reg <= data1_in;
			data2_in_reg <= data2_in;
		end if;
	end process;


	-- ラッチ信号の生成とシフトレジスタ --

	process (clk_ser_sig, reset_n_sig) begin
		if (reset_n_sig = '0') then
			start_reg <= "00001";

		elsif rising_edge(clk_ser_sig) then
			start_reg <= start_reg(0) & start_reg(4 downto 1);

			if (start_reg(0) = '1') then
				data0_ser_reg <= data0_in_reg;
				data1_ser_reg <= data1_in_reg;
				data2_ser_reg <= data2_in_reg;
				clock_ser_reg <= "0000011111";
			else
				data0_ser_reg <= "XX" & data0_ser_reg(9 downto 2);
				data1_ser_reg <= "XX" & data1_ser_reg(9 downto 2);
				data2_ser_reg <= "XX" & data2_ser_reg(9 downto 2);
				clock_ser_reg <= "XX" & clock_ser_reg(9 downto 2);
			end if;
		end if;
	end process;


	-- ビット出力 --

	process (clk_ser_sig) begin
		if rising_edge(clk_ser_sig) then
			data_p_h_reg <= clock_ser_reg(0) & data2_ser_reg(0) & data1_ser_reg(0) & data0_ser_reg(0);
			data_p_l_reg <= clock_ser_reg(1) & data2_ser_reg(1) & data1_ser_reg(1) & data0_ser_reg(1);
			data_n_h_reg <= not(clock_ser_reg(0) & data2_ser_reg(0) & data1_ser_reg(0) & data0_ser_reg(0));
			data_n_l_reg <= not(clock_ser_reg(1) & data2_ser_reg(1) & data1_ser_reg(1) & data0_ser_reg(1));
		end if;
	end process;

	u_ddo_p : altddio_out
	generic map (
		extend_oe_disable		=> "UNUSED",
		intended_device_family	=> DEVICE_FAMILY,
		invert_output			=> "OFF",
		lpm_type				=> "altddio_out",
		oe_reg					=> "UNUSED",
		power_up_high			=> "OFF",
		width					=> 4
	)
	port map (
		outclock	=> clk_ser_sig,
		datain_h	=> data_p_h_reg,
		datain_l	=> data_p_l_reg,
		dataout		=> ddo_p_sig
	);

	u_ddo_n : altddio_out
	generic map (
		extend_oe_disable		=> "UNUSED",
		intended_device_family	=> DEVICE_FAMILY,
		invert_output			=> "OFF",
		lpm_type				=> "altddio_out",
		oe_reg					=> "UNUSED",
		power_up_high			=> "OFF",
		width					=> 4
	)
	port map (
		outclock	=> clk_ser_sig,
		datain_h	=> data_n_h_reg,
		datain_l	=> data_n_l_reg,
		dataout		=> ddo_n_sig
	);

	tx0_p <= ddo_p_sig(0);
	tx0_n <= ddo_n_sig(0);
	tx1_p <= ddo_p_sig(1);
	tx1_n <= ddo_n_sig(1);
	tx2_p <= ddo_p_sig(2);
	tx2_n <= ddo_n_sig(2);
	txc_p <= ddo_p_sig(3);
	txc_n <= ddo_n_sig(3);


end RTL;


----------------------------------------------------------------------
-- top module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.dvi_encoder_tmds_submodule;
use work.dvi_encoder_pdiff_submodule;

entity dvi_encoder is
	generic(
		DEVICE_FAMILY	: string := "Cyclone III"	-- デバイスファミリ 
--		DEVICE_FAMILY	: string := "Cyclone IV E"
--		DEVICE_FAMILY	: string := "Cyclone V"
--		DEVICE_FAMILY	: string := "MAX 10"
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;		-- Rise edge drive clock
		clk_x5		: in  std_logic;		-- Transmitter clock (It synchronizes with clk)

		vga_r		: in  std_logic_vector(7 downto 0);
		vga_g		: in  std_logic_vector(7 downto 0);
		vga_b		: in  std_logic_vector(7 downto 0);
		vga_de		: in  std_logic;
		vga_hsync	: in  std_logic;
		vga_vsync	: in  std_logic;

		data0_p		: out std_logic;
		data0_n		: out std_logic;
		data1_p		: out std_logic;
		data1_n		: out std_logic;
		data2_p		: out std_logic;
		data2_n		: out std_logic;
		clock_p		: out std_logic;
		clock_n		: out std_logic
	);
end dvi_encoder;

architecture RTL of dvi_encoder is
	signal q_blu_sig	: std_logic_vector(9 downto 0);
	signal q_grn_sig	: std_logic_vector(9 downto 0);
	signal q_red_sig	: std_logic_vector(9 downto 0);

begin

	-- TMDSデータエンコード --

	u_enc_r : dvi_encoder_tmds_submodule
	port map (
		reset	=> reset,
		clk		=> clk,
		de_in	=> vga_de,
		c1_in	=> '0',
		c0_in	=> '0',
		d_in	=> vga_r,
		q_out	=> q_red_sig
	);

	u_enc_g : dvi_encoder_tmds_submodule
	port map (
		reset	=> reset,
		clk		=> clk,
		de_in	=> vga_de,
		c1_in	=> '0',
		c0_in	=> '0',
		d_in	=> vga_g,
		q_out	=> q_grn_sig
	);

	u_enc_b : dvi_encoder_tmds_submodule
	port map (
		reset	=> reset,
		clk		=> clk,
		de_in	=> vga_de,
		c1_in	=> vga_vsync,
		c0_in	=> vga_hsync,
		d_in	=> vga_b,
		q_out	=> q_blu_sig
	);


	-- シリアライザ --

	u_ser : dvi_encoder_pdiff_submodule
	generic map (
		DEVICE_FAMILY	=> DEVICE_FAMILY
	)
	port map (
		reset		=> reset,
		clk			=> clk,
		clk_x5		=> clk_x5,

		data0_in	=> q_blu_sig,
		data1_in	=> q_grn_sig,
		data2_in	=> q_red_sig,

		tx0_p		=> data0_p,
		tx0_n		=> data0_n,
		tx1_p		=> data1_p,
		tx1_n		=> data1_n,
		tx2_p		=> data2_p,
		tx2_n		=> data2_n,
		txc_p		=> clock_p,
		txc_n		=> clock_n
	);


end RTL;
