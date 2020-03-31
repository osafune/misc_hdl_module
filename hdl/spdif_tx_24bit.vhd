-- ===================================================================
-- TITLE : S/PDIF Encoder
--
--     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2005/09/26 -> 2005/09/30
--
--     UPDATE : 2016/10/05
--            : 2019/08/12 ライセンスアップデート
--            : 2020/02/04 192kHz/24bit化対応 
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
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity spdif_tx_24bit is
	generic(
		COPYRIGHTS		: string := "ENABLE";		-- "ENALBE", "NONE"
		CLOCK_ACCURACY	: string := "STANDARD";		-- "STANDARD", "VARIABLE", "HIQUALITY"
		COPY_CONTROL	: string := "NONE";			-- "NONE", "ONCE", "LIMIT"
		CATEGORY_CODE	: std_logic_vector(7 downto 0) := "00000000"	-- source category code
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic := '1';	-- 128fs Pulse width 1clock time
		first_frame	: out std_logic;
		end_frame	: out std_logic;

		freq_code	: in  std_logic_vector(3 downto 0) := "0000";
						-- 0000 : 44.1kHz
						-- 0010 : 48kHz
						-- 0011 : 32kHz
						-- 1000 : 88.2kHz
						-- 1010 : 96kHz
						-- 1100 : 176.4kHz
						-- 1110 : 192kHz
		dlen_code	: in  std_logic_vector(3 downto 0) := "0000";
						-- 0000 : none
						-- 0010 : 16bit
						-- 1010 : 20bit
						-- 1011 : 24bit
		pcmdata_l	: in  std_logic_vector(23 downto 0);
		pcmdata_r	: in  std_logic_vector(23 downto 0);

		spdif_out	: out std_logic
	);
end spdif_tx_24bit;

architecture RTL of spdif_tx_24bit is
	constant FRAME_MAX		: integer := 192-1;
	constant SUBFRAME_MAX	: integer := 2-1;
	constant PCM_L_SUBFRAME	: integer := 0;
	constant PCM_R_SUBFRAME	: integer := 1;

	constant B_PREAMBLE		: std_logic_vector(2 downto 0) := "001";
	constant M_PREAMBLE		: std_logic_vector(2 downto 0) := "100";
	constant W_PREAMBLE		: std_logic_vector(2 downto 0) := "010";

	constant CATEGORY_GENERAL		: std_logic_vector(7 downto 0) := "00000000";
	constant CATEGORY_CD			: std_logic_vector(7 downto 0) := "00000001";
	constant CATEGORY_MO			: std_logic_vector(7 downto 0) := "00001001";
	constant CATEGORY_MD			: std_logic_vector(7 downto 0) := "01001001";
	constant CATEGORY_BROADCAST		: std_logic_vector(7 downto 0) := "00001110";
	constant CATEGORY_BROADCAST_JP	: std_logic_vector(7 downto 0) := "00000100";
	constant CATEGORY_BROADCAST_EU	: std_logic_vector(7 downto 0) := "00001100";
	constant CATEGORY_BROADCAST_US	: std_logic_vector(7 downto 0) := "01100100";
	constant CATEGORY_SOFTWARE		: std_logic_vector(7 downto 0) := "01000100";
	constant CATEGORY_PCM_CODEC		: std_logic_vector(7 downto 0) := "10000010";
	constant CATEGORY_MIXER			: std_logic_vector(7 downto 0) := "10010010";
	constant CATEGORY_CONVERTER		: std_logic_vector(7 downto 0) := "10011010";
	constant CATEGORY_SAMPLER		: std_logic_vector(7 downto 0) := "10100010";
	constant CATEGORY_DAT			: std_logic_vector(7 downto 0) := "10000011";
	constant CATEGORY_VTR			: std_logic_vector(7 downto 0) := "10001011";
	constant CATEGORY_DCC			: std_logic_vector(7 downto 0) := "11000011";
	constant CATEGORY_SYNTH			: std_logic_vector(7 downto 0) := "10000101";
	constant CATEGORY_MIC			: std_logic_vector(7 downto 0) := "10001101";
	constant CATEGORY_ADC			: std_logic_vector(7 downto 0) := "10010110";
	constant CATEGORY_MEMORY		: std_logic_vector(7 downto 0) := "10001000";
	constant CATEGORY_TEST			: std_logic_vector(7 downto 0) := "11000000";


	signal frame_num		: integer range 0 to FRAME_MAX;
	signal subframe_num		: integer range 0 to SUBFRAME_MAX;
	signal amblecode_sig	: std_logic_vector(2 downto 0);
	signal pcmdata_sig		: std_logic_vector(23 downto 0);

	signal copyrights_sig	: std_logic;
	signal channelno_sig	: std_logic_vector(3 downto 0);
	signal clkaccur_sig		: std_logic_vector(1 downto 0);
	signal copycontrol_sig	: std_logic_vector(1 downto 0);
	signal statbit_sig		: std_logic_vector(FRAME_MAX downto 0);
	signal status_bit_sig	: std_logic;


	component spdif_tx_subframe_enc
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic := '1';

		frame_end	: out std_logic;

		amble_code	: in  std_logic_vector(2 downto 0);
		aux_code	: in  std_logic_vector(3 downto 0) := "0000";
		sample_code	: in  std_logic_vector(19 downto 0);
		valid_bit	: in  std_logic := '0';
		user_bit	: in  std_logic := '0';
		status_bit	: in  std_logic;

		spdif_out	: out std_logic
	);
	end component;
	signal frame_end_sig	: std_logic;

begin

	-- タイミング信号の生成 

	process(clk, reset)begin
		if (reset = '1') then
			frame_num <= 0;
			subframe_num <= 0;

		elsif rising_edge(clk) then
			if (clk_ena = '1' and frame_end_sig = '1') then

				if (subframe_num /= SUBFRAME_MAX) then	-- subframeが最大かどうか 
					subframe_num <= subframe_num + 1;
				else
					subframe_num <= 0;
					if (frame_num /= FRAME_MAX) then	-- frame数が最大かどうか 
						frame_num <= frame_num + 1;
					else
						frame_num <= 0;
					end if;
				end if;

			end if;
		end if;
	end process;

	first_frame <= '1' when(subframe_num = 0) else '0';
	end_frame   <= '1' when(subframe_num = SUBFRAME_MAX) else '0';


	-- プリアンブルシンボルの設定 

	amblecode_sig <= B_PREAMBLE when(frame_num = 0 and subframe_num = 0) else
					 M_PREAMBLE when(frame_num /= 0 and subframe_num = 0) else
					 W_PREAMBLE;


	-- オーディオデータの設定 

	pcmdata_sig <= 	pcmdata_l when(subframe_num = PCM_L_SUBFRAME) else
					pcmdata_r when(subframe_num = PCM_R_SUBFRAME) else
					(others=>'X');


	-- ステータスビットの設定 

	copyrights_sig <= '0' when(COPYRIGHTS = "ENABLE") else '1';

	clkaccur_sig <=
			"01" when(CLOCK_ACCURACY = "HIQUALITY") else
			"10" when(CLOCK_ACCURACY = "VARIABLE") else
			"00";

	channelno_sig <=
			"0001" when(subframe_num = PCM_L_SUBFRAME) else
			"0010" when(subframe_num = PCM_R_SUBFRAME) else
			"0000";

	copycontrol_sig <=
			"01" when(COPY_CONTROL = "ONCE") else
			"11" when(COPY_CONTROL = "LIMIT") else
			"00";

	statbit_sig(0) <= '0';							-- 民生用コード 
	statbit_sig(1) <= '0';							-- オーディオデータ 
	statbit_sig(2) <= copyrights_sig;				-- 著作権情報設定 
	statbit_sig(4 downto 3) <= "00";				-- エンファシス設定 
	statbit_sig(5) <= '0';							-- ２チャネルオーディオ 
	statbit_sig(7 downto 6) <= "00";				-- モード０ 
	statbit_sig(15 downto 8) <= CATEGORY_CODE;		-- 機器カテゴリ設定 
	statbit_sig(19 downto 16) <= "0000";			-- ソース番号０ 
	statbit_sig(23 downto 20) <= channelno_sig;		-- チャネル番号指定 
	statbit_sig(27 downto 24) <= freq_code;			-- サンプリング周波数設定 
	statbit_sig(29 downto 28) <= clkaccur_sig;		-- クロック精度設定 
	statbit_sig(31 downto 30) <= "00";				-- 予約 
	statbit_sig(35 downto 32) <= dlen_code;			-- 有効データ長 
	statbit_sig(39 downto 36) <= "0000";			-- オリジナルサンプリング周波数（指定無し） 
	statbit_sig(41 downto 40) <= copycontrol_sig;	-- コピー制限設定 
	statbit_sig(FRAME_MAX downto 42) <= (others=>'0');	-- 予約 

	status_bit_sig <= statbit_sig(frame_num);


	-- サブフレームエンコーダ 

	U : spdif_tx_subframe_enc
		port map(
			reset		=> reset,
			clk			=> clk,
			clk_ena		=> clk_ena,
			frame_end	=> frame_end_sig,
			amble_code	=> amblecode_sig,
			aux_code	=> pcmdata_sig(3 downto 0),
			sample_code	=> pcmdata_sig(23 downto 4),
			valid_bit	=> '0',
			user_bit	=> '0',
			status_bit	=> status_bit_sig,
			spdif_out	=> spdif_out
		);


end RTL;



----------------------------------------------------------------------
--  S/PDIF サブフレームエンコーダ 
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity spdif_tx_subframe_enc is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		clk_ena		: in  std_logic := '1';

		frame_end	: out std_logic;

		amble_code	: in  std_logic_vector(2 downto 0);
		aux_code	: in  std_logic_vector(3 downto 0) := "0000";
		sample_code	: in  std_logic_vector(19 downto 0);
		valid_bit	: in  std_logic := '0';
		user_bit	: in  std_logic := '0';
		status_bit	: in  std_logic;

		spdif_out	: out std_logic
	);
end spdif_tx_subframe_enc;

architecture RTL of spdif_tx_subframe_enc is
	signal slot_counter	: std_logic_vector(5 downto 0);

	signal amblebit_sig	: std_logic_vector(7 downto 0);
	signal sendbit_sig	: std_logic_vector(31 downto 0);
	signal amble_reg	: std_logic_vector(2 downto 0);
	signal auxcode_reg	: std_logic_vector(3 downto 0);
	signal sample_reg	: std_logic_vector(19 downto 0);
	signal valid_reg	: std_logic;
	signal userbit_reg	: std_logic;
	signal status_reg	: std_logic;

	signal bit_reg		: std_logic;
	signal send_symbol	: std_logic;
	signal amble_symbol	: std_logic;
	signal party_reg	: std_logic;

	signal spdifout_sig	: std_logic;
	signal spdifout_reg	: std_logic;

begin

	amblebit_sig(3 downto 0) <= "0111";
	amblebit_sig(6 downto 4) <= amble_reg;
	amblebit_sig(7) <= '0';

	sendbit_sig(3 downto 0) <= "XXXX";
	sendbit_sig(7 downto 4) <= auxcode_reg;
	sendbit_sig(27 downto 8) <= sample_reg;
	sendbit_sig(28) <= valid_reg;
	sendbit_sig(29) <= userbit_reg;
	sendbit_sig(30) <= status_reg;
	sendbit_sig(31) <= party_reg;

	frame_end <= '1' when(slot_counter = "111111") else '0';

	spdifout_sig <= amble_symbol when(slot_counter(5 downto 3) = "000") else send_symbol;

	process(clk, reset)begin
		if (reset = '1') then
			slot_counter <= (others=>'0');
			send_symbol  <= '0';
			party_reg    <= '0';
			spdifout_reg <= '0';

		elsif rising_edge(clk) then
			if (clk_ena = '1') then
				slot_counter <= slot_counter + '1';

				if (slot_counter = "000000") then		-- 送出データのラッチ 
					amble_reg   <= amble_code;
					auxcode_reg <= aux_code;
					sample_reg  <= sample_code;
					valid_reg   <= valid_bit;
					userbit_reg <= user_bit;
					status_reg  <= status_bit;
				end if;

				if (slot_counter(5 downto 3) = "000") then
					party_reg <= '0';
					if (send_symbol = '0') then			-- プリアンブルシンボル 
						amble_symbol <= amblebit_sig(CONV_INTEGER(slot_counter(2 downto 0)));
					else
						amble_symbol <= not amblebit_sig(CONV_INTEGER(slot_counter(2 downto 0)));
					end if;
				else
					if (slot_counter(0) = '0') then		-- 前半シンボル 
						bit_reg <= sendbit_sig(CONV_INTEGER(slot_counter(5 downto 1)));
						send_symbol <= not send_symbol;
					else								-- 後半シンボル 
						party_reg <= party_reg xor bit_reg;
						if (bit_reg = '1') then
							send_symbol <= not send_symbol;
						end if;
					end if;
				end if;

				spdifout_reg <= spdifout_sig;

			end if;
		end if;
	end process;

	spdif_out <= spdifout_reg;



end RTL;
