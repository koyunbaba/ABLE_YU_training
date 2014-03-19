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
		clk,
		resetn,
		din,		
		kernel,		
		din_valid,
		dout,				
		dout_valid
    );
	parameter KERNEL_SIZE = 5;
	input	clk;
	input	resetn;
	input	[KERNEL_SIZE*KERNEL_SIZE*8-1:0]	din;
	input 	[KERNEL_SIZE*KERNEL_SIZE*6-1:0] kernel;
	input	din_valid;
	output	[31:0]	dout;
	output	dout_valid;
	//--------------------------------------------------------------------------
	
	
	parameter total_size = KERNEL_SIZE * KERNEL_SIZE;
	parameter layer_1_preadder_size = (KERNEL_SIZE/2)*KERNEL_SIZE;
	parameter layer_1_mul_size = KERNEL_SIZE;
	parameter layer_1_size = layer_1_preadder_size + layer_1_mul_size;
	parameter adder_tree_layer = $clog2(layer_1_size)+1;
	parameter latency = 3+adder_tree_layer+1;// layer 1: 3, layer2~  adder tree, the last 1 for output buf
	
    wire [8:0] din_array [total_size-1:0];
    wire [5:0] kernel_array [total_size-1:0];	
    genvar i;
	genvar j;
    generate
        for(i = 0; i < total_size; i = i + 1) begin
            assign din_array[i] = {1'b0, din[i*8 +: 8]}; // for signed num 0~255
            assign kernel_array[i] = kernel[i*6 +: 6]; // -32~31
        end     
		
    endgenerate  	
	
	reg  [latency-1:0] layer_valid;		
	wire [14:0] layer_1_2 [layer_1_size-1:0];//(a+b)*c	
  
	generate 	
		for(i = 0; i < KERNEL_SIZE; i = i + 1) 
		begin:layer1 // all multiplications are done at layer 1
			for(j = 0; j < KERNEL_SIZE/2; j = j + 1)
			begin: layer1_1 // for symmetric coeff, pre-adder dsp48e1 is used.
				xbip_dsp48_macro_preadder_l3 pre_adder1 (// (A+D)*B  latency 3
					.CLK(clk),  // input CLK
					.SEL(kernel_array[0] != kernel_array[KERNEL_SIZE-1]),  // determine (D+A)*B OR (D-A)*B
					.D(din_array[i*KERNEL_SIZE+j]),      // input [8 : 0] D
					.B(kernel_array[i*KERNEL_SIZE+j]),      // input [5 : 0] B					
					.A(din_array[(i+1)*KERNEL_SIZE-j-1]),      // input [8 : 0] A
					.P(layer_1_2[i*(KERNEL_SIZE/2)+j])      // output [14 : 0] P
				);		
			end
			// the remains are multiply only
			xbip_dsp48_macro_mul_l3 mul_ABC (//A*B, latency 3
				.CLK(clk),  // input CLK
				.A(din_array[i*KERNEL_SIZE+KERNEL_SIZE/2]),      // input [8 : 0] A
				.B(kernel_array[i*KERNEL_SIZE+KERNEL_SIZE/2]),      // input [5 : 0] B
				.P(layer_1_2[layer_1_preadder_size+i])      // output [15 : 0] P
			);
		end		
    endgenerate
    
	// adder tree
	
	
	parameter adder_tree_data_size = (2**adder_tree_layer);	
	reg [31:0] adder_tree_data [adder_tree_data_size-1:0];	// array tree structure
	reg  [31:0] layer_end;		
	assign dout = layer_end;
	assign dout_valid = layer_valid[latency-1]; 
    integer k; 
    always@(posedge clk) begin    
        
    	if( resetn == 1'b0 ) begin    
			layer_valid <= 0;    		
			layer_end <= 0;
			for(k = 0; k < adder_tree_data_size; k = k + 1) begin
				adder_tree_data[k] <= 0;
			end		
			
    	end
    	else begin			
		
			//adder tree
			//layer 2
			for(k = 0; k < layer_1_size; k = k + 1) begin
				adder_tree_data[adder_tree_data_size/2+k] <= {{17{layer_1_2[k][14]}}, layer_1_2[k]};
			end			
			
			
			//layer 3 ~ ...
			for(k = 1; k < adder_tree_data_size/2; k = k + 1) begin
				adder_tree_data[k] <= adder_tree_data[k*2]+adder_tree_data[k*2+1];
			end
	   	    layer_end <= adder_tree_data[1];
			
			layer_valid <= {layer_valid, din_valid};
        end
    end	
	
endmodule
