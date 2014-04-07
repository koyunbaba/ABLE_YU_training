`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/04 12:59:19
// Design Name: 
// Module Name: row_sym_tb
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


module row_sym_tb;
	
	parameter FILTER_SZ = 7;
	parameter MAX_WIDTH = 32;
	
	reg 		clk;
	reg 		resetn;
	reg			en;
	
	reg [7:0]	din;
	reg 		din_valid;
	
	reg	[$clog2(MAX_WIDTH)-1:0]	width;
	
	
	wire	[ 8*FILTER_SZ-1:0 ]	dout;
	wire						dout_valid;

	row_sym #(
		.FILTER_SZ(FILTER_SZ),	
		.MAX_WIDTH(MAX_WIDTH)
	)
	row_sym_uut
	(
		.clk(clk),
		.resetn(resetn),
		.en(en),
		
		.din(din),
		.din_valid(din_valid),
		
		.width(width),
		
		
		.dout(dout),
		.dout_valid(dout_valid)
	);

	parameter clk_period = 10;
	initial clk = 0;
	always #(clk_period/2) clk = ~clk;
	
	initial begin
		
		resetn = 0;
		width = MAX_WIDTH-1;
		#100
		
		resetn = 1'b1;
	end
	
	always@(posedge clk) begin
	
		if( resetn == 1'b0 ) begin
		
			din <= 0;			
			din_valid <= 1'b0;
			en 	<= 1'b0;
			
		end
		else begin
		
			
			en <= 1'b1;
			
			if( din <= width ) begin
			
				din_valid <= 1'b1;
			end
			else begin
			
				din_valid <= 1'b0;
			end
			
			din <= din + 1;
			
		end	
	end
endmodule
