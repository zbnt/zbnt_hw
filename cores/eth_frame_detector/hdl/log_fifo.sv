/*
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/

module log_fifo
(
	input logic clk,
	input logic rst,

	output logic wr_ack,
	output logic valid,

	output logic full,
	input logic [69:0] din,
	input logic wr_en,

	output logic empty,
	output logic [69:0] dout,
	input logic rd_en
);
	xpm_fifo_sync
	#(
		.DOUT_RESET_VALUE("0"),
		.ECC_MODE("no_ecc"),
		.FIFO_MEMORY_TYPE("block"),
		.FIFO_READ_LATENCY(1),
		.FIFO_WRITE_DEPTH(2048),
		.FULL_RESET_VALUE(0),
		.PROG_EMPTY_THRESH(10),
		.PROG_FULL_THRESH(10),
		.RD_DATA_COUNT_WIDTH(1),
		.READ_DATA_WIDTH(70),
		.READ_MODE("std"),
		.USE_ADV_FEATURES("1010"),
		.WAKEUP_TIME(0),
		.WRITE_DATA_WIDTH(70),
		.WR_DATA_COUNT_WIDTH(1)
	)
	U0
	(
		.wr_clk(clk),
		.rst(rst),

		.wr_ack(wr_ack),
		.data_valid(valid),

		.full(full),
		.din(din),
		.wr_en(wr_en),

		.empty(empty),
		.dout(dout),
		.rd_en(rd_en),

		.injectdbiterr(1'b0),
		.injectsbiterr(1'b0),
		.sleep(1'b0)
	);
endmodule