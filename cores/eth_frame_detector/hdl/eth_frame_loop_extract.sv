/*
	This Source Code Form is subject to the terms of the Mozilla Public
	License, v. 2.0. If a copy of the MPL was not distributed with this
	file, You can obtain one at https://mozilla.org/MPL/2.0/.
*/

module eth_frame_loop_extract #(parameter C_NUM_SCRIPTS = 4, parameter C_AXIS_LOG_WIDTH = 64, parameter C_EXTRACT_FIFO_SIZE = 2048)
(
	input logic clk,
	input logic rst_n,
	input logic srst,
	input logic enable,

	input logic clk_log,
	input logic [63:0] current_time,
	output logic [63:0] overflow_count,

	// S_AXIS

	input logic [7:0] s_axis_tdata,
	input logic [17*C_NUM_SCRIPTS:0] s_axis_tuser,  // {C_NUM_SCRIPTS * {PARAM_B, INSTR_B, MATCHED}, FCS_INVALID}
	input logic s_axis_tlast,
	input logic s_axis_tvalid,

	// M_AXIS_FRAME

	output logic [C_AXIS_LOG_WIDTH-1:0] m_axis_frame_tdata,
	output logic m_axis_frame_tvalid,
	input logic m_axis_frame_tready,

	// M_AXIS_CTL

	output logic [119:0] m_axis_ctl_tdata, // {8 * {MATCHED}, SIZE, NUMBER, TIMESTAMP}
	output logic m_axis_ctl_tvalid,
	input logic m_axis_ctl_tready
);
	// Flags

	logic [C_NUM_SCRIPTS-1:0] extract_byte, script_match;

	for(genvar i = 0; i < C_NUM_SCRIPTS; ++i) begin
		always_comb begin
			script_match[i] = s_axis_tuser[17*i+1];
			extract_byte[i] = &s_axis_tuser[17*i+2:17*i+1];
		end
	end

	// CDC

	logic [63:0] current_time_cdc, overflow_count_cdc;

	bus_cdc #(64, 2) U0
	(
		.clk_src(clk_log),
		.clk_dst(clk),
		.data_in(current_time),
		.data_out(current_time_cdc)
	);

	bus_cdc #(64, 2) U1
	(
		.clk_src(clk),
		.clk_dst(clk_log),
		.data_in(overflow_count_cdc),
		.data_out(overflow_count)
	);

	// Push values to FIFO

	enum logic [1:0] {ST_WAIT_FIFO, ST_WRITE_FRAME, ST_WRITE_CTL, ST_OVERFLOW} state;
	logic [C_AXIS_LOG_WIDTH/8-1:0] count_1h;
	logic [15:0] count;

	logic in_frame;
	logic [31:0] frame_number;

	logic [C_AXIS_LOG_WIDTH-1:0] s_axis_frame_tdata;
	logic s_axis_frame_tvalid, s_axis_frame_tready;

	logic [119:0] s_axis_ctl_tdata;
	logic s_axis_ctl_tvalid, s_axis_ctl_tready;

	always_ff @(posedge clk) begin
		if(~rst_n) begin
			state <= ST_WAIT_FIFO;

			count <= 16'd0;
			count_1h <= 'd1;

			in_frame <= 1'b0;
			frame_number <= 32'd0;

			overflow_count_cdc <= 64'd0;

			s_axis_ctl_tdata <= '0;
			s_axis_ctl_tvalid <= 1'b0;
			s_axis_frame_tvalid <= 1'b0;
		end else begin
			if(s_axis_frame_tvalid & s_axis_frame_tready) begin
				s_axis_frame_tvalid <= 1'b0;
			end

			if(s_axis_ctl_tvalid & s_axis_ctl_tready) begin
				s_axis_ctl_tvalid <= 1'b0;
			end

			if(s_axis_tvalid) begin
				in_frame <= ~s_axis_tlast;

				if(s_axis_tlast && script_match != '0) begin
					frame_number <= frame_number + 32'd1;
				end
			end

			case(state)
				ST_WAIT_FIFO: begin
					count <= 16'd0;
					count_1h <= 'd1;

					if(s_axis_frame_tready & s_axis_ctl_tready & ~in_frame & enable) begin
						state <= ST_WRITE_FRAME;
					end
				end

				ST_WRITE_FRAME: begin
					if(s_axis_tvalid) begin
						if(extract_byte != 'd0) begin
							if(count_1h[C_AXIS_LOG_WIDTH/8-1] | s_axis_tlast) begin
								if(s_axis_frame_tready) begin
									if(s_axis_tlast) begin
										state <= ST_WRITE_CTL;
										s_axis_ctl_tdata <= {'0, script_match, count + 16'd1, frame_number, current_time_cdc};
										s_axis_ctl_tvalid <= 1'b1;
									end
								end else begin
									state <= ST_OVERFLOW;
									s_axis_ctl_tdata <= {'0, count + 16'd1, frame_number, current_time_cdc};

									if(s_axis_tlast) begin
										overflow_count_cdc <= overflow_count_cdc + 64'd1;
									end
								end

								s_axis_frame_tvalid <= 1'b1;
							end

							count <= count + 16'd1;
							count_1h <= {count_1h[C_AXIS_LOG_WIDTH/8-2:0], count_1h[C_AXIS_LOG_WIDTH/8-1]};
						end else if(s_axis_tlast) begin
							state <= ST_WRITE_CTL;
							s_axis_ctl_tdata <= {'0, script_match, count, frame_number, current_time_cdc};
							s_axis_ctl_tvalid <= 1'b1;

							if(~count_1h[0]) begin
								s_axis_frame_tvalid <= 1'b1;
							end
						end
					end else if(~in_frame & ~enable) begin
						state <= ST_WAIT_FIFO;
					end
				end

				ST_WRITE_CTL: begin
					if(s_axis_ctl_tvalid & s_axis_ctl_tready) begin
						state <= ST_WAIT_FIFO;
					end
				end

				ST_OVERFLOW: begin
					if(s_axis_frame_tready & s_axis_frame_tvalid) begin
						state <= ST_WRITE_CTL;
						s_axis_ctl_tvalid <= 1'b1;
					end
				end
			endcase

			if(srst) begin
				overflow_count_cdc <= 64'd0;
			end else if(state != ST_WRITE_FRAME && s_axis_tvalid && s_axis_tlast) begin
				overflow_count_cdc <= overflow_count_cdc + 64'd1;
			end
		end
	end

	for(genvar i = 0; i < C_AXIS_LOG_WIDTH/8; ++i) begin
		always_ff @(posedge clk) begin
			if(~rst_n) begin
				s_axis_frame_tdata[i*8+7:i*8] <= 8'd0;
			end else if(state == ST_WRITE_FRAME && s_axis_tvalid && extract_byte != 'd0 && count_1h[i]) begin
				s_axis_frame_tdata[i*8+7:i*8] <= s_axis_tdata;
			end
		end
	end

	// FIFO instances

	axis_fifo
	#(
		.C_DEPTH(C_EXTRACT_FIFO_SIZE / (C_AXIS_LOG_WIDTH/8)),
		.C_MEM_TYPE("block"),
		.C_CDC_STAGES(2),

		.C_DATA_WIDTH(C_AXIS_LOG_WIDTH)
	)
	U2
	(
		.s_clk(clk),
		.s_rst_n(rst_n),

		.s_axis_tdata(s_axis_frame_tdata),
		.s_axis_tvalid(s_axis_frame_tvalid),
		.s_axis_tready(s_axis_frame_tready),

		.m_clk(clk_log),

		.m_axis_tdata(m_axis_frame_tdata),
		.m_axis_tvalid(m_axis_frame_tvalid),
		.m_axis_tready(m_axis_frame_tready)
	);

	axis_fifo
	#(
		.C_DEPTH(C_EXTRACT_FIFO_SIZE / 64),
		.C_MEM_TYPE("block"),
		.C_CDC_STAGES(2),

		.C_DATA_WIDTH(120)
	)
	U3
	(
		.s_clk(clk),
		.s_rst_n(rst_n),

		.s_axis_tdata(s_axis_ctl_tdata),
		.s_axis_tvalid(s_axis_ctl_tvalid),
		.s_axis_tready(s_axis_ctl_tready),

		.m_clk(clk_log),

		.m_axis_tdata(m_axis_ctl_tdata),
		.m_axis_tvalid(m_axis_ctl_tvalid),
		.m_axis_tready(m_axis_ctl_tready)
	);
endmodule
