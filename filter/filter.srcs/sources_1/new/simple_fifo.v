`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/02 11:11:48
// Design Name: 
// Module Name: simple_fifo
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
module simple_fifo
#(
	parameter LATENCY = 1,
	parameter SIZE = 8
)
(
	input clk,
	input resetn,
	input [SIZE-1:0] din,
	input en,
	output [SIZE-1:0] dout
);

	reg [SIZE-1:0] buffer [LATENCY-1:0];
	
	integer ii;
	assign dout = buffer[0];
	always@( posedge clk) begin
	
		if(resetn == 1'b0) begin
		
			for(ii = 0; ii < LATENCY; ii = ii + 1) begin
			
				buffer[ii] <= 0;
			end
		end
		else begin
			if(en == 1'b1) begin
			
				buffer[LATENCY-1] <= din;
				for(ii = 0; ii < LATENCY - 1; ii = ii + 1) begin
				
					buffer[ii] <= buffer[ii+1];
				end		
			end
		end	
	end
endmodule
	
