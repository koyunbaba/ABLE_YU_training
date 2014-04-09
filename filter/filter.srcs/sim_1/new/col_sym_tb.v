`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/09 22:29:11
// Design Name: 
// Module Name: col_sym_tb
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


module col_sym_tb;

    reg clk;
    reg resetn;
    reg en;
    
    reg [8*5-1:0] din;
    reg           din_valid;
    
    reg [11:0]    width;
    reg [11:0]    height;
    
    wire [8*5-1:0]    dout;
    wire              dout_valid;

	col_sym col_sym_uut
	(
		.clk(clk),
		.resetn(resetn),
		.en(en),
		
		.din(din),
		.din_valid(din_valid),
		
		.width(width),
		.height(height),
		
		.dout(dout),
		.dout_valid(dout_valid)
	);
	
	parameter clk_period = 10;
	initial clk = 0;
	always #(clk_period/2) clk = ~clk;
	
	integer i;
	reg	[11:0] count;
	
	initial begin
	
		resetn = 1'b0;
		
		width = 9;
		height = 9;
		
		#100
		
		resetn = 1'b1;
	end
	
	always@(posedge clk) begin
		if( resetn == 1'b0 ) begin
		
			count <= 0;			
		end
		else begin
		
			if( din_valid == 1'b1 ) begin
			
				if( count == width ) begin
				
					count <= 0;				
				end
				else begin
				
					count <= count + 1;
				end
			end
		end
	end
	
	always@(posedge clk) begin
	
		if( resetn == 1'b0 ) begin
		
			for( i = 0; i < 5; i = i + 1) begin
			
				din[8*i +: 8] <= 5-i;
			end

			din_valid <= 1'b0;
			en <= 1'b0;
			
		end
		else begin

			if( count == width ) begin
			
				din[8*0 +: 8] <= din[8*0 +: 8] + 1;
				
				for( i = 1; i < 5; i = i + 1) begin
			
					din[8*i +: 8] <= din[8*(i-1) +: 8];
				end

			end
			
			din_valid <= 1'b1;
			en <= 1'b1;
		end
	end
endmodule
