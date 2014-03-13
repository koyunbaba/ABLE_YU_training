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

		output	[7:0]	dout,				
		output	dout_valid
    );
   
        
    reg [15:0] temp;
    reg [15:0] filter_layer_1[4:0];
	reg [15:0] filter_layer_2[2:0];
	reg [15:0] filter_layer_3[1:0];
	reg [15:0] filter_layer_4;
	reg filter_layer_valid [3:0];		
	
	assign dout = filter_layer_4[4 +: 8];
	assign dout_valid = filter_layer_valid[3]; 
    
    always@(posedge clk) begin
    	if( resetn == 1'b0 ) begin    	
    		
			filter_layer_valid[0] <= 1'b0;
			filter_layer_valid[1] <= 1'b0;
			filter_layer_valid[2] <= 1'b0;
			filter_layer_valid[3] <= 1'b0;
			
			filter_layer_1[0] <= 1'b0;
			filter_layer_1[1] <= 1'b0;
			filter_layer_1[2] <= 1'b0;
			filter_layer_1[3] <= 1'b0;
			filter_layer_1[4] <= 1'b0;
			                  
			filter_layer_2[0] <= 1'b0;
			filter_layer_2[1] <= 1'b0;
			filter_layer_2[2] <= 1'b0;
			                  
			filter_layer_3[0] <= 1'b0;
			filter_layer_3[1] <= 1'b0;
			                  
			filter_layer_4    <= 1'b0;
			
    	end
    	else begin

		filter_layer_1[0] <= {8'b0, din00}+ {7'b0, din01, 1'b0};
		filter_layer_1[1] <= {8'b0, din02}+	{7'b0, din10, 1'b0};
		filter_layer_1[2] <= {6'b0, din11, 2'b0} + {7'b0, din12, 1'b0};
		filter_layer_1[3] <= {8'b0, din20}+ {7'b0, din21, 1'b0};
		filter_layer_1[4] <=  {8'b0, din22};			
		filter_layer_valid[0] <= din_valid;
		
		filter_layer_2[0] <= filter_layer_1[0] + filter_layer_1[1];
		filter_layer_2[1] <= filter_layer_1[2] + filter_layer_1[3];
		filter_layer_2[2] <= filter_layer_1[4];
		filter_layer_valid[1] <= filter_layer_valid[0];
		
		filter_layer_3[0] <= filter_layer_2[0] + filter_layer_2[1];
		filter_layer_3[1] <= filter_layer_2[2];
		filter_layer_valid[2] <= filter_layer_valid[1];
		
		filter_layer_4 <= (filter_layer_3[0] + filter_layer_3[1]);
		filter_layer_valid[3] <= filter_layer_valid[2];		
    	end
    end
endmodule
