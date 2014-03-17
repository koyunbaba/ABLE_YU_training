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
		input	[71:0]	din,		
		input 	[53:0] 	kernel,		
		input	din_valid,
		output	[15:0]	dout,				
		output	dout_valid
    );
	parameter latency = 7;
    wire [8:0] din_array [8:0];
    wire [5:0] kernel_array [8:0];
    genvar i;
    generate
        for(i = 0; i < 9; i = i + 1) begin
            assign din_array[i] = {1'b0, din[i*8 +: 8]}; // for signed num 0~255
            assign kernel_array[i] = kernel[i*6 +: 6]; // -32~31
        end     
    endgenerate  
	
	
	reg  layer_valid [latency-1:0];		
	wire [14:0] layer_1_2 [4:0];
	reg  [8:0]  layer_1_2_buf [3:0];
	reg  [5:0]  layer_1_2_kernel [3:0];	
	wire [15:0] layer_2_3 [3:0];	
	reg  [15:0] layer_2_3_5 [2:0];//latency of layer2 is 3
	reg  [15:0] layer_3_4 [2:0];
	reg  [15:0] layer_4_5 [1:0];
	reg  [15:0] layer_5_end;
	
	
	assign dout = layer_5_end;
	assign dout_valid = layer_valid[latency-1]; 
  
	generate 	
		for(i = 0; i < 5; i = i + 1) 
		begin:layer1 // 0 2 4 6 8 mul kernel
			xbip_dsp48_macro_mul mulAB (//latency 1
			.CLK(clk),  // input CLK
			.A(din_array[i*2]),      // input [8 : 0] A
			.B(kernel_array[i*2]),      // input [5 : 0] B
			.P(layer_1_2[i])      // output [14 : 0] P
			);
		end

		for(i = 0; i < 4; i = i + 1) 
		begin:layer2// 1 * kernel + 0 (pre mul) ...
			xbip_dsp48_macro_macc_l3 macc_ABC (//latency 3
				.CLK(clk),  // input CLK
				.A(layer_1_2_buf[i]),      // input [8 : 0] A
				.B(layer_1_2_kernel[i]),      // input [5 : 0] B
				.C(layer_1_2[i]),      // input [14 : 0] C
				.P(layer_2_3[i])      // output [15 : 0] P
			);
		end		
		
    endgenerate
    
    integer j;    
    always@(posedge clk) begin    
        
    	if( resetn == 1'b0 ) begin    	
    		for(j = 0; j < latency; j = j + 1)begin
				layer_valid[j] <= 1'b0;			
			end	
			
			for(j = 0; j < 4; j = j + 1)begin
				layer_1_2_buf[j] <= 9'b0;			
				layer_1_2_kernel[j] <= 6'b0;			
			end		
			
			for(j = 0; j < 3; j = j + 1)begin
				layer_2_3_5[j] <= 16'b0;			
				layer_3_4[j] <= 16'b0;			
			end		
			layer_4_5[0] <= 16'b0;
			layer_4_5[1] <= 16'b0;
			layer_5_end <= 16'b0;
			
			
    	end
    	else begin
			//layer 1
			for(j = 0; j < 4; j = j + 1) begin
				layer_1_2_buf[j] <= din_array[j*2+1];
				layer_1_2_kernel[j] <= kernel_array[j*2+1];
			end		
		
			//layer 2
			layer_2_3_5[0] <= layer_1_2[4];
			layer_2_3_5[1] <= layer_2_3_5[0];
			layer_2_3_5[2] <= layer_2_3_5[1];
		
			//layer 3
			layer_3_4[0] <= layer_2_3[0] + layer_2_3[1];
			layer_3_4[1] <= layer_2_3[2] + layer_2_3[3];
			layer_3_4[2] <= layer_2_3_5[2];
			
			//layer 4
			layer_4_5[0] <= layer_3_4[0] + layer_3_4[1];
			layer_4_5[1] <= layer_3_4[2];
			
			//layer 5
			layer_5_end <= layer_4_5[0] + layer_4_5[1];
			
	   	    layer_valid[0] <= din_valid;
		    for(j = 1; j < latency; j = j + 1)begin
				layer_valid[j] <= layer_valid[j-1];		
            end
        end
    end	
	
endmodule
