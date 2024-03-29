// ===================================================================
// TITLE : UART sender/reciever module
//
//     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
//     DATE   : 2015/12/27 -> 2015/12/27
//
//     UPDATE : 2020/04/02 module update (osafune@j7system.jp)
//              2021/01/04 add RTS/CTS (osafune@j7system.jp)
//              2022/02/17 add clk_ena signal (osafune@j7system.jp)
//              2022/11/25 add uart_to_bytes (osafune@j7system.jp)
// ===================================================================
//
// The MIT License (MIT)
// Copyright (c) 2020 J-7SYSTEM WORKS LIMITED.
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

`default_nettype none


// ===================================================================
// UART sender phy
// ===================================================================

module uart_phy_txd #(
	parameter CLOCK_FREQUENCY	= 50000000,
	parameter UART_BAUDRATE		= 115200,
	parameter UART_STOPBIT		= 1
) (
	// Interface: clk
	input wire			reset,
	input wire			clk,
	input wire			clk_ena,	// 未使用時'1'にする 

	// Interface: ST in
	output wire			in_ready,
	input wire			in_valid,
	input wire  [7:0]	in_data,

	// interface UART
	output wire			txd,
	input wire			cts			// フロー制御を使わない場合は'1'にする 
);


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */

	localparam CLOCK_DIVNUM = ((CLOCK_FREQUENCY + UART_BAUDRATE/2 - 1)/ UART_BAUDRATE) - 1;
	localparam INIT_BITCOUNT = (UART_STOPBIT > 1)? 11 : 10;


/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = reset;				// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = clk;				// モジュール内部駆動クロック 

	reg [11:0]		divcount_reg;
	reg [3:0]		bitcount_reg;
	reg [8:0]		txd_reg;
	reg [1:0]		ctsin_reg;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	assign in_ready = (bitcount_reg == 4'd0)? ctsin_reg[1] : 1'b0;
	assign txd = txd_reg[0];

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			divcount_reg <= 1'd0;
			bitcount_reg <= 1'd0;
			txd_reg <= 9'h1ff;
			ctsin_reg <= 2'b00;

		end
		else begin
			if (clk_ena) begin
				ctsin_reg <= {ctsin_reg[0], cts};

				if (bitcount_reg == 4'd0) begin
					if (in_valid && ctsin_reg[1]) begin
						divcount_reg <= CLOCK_DIVNUM[11:0];
						bitcount_reg <= INIT_BITCOUNT[3:0];
						txd_reg <= {in_data, 1'b0};
					end
				end
				else begin
					if (divcount_reg == 0) begin
						divcount_reg <= CLOCK_DIVNUM[11:0];
						bitcount_reg <= bitcount_reg - 1'd1;
						txd_reg <= {1'b1, txd_reg[8:1]};
					end
					else begin
						divcount_reg <= divcount_reg - 1'd1;
					end
				end

			end
		end
	end

endmodule



// ===================================================================
// UART reciever phy
// ===================================================================

module uart_phy_rxd #(
	parameter CLOCK_FREQUENCY	= 50000000,
	parameter UART_BAUDRATE		= 115200,
	parameter UART_STOPBIT		= 1
) (
	// Interface: clk
	input wire			reset,
	input wire			clk,
	input wire			clk_ena,	// 未使用時'1'にする 

	// Interface: ST out
	input wire			out_ready,
	output wire			out_valid,
	output wire [7:0]	out_data,
	output wire [1:0]	out_error,	// [0]:overflow, [1]:framing

	// interface UART
	input wire			rxd,
	output wire			rts			// フロー制御を使わない場合は開放にする 
);


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */

	localparam CLOCK_DIVNUM = ((CLOCK_FREQUENCY + UART_BAUDRATE/2 - 1)/ UART_BAUDRATE) - 1;
	localparam BIT_CAPTURE  = (CLOCK_DIVNUM / 2);


/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = reset;				// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = clk;				// モジュール内部駆動クロック 

	reg [2:0]		rxdin_reg;
	reg				rts_reg;

	reg [11:0]		divcount_reg;
	reg [3:0]		bitcount_reg;
	reg [7:0]		shift_reg;
	reg [7:0]		outdata_reg;
	reg				outvalid_reg;
	reg				overflow_reg;
	reg				stoperror_reg;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			rxdin_reg <= 3'b111;
			divcount_reg <= 1'd0;
			bitcount_reg <= 1'd0;
			shift_reg <= 8'h00;
			outvalid_reg <= 1'b0;
			outdata_reg  <= 8'h00;
			overflow_reg <= 1'b0;
			stoperror_reg <= 1'b0;
			rts_reg <= 1'b0;

		end
		else begin
			if (clk_ena) begin
				rxdin_reg <= {rxdin_reg[1:0], rxd};
				rts_reg <= (!out_ready && outvalid_reg)? 1'b0 : 1'b1;

				if (out_ready && outvalid_reg) begin
					overflow_reg <= 1'b0;
					outvalid_reg <= 1'b0;
				end
				else if (divcount_reg == 0 && bitcount_reg == 4'd1 && rxdin_reg[2] == 1'b1) begin
					overflow_reg <= outvalid_reg;
					outvalid_reg <= 1'b1;
				end


				if (bitcount_reg == 4'd0) begin
					if (rxdin_reg[2:1] == 2'b10) begin
						divcount_reg <= BIT_CAPTURE[11:0];
						bitcount_reg <= 4'd10;
					end
				end
				else begin
					if (divcount_reg == 0) begin
						divcount_reg <= CLOCK_DIVNUM[11:0];

						if (bitcount_reg == 4'd10) begin			// start bit check
							if (rxdin_reg[2] != 1'b0) begin
								bitcount_reg <= 4'd0;
							end
							else begin
								bitcount_reg <= bitcount_reg - 1'd1;
							end
						end
						else if (bitcount_reg == 4'd1) begin		// stop bit check
							if (rxdin_reg[2] != 1'b1) begin
								stoperror_reg <= 1'b1;
							end
							else begin
								outdata_reg  <= shift_reg;
								stoperror_reg <= 1'b0;
							end

							bitcount_reg <= bitcount_reg - 1'd1;
						end
						else begin
							bitcount_reg <= bitcount_reg - 1'd1;
							shift_reg <= {rxdin_reg[2], shift_reg[7:1]};
						end

					end
					else begin
						divcount_reg <= divcount_reg - 1'd1;
					end
				end

			end
		end
	end

	assign rts = rts_reg;
	assign out_valid = outvalid_reg;
	assign out_data  = outdata_reg;
	assign out_error = {stoperror_reg, overflow_reg};

endmodule



// ===================================================================
// UART to Avalon-ST Bytes stream input/output
// ===================================================================

module uart_to_bytes #(
	parameter CLOCK_FREQUENCY	= 50000000,
	parameter UART_BAUDRATE		= 115200,
	parameter UART_STOPBIT		= 1
) (
	// Interface: clk
	input wire			reset,
	input wire			clk,

	// Interface: ST in
	output wire			in_ready,
	input wire			in_valid,
	input wire  [7:0]	in_data,

	// Interface: ST out
	input wire			out_ready,
	output wire			out_valid,
	output wire [7:0]	out_data,

	// interface: coe UART
	output wire			txd,
	input wire			cts,		// フロー制御を使わない場合は'1'にする 
	input wire			rxd,
	output wire			rts			// フロー制御を使わない場合は開放にする 
);


/* ===== モジュール構造記述 ============== */

	uart_phy_txd #(
		.CLOCK_FREQUENCY	(CLOCK_FREQUENCY),
		.UART_BAUDRATE		(UART_BAUDRATE),
		.UART_STOPBIT		(UART_STOPBIT)
	)
	u_txd (
		.reset		(reset),
		.clk		(clk),
		.clk_ena	(1'b1),
		.in_ready	(in_ready),
		.in_valid	(in_valid),
		.in_data	(in_data),
		.txd		(txd),
		.cts		(cts)
	);

	uart_phy_rxd #(
		.CLOCK_FREQUENCY	(CLOCK_FREQUENCY),
		.UART_BAUDRATE		(UART_BAUDRATE),
		.UART_STOPBIT		(UART_STOPBIT)
	)
	u_rxd (
		.reset		(reset),
		.clk		(clk),
		.clk_ena	(1'b1),
		.out_ready	(out_ready),
		.out_valid	(out_valid),
		.out_data	(out_data),
		.out_error	(),
		.rxd		(rxd),
		.rts		(rts)
	);



endmodule
