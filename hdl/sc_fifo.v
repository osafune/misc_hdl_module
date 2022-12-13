// ===================================================================
// TITLE : Simple Single-Clock FIFO
//
//     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
//     DATE   : 2021/03/29 -> 2021/04/02
//
// ===================================================================
//
// The MIT License (MIT)
// Copyright (c) 2021 J-7SYSTEM WORKS LIMITED.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

// Verilog-2001 / IEEE 1364-2001
`default_nettype none

module sc_fifo #(
	parameter FIFO_WORD_WIDTH		= 4,
	parameter FIFO_DATA_WIDTH		= 8
) (
	input wire		clk,
	input wire		reset,
	input wire		init,						// 同期リセット 

	input wire		wrreq,						// オーバーラン保護なし 
	input wire  [FIFO_DATA_WIDTH-1:0]	data,
	input wire		rdack,						// アンダーラン保護なし, Show-ahead動作 
	output wire [FIFO_DATA_WIDTH-1:0]	q,

	output wire		empty,
	output wire		full,
	output wire [FIFO_WORD_WIDTH:0]		usedw
);


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */



/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = reset;		// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = clk;		// モジュール内部駆動クロック 

	reg [FIFO_WORD_WIDTH-1:0]	waddr_reg, raddr_reg;
	reg [FIFO_DATA_WIDTH-1:0]	ram[0:2**FIFO_WORD_WIDTH-1];
	reg [FIFO_DATA_WIDTH-1:0]	q_reg;
	reg [FIFO_WORD_WIDTH:0] 	usedw_reg;
	reg				empty_delay_reg;
	wire			empty_sig;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	// メモリブロック 

	always @(posedge clock_sig) begin
		if (wrreq) ram[waddr_reg] <= data;
		q_reg <= ram[raddr_reg + ((rdack)? 1'd1 : 1'd0)];
	end

	assign q = q_reg;


	// ワードカウンタ処理 

	assign empty_sig = (usedw_reg == 0)? 1'b1 : 1'b0;

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			waddr_reg <= 1'd0;
			raddr_reg <= 1'd0;
			usedw_reg <= 1'd0;
			empty_delay_reg <= 1'b1;
		end
		else begin
			if (init) begin
				waddr_reg <= 1'd0;
				raddr_reg <= 1'd0;
				usedw_reg <= 1'd0;
				empty_delay_reg <= 1'b1;
			end
			else begin
				if (wrreq) begin
					waddr_reg <= waddr_reg + 1'd1;
				end

				if (rdack) begin
					raddr_reg <= raddr_reg + 1'd1;
				end

				if (!wrreq && rdack) begin
					usedw_reg <= usedw_reg - 1'd1;
				end
				else if (wrreq && !rdack) begin
					usedw_reg <= usedw_reg + 1'd1;
				end

				empty_delay_reg <= empty_sig;
			end
		end
	end

	assign empty = (empty_sig || (!empty_sig && empty_delay_reg))? 1'b1 : 1'b0;
	assign full = usedw_reg[FIFO_WORD_WIDTH];
	assign usedw = usedw_reg;



endmodule
