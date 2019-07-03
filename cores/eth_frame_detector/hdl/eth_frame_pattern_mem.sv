/*
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/

module eth_frame_pattern_mem
(
	input logic clk,

	// MEM_PA

	input logic mem_pa_req,
	input logic mem_pa_we,
	output logic mem_pa_ack,

	input logic [10:0] mem_pa_addr,
	input logic [29:0] mem_pa_wdata,
	output logic [29:0] mem_pa_rdata,

	// MEM_PB

	input logic mem_pb_clk,
	input logic [10:0] mem_pb_addr,
	output logic [29:0] mem_pb_rdata
);
	// mem_pb_clk clock domain

	logic mem_wenable;
	logic [10:0] mem_pa_addr_cdc;
	logic [29:0] mem_pa_wdata_cdc, mem_pa_rdata_cdc;
	logic mem_pa_req_cdc, mem_pa_ack_cdc, mem_pa_we_cdc;

	always_ff @(posedge mem_pb_clk) begin
		if(mem_pa_req_cdc & ~mem_pa_ack_cdc) begin
			mem_wenable <= mem_pa_we_cdc;
			mem_pa_ack_cdc <= 1'b1;
		end else begin
			mem_wenable <= 1'b0;

			if(~mem_pa_req_cdc) begin
				mem_pa_ack_cdc <= 1'b0;
			end
		end
	end

	pattern_mem U0
	(
		.clk(mem_pb_clk),

		.a(mem_pa_addr_cdc),
		.d(mem_pa_wdata_cdc),
		.we(mem_wenable),
		.qspo(mem_pa_rdata_cdc),

		.dpra(mem_pb_addr),
		.qdpo(mem_pb_rdata)
	);

	// clock domain crossing

	sync_ffs #(43, 2) U1
	(
		.clk(mem_pb_clk),
		.data_in({mem_pa_wdata, mem_pa_addr, mem_pa_we, mem_pa_req}),
		.data_out({mem_pa_wdata_cdc, mem_pa_addr_cdc, mem_pa_we_cdc, mem_pa_req_cdc})
	);

	sync_ffs #(31, 2) U2
	(
		.clk(clk),
		.data_in({mem_pa_rdata_cdc, mem_pa_ack_cdc}),
		.data_out({mem_pa_rdata, mem_pa_ack})
	);
endmodule