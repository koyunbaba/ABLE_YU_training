`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/12 09:56:28
// Design Name: 
// Module Name: filter
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


module filter
	(
		input	clk,
		input	resetn,
		
		input	[7:0]	din00,
		input	[7:0]	din01,
		input	[7:0]	din02,
		input	[7:0]	din10,
		input	[7:0]	din11,
		input	[7:0]	din12,
		input	[7:0]	din20,
		input	[7:0]	din21,
		input	[7:0]	din22,
		
		input	din_valid,
		
		output	reg [7:0]	dout,				
		output	reg dout_valid
    );
        
    reg [15:0] temp;
    
    always@(*) begin
    
    	// TODO: improve this poor timing design
    	
    	/*
    	 * This is a Gaussian filter
    	 *
    	 *	1  2  1
    	 *  2  4  2
    	 *  1  2  1
    	 *
    	*/ 
	    temp <= {8'b0, din00} 			+ {7'b0, din01, 1'b0} + {8'b0, din02} 		+  			 
    			{7'b0, din10, 1'b0} 	+ {6'b0, din11, 2'b0} + {7'b0, din12, 1'b0} +
    			{8'b0, din20} 			+ {7'b0, din21, 1'b0} + {8'b0, din22} 		;
    end
    
    always@(posedge clk) begin
    	if( resetn == 1'b0 ) begin
    	
    		dout <= 0;
    		dout_valid <= 1'b0;
    	end
    	else begin
			
			// TODO: pay attention on dout_valid delay when pipelining adder tree     	
    		if( din_valid == 1'b1 ) begin    			    					
    			
    			dout <= temp[4 +: 8];
    			dout_valid <= 1'b1; 
    		end
    		else begin
    		
    			dout_valid <= 1'b0;
    		end	
    	end
    end
endmodule
