`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/19 16:23:09
// Design Name: 
// Module Name: filter_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module filter_wrapper
#(
	parameter KERNEL_SIZE = 3,
	parameter MAX_IMAGE_SIZE = 10, // bit 
	parameter M_BYTES_IN = 4
)
(
	input	clk,
	input	resetn,
	input	col_neg,
	input 	row_neg,
	input	[M_BYTES_IN*8-1:0]	din,
	input 	[5:0] kernel,
	input	din_valid,
	input	en,
	input	kernel_valid,
	input   [MAX_IMAGE_SIZE-1:0] d_cols,
    input   [MAX_IMAGE_SIZE-1:0] d_rows,
	output	[32*M_BYTES_IN-1:0]	dout,
	output	[M_BYTES_IN-1:0] dout_valid
);	

	genvar gi;
	genvar gj;
	genvar gk;
	

	
	integer ii;
	integer ij;
	

	wire [KERNEL_SIZE*M_BYTES_IN*8-1:0] rowbuffer_out;
	wire rowbuffer_dout_valid;
	filter_rowbuffer #(.KERNEL_SIZE(KERNEL_SIZE), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE), .M_BYTES_IN(M_BYTES_IN)) rowbuffer_uut(
		.clk(clk),
		.resetn(resetn),
		.d_cols(d_cols),
		.d_rows(d_rows),	
		.din(din),	
		.din_valid(din_valid),
		.en(en),
		.dout(rowbuffer_out),
		.dout_valid(rowbuffer_dout_valid)
	);
	
	wire [M_BYTES_IN*KERNEL_SIZE*8-1:0] rowbuffer_switch_out;
	wire rowbuffer_switch_dout_valid;
	filter_rowbuffer_switch #(.KERNEL_SIZE(KERNEL_SIZE), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE), .M_BYTES_IN(M_BYTES_IN)) rowbuffer_switch_uut(
		.clk(clk),
		.resetn(resetn),
		.d_cols(d_cols),
		.d_rows(d_rows),
		.din(rowbuffer_out),	
		.din_valid(rowbuffer_dout_valid),
		.en(en),
		.dout(rowbuffer_switch_out),
		.dout_valid(rowbuffer_switch_dout_valid)
	);
	
	
	wire [(KERNEL_SIZE+M_BYTES_IN-1)*KERNEL_SIZE*8-1:0] window_out;
	wire [KERNEL_SIZE*KERNEL_SIZE*8-1:0] window_out_sub [M_BYTES_IN-1:0];
	wire filter_kernel_valid;
	
	filter_window #(.KERNEL_SIZE(KERNEL_SIZE), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE), .M_BYTES_IN(M_BYTES_IN)) window_uut(
		.clk(clk),
		.resetn(resetn),
		.d_cols(d_cols),
		.d_rows(d_rows),
		.din(rowbuffer_switch_out),	
		.din_valid(rowbuffer_switch_dout_valid),
		.en(en),
		.dout(window_out),
		.dout_valid(filter_kernel_valid)
	);	
	
	reg [KERNEL_SIZE*KERNEL_SIZE*6-1:0]	kernel_sipo;	
	
	generate	
		
		for(gi = 0; gi < M_BYTES_IN; gi = gi + 1) begin
		
			for(gj = 0; gj < KERNEL_SIZE; gj = gj + 1) begin
			
				for(gk = 0; gk < KERNEL_SIZE; gk = gk + 1) begin
				
					assign window_out_sub[gi][gj*KERNEL_SIZE*8 + gk*8 +: 8] = window_out[gj*(KERNEL_SIZE+M_BYTES_IN-1)*8 + gi*8 + gk*8 +: 8];							
				end
			end
		end			
	
		for(gi = 0; gi < M_BYTES_IN; gi = gi + 1) 
		begin: Multiple_Kernel		
		
			filter #(.KERNEL_SIZE(KERNEL_SIZE))	filter_uut
			(
				.clk(clk),
				.resetn(resetn),
				.col_neg(col_neg),
				.row_neg(row_neg),
				.din(window_out_sub[gi]), //[71:0], 9 * 8, 0~255
				.kernel(kernel_sipo), //[53:0], 9 * 6, -32~31			
				.din_valid( filter_kernel_valid ), 
				.dout(dout[gi*32 +: 32]), //[15:0], signed 16bit
				.dout_valid(dout_valid[gi])		
			);		
		end
	endgenerate
		
	// kernel serial in parallel out
	always@( posedge clk) begin
		if(resetn == 1'b0) begin
		
			kernel_sipo <= 0;								
		end
		else begin		
			if(kernel_valid == 1'b1) begin
			
				kernel_sipo[0+:8] <= kernel;	
				kernel_sipo[6+:KERNEL_SIZE*KERNEL_SIZE*6-6] <= kernel_sipo[0+:KERNEL_SIZE*KERNEL_SIZE*6-6];					
			end			
		end		
	end	
	
	
	
endmodule
