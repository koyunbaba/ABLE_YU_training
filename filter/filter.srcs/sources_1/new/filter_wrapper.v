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

module filter_wrapper(
		clk,
		resetn,
		col_neg,
		row_neg,
		din,	
		din_valid, 		
		kernel,		
		kernel_valid,
		dout,				
		dout_valid
    );
	parameter KERNEL_SIZE = 3;
	input	clk;
	input	resetn;
	input	col_neg;
	input 	row_neg;
	input	[8*KERNEL_SIZE-1:0]	din;
	input 	[5:0] kernel; 
	input	din_valid;
	input	kernel_valid;
	output	[31:0]	dout;
	output	dout_valid;	
	//-----------------------------------------------------------------------------
	
	reg [KERNEL_SIZE*KERNEL_SIZE*8-1:0]	din_sipo;
	reg [KERNEL_SIZE*KERNEL_SIZE*6-1:0]	kernel_sipo;
	reg [KERNEL_SIZE-1:0] sipo_valid;
	
	integer i;
	integer j;
	
	// serial in parallel out
	always@( posedge clk) begin
		if(resetn == 1'b0) begin			
			din_sipo <= 0;
			kernel_sipo <= 0;							
			sipo_valid <= 0;
		end
		else begin
			din_sipo[(KERNEL_SIZE-1)*KERNEL_SIZE*8 +: 8*KERNEL_SIZE] <= din;								
			din_sipo[0 +: (KERNEL_SIZE-1)*KERNEL_SIZE*8] <= din_sipo[KERNEL_SIZE*8 +: (KERNEL_SIZE-1)*KERNEL_SIZE*8];
			
			if(kernel_valid == 1'b1) begin
				kernel_sipo[0+:8] <= kernel;	
				kernel_sipo[6+:KERNEL_SIZE*KERNEL_SIZE*6-6] <= kernel_sipo[0+:KERNEL_SIZE*KERNEL_SIZE*6-6];							
			end
			
			sipo_valid <= {sipo_valid, din_valid};
			
		end		
	end
	
	
	
	filter #(.KERNEL_SIZE(KERNEL_SIZE))	filter_uut
	(
		.clk(clk),
		.resetn(resetn),
		.col_neg(col_neg),
		.row_neg(row_neg),
		.din(din_sipo), //[71:0], 9 * 8, 0~255
		.kernel(kernel_sipo), //[53:0], 9 * 6, -32~31			
		.din_valid( &sipo_valid ), // valid when all sipo_valid is 1'b1
		.dout(dout), //[15:0], signed 16bit
		.dout_valid(dout_valid)		
	);
	
	
endmodule
