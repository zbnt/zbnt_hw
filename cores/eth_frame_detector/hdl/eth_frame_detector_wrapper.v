/*
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/

module eth_frame_detector_w
(
	// S_AXI : AXI4-Lite slave interface (from PS)

	input wire s_axi_clk,
	input wire s_axi_resetn,

	input wire [15:0] s_axi_awaddr,
	input wire [2:0] s_axi_awprot,
	input wire s_axi_awvalid,
	output wire s_axi_awready,

	input wire [31:0] s_axi_wdata,
	input wire [3:0] s_axi_wstrb,
	input wire s_axi_wvalid,
	output wire s_axi_wready,

	output wire [1:0] s_axi_bresp,
	output wire s_axi_bvalid,
	input wire s_axi_bready,

	input wire [15:0] s_axi_araddr,
	input wire [2:0] s_axi_arprot,
	input wire s_axi_arvalid,
	output wire s_axi_arready,

	output wire [31:0] s_axi_rdata,
	output wire [1:0] s_axi_rresp,
	output wire s_axi_rvalid,
	input wire s_axi_rready,

	// M_AXIS_A : AXI4-Stream master interface (to TEMAC of iface A)

	input wire m_axis_a_clk,

	output wire [7:0] m_axis_a_tdata,
	output wire m_axis_a_tuser,
	output wire m_axis_a_tlast,
	output wire m_axis_a_tvalid,
	input wire m_axis_a_tready,

	output wire [15:0] pause_a_val,
	output wire pause_a_req,

	// S_AXIS_A : AXI4-Stream slave interface (from TEMAC of iface A)

	input wire s_axis_a_clk,

	input wire [7:0] s_axis_a_tdata,
	input wire s_axis_a_tuser,
	input wire s_axis_a_tlast,
	input wire s_axis_a_tvalid,

	// M_AXIS_B : AXI4-Stream master interface (to TEMAC of iface B)

	input wire m_axis_b_clk,

	output wire [7:0] m_axis_b_tdata,
	output wire m_axis_b_tuser,
	output wire m_axis_b_tlast,
	output wire m_axis_b_tvalid,
	input wire m_axis_b_tready,

	output wire [15:0] pause_b_val,
	output wire pause_b_req,

	// S_AXIS_B : AXI4-Stream slave interface (from TEMAC of iface B)

	input wire s_axis_b_clk,

	input wire [7:0] s_axis_b_tdata,
	input wire s_axis_b_tuser,
	input wire s_axis_b_tlast,
	input wire s_axis_b_tvalid,

	// Timer

	input wire [63:0] current_time,
	input wire time_running
);
	eth_frame_detector U0
	(
		// S_AXI

		.s_axi_clk(s_axi_clk),
		.s_axi_resetn(s_axi_resetn),

		.s_axi_awaddr(s_axi_awaddr),
		.s_axi_awprot(s_axi_awprot),
		.s_axi_awvalid(s_axi_awvalid),
		.s_axi_awready(s_axi_awready),

		.s_axi_wdata(s_axi_wdata),
		.s_axi_wstrb(s_axi_wstrb),
		.s_axi_wvalid(s_axi_wvalid),
		.s_axi_wready(s_axi_wready),

		.s_axi_bresp(s_axi_bresp),
		.s_axi_bvalid(s_axi_bvalid),
		.s_axi_bready(s_axi_bready),

		.s_axi_araddr(s_axi_araddr),
		.s_axi_arprot(s_axi_arprot),
		.s_axi_arvalid(s_axi_arvalid),
		.s_axi_arready(s_axi_arready),

		.s_axi_rdata(s_axi_rdata),
		.s_axi_rresp(s_axi_rresp),
		.s_axi_rvalid(s_axi_rvalid),
		.s_axi_rready(s_axi_rready),

		// M_AXIS_A

		.m_axis_a_clk(m_axis_a_clk),

		.m_axis_a_tdata(m_axis_a_tdata),
		.m_axis_a_tuser(m_axis_a_tuser),
		.m_axis_a_tlast(m_axis_a_tlast),
		.m_axis_a_tvalid(m_axis_a_tvalid),
		.m_axis_a_tready(m_axis_a_tready),

		.pause_a_val(pause_a_val),
		.pause_a_req(pause_a_req),

		// S_AXIS_A

		.s_axis_a_clk(s_axis_a_clk),

		.s_axis_a_tdata(s_axis_a_tdata),
		.s_axis_a_tuser(s_axis_a_tuser),
		.s_axis_a_tlast(s_axis_a_tlast),
		.s_axis_a_tvalid(s_axis_a_tvalid),

		// M_AXIS_B

		.m_axis_b_clk(m_axis_b_clk),

		.m_axis_b_tdata(m_axis_b_tdata),
		.m_axis_b_tuser(m_axis_b_tuser),
		.m_axis_b_tlast(m_axis_b_tlast),
		.m_axis_b_tvalid(m_axis_b_tvalid),
		.m_axis_b_tready(m_axis_b_tready),

		.pause_b_val(pause_b_val),
		.pause_b_req(pause_b_req),

		// S_AXIS_B

		.s_axis_b_clk(s_axis_b_clk),

		.s_axis_b_tdata(s_axis_b_tdata),
		.s_axis_b_tuser(s_axis_b_tuser),
		.s_axis_b_tlast(s_axis_b_tlast),
		.s_axis_b_tvalid(s_axis_b_tvalid),

		// Timer

		.current_time(current_time),
		.time_running(time_running)
	);
endmodule