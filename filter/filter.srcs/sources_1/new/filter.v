`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/17 18:08:10
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

//symmetric filter
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
	parameter latency = 9;// layer 1: 3, layer 2: 3, layer 3~5: 3, 3+3+3 = 9
    wire [8:0] din_array [8:0];
    wire [5:0] kernel_array [8:0];
	wire plus_or_minus [2:0]; // 0 for plus, 1 for minus.
    genvar i;
    generate
        for(i = 0; i < 9; i = i + 1) begin
            assign din_array[i] = {1'b0, din[i*8 +: 8]}; // for signed num 0~255
            assign kernel_array[i] = kernel[i*6 +: 6]; // -32~31
        end     
		for(i = 0; i < 3; i = i + 1) begin
			assign plus_or_minus[i] = (kernel_array[i*3] == kernel_array[i*3+2]) ? 1'b0 : 1'b1;
		end
    endgenerate  
	
	
	reg  [latency-1:0] layer_valid;		
	wire [14:0] layer_1_2 [2:0];//(a+b)*c
	reg  [8:0]  layer_1_2_buf [3*3-1:0];// din_array 1 4 7  buffer (din1 -> 0->1->2) (din3 -> 3->4->5) (din5 -> 6->7->8) latency of layer 1 is 3
	wire [15:0] layer_2_3 [2:0];// a*b+c result, latency of layer 3 is 3		
	reg  [15:0] layer_3_4 [1:0];
	reg  [15:0] layer_4_5;
	reg  [15:0] layer_5_end;	
	
	assign dout = layer_5_end;
	assign dout_valid = layer_valid[latency-1]; 
  
	generate 	
		for(i = 0; i < 3; i = i + 1) 
		begin:layer1 // (0 +/- 2)*kernel   (3 +/- 5)*kernel  (6 +/- 8)*kernel
		     xbip_dsp48_macro_preadder_l3 pre_adder (// (A+D)*B  latency 3
                .CLK(clk),  // input CLK
                .A(din_array[i*3]),      // input [8 : 0] A
                .B(kernel_array[i*3]),      // input [5 : 0] B
                .D(plus_or_minus[i] == 1'b0 ? din_array[i*3+2] : -din_array[i*3+2]),      // input [8 : 0] D
                .P(layer_1_2[i])      // output [14 : 0] P
            );			
		end

		for(i = 0; i < 3; i = i + 1) 
		begin:layer2// (1, 4, 7)*kernel + pre-result
			xbip_dsp48_macro_macc_l3 macc_ABC (//A*B+C, latency 3
				.CLK(clk),  // input CLK
				.A(layer_1_2_buf[i*3+2]),      // input [8 : 0] A
				.B(kernel_array[i*3+1]),      // input [5 : 0] B
				.C(layer_1_2[i]),      // input [14 : 0] C
				.P(layer_2_3[i])      // output [15 : 0] P
			);
		end		
		
    endgenerate
    
    integer j;    
    always@(posedge clk) begin    
        
    	if( resetn == 1'b0 ) begin    
			layer_valid <= 0;
    		
			
			for(j = 0; j < 9; j = j + 1)begin
				layer_1_2_buf[j] <= 9'b0;							
			end		
			
			for(j = 0; j < 2; j = j + 1)begin						
				layer_3_4[j] <= 16'b0;			
			end		
			layer_4_5 <= 16'b0;			
			layer_5_end <= 16'b0;
			
    	end
    	else begin
			//layer 1 buffer for 1 4 7 
			for(j = 0; j < 3; j = j + 1) begin
				layer_1_2_buf[j*3] <= din_array[j*3+1];		
				layer_1_2_buf[j*3+1] <= layer_1_2_buf[j*3];
				layer_1_2_buf[j*3+2] <= layer_1_2_buf[j*3+1];
			end		
		
			//adder tree
			//layer 3
			layer_3_4[0] <= layer_2_3[0] + layer_2_3[1];
			layer_3_4[1] <= layer_2_3[2];			
			
			//layer 4
			layer_4_5 <= layer_3_4[0] + layer_3_4[1];
			
			//layer 5
			layer_5_end <= layer_4_5;
			
			//layer_valid <= {layer_valid, din_valid};
			layer_valid <= {layer_valid, din_valid};
	   	    /*layer_valid[0] <= din_valid;
		    for(j = 1; j < latency; j = j + 1)begin
				layer_valid[j] <= layer_valid[j-1];		
            end*/
        end
    end	
	
endmodule
