`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/19 15:57:32
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
		clk,
		resetn,
		col_neg,
		row_neg,
		din,		
		din_valid,
		kernel,		
		dout,				
		dout_valid		
    );
	parameter KERNEL_SIZE = 3;
	input	clk;
	input	resetn;
	input	col_neg;
	input 	row_neg;
	input	[KERNEL_SIZE*KERNEL_SIZE*8-1:0]	din;
	input 	[KERNEL_SIZE*KERNEL_SIZE*6-1:0] kernel;
	input	din_valid;
	output	[31:0]	dout;
	output	dout_valid;
	//--------------------------------------------------------------------------
	
	
	parameter total_size = KERNEL_SIZE * KERNEL_SIZE;
	parameter layer_1_size = (KERNEL_SIZE/2+1)*(KERNEL_SIZE/2);
	parameter layer_2_size = layer_1_size;	
	parameter adder_tree_layer = $clog2(layer_1_size)+1;
	parameter latency = 6+3+adder_tree_layer+1;// layer 1: 3, layer2~  adder tree, the last 1 for output buf
	
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
	wire [14:0] layer_1_2 [layer_1_size-1:0];//(d+a)*b	
	wire [15:0] layer_2_3 [layer_2_size-1:0];//(d+a)*b+c
	reg  [8:0] 	layer_1_3 [5:0]; // center of center data buf, latency of layer 1 and 2 is 6
	wire [16:0] layer_1_3_4;
	reg  [16:0] layer_3_4 [layer_1_size*3-1:3];//(d+a)*b+c
	
	
	// take KERNEL_SIZE = 3 for example   
	//   00 01 02
	// [ 10 11 12 ]
	//   20 21 22
	// use pre-adder dsp48e1 in layer 1, and there are KERNEL_SIZE^2 / 2 calculating.   latency is 2
	// 		(A+D)*B						 (00 + 02) * kernel,  (10 + 12) * kernel	
	//										=> layer1_0 		=> layer1_1
	//
	// use pre-adder & MACC in layer2, and there are KERNEL_SIZE^2 / 2 calculating.  	latency is 6
	// 		(A+D)*B+C					 (20 + 22) * kernel + layer1_0,  (01 + 21) * kernel	+ layer1_1
	//										=> layer2_0			=> layer2_1
	//
	// element 11 is just buffering for 6 latency, in order to apply MACC.
	//
	// use MACC in layer3, and there is only one calculating.  	latency is 3
	//		A*B+C						 11 * kernel + layer2_0
	//
	// the results of layer3 and the remain layer2 which is just buffering in layer3 are the input of the adder-tree
	generate 	
		for(i = 0; i < (KERNEL_SIZE/2) + 1; i = i + 1) 
		begin:layer1 
			for(j = 0; j < (KERNEL_SIZE/2); j = j + 1)
			begin: layer1_1 // for symmetric coeff, pre-adder dsp48e1 is used. latency = 2
				xbip_dsp48_macro_preadder_l2 preadder1 (
					.CLK(clk),  // input CLK
					.SEL(col_neg),  // input [0 : 0] SEL
					.A(din_array[(i+1)*KERNEL_SIZE-j-1]),      // input [8 : 0] A
					.B(kernel_array[i*KERNEL_SIZE+j]),      // input [5 : 0] B
					.D(din_array[i*KERNEL_SIZE+j]),      // input [8 : 0] D
					.P(layer_1_2[i*(KERNEL_SIZE/2)+j])      // output [14 : 0] P
				);	
			end
		end		
		for(i = KERNEL_SIZE/2+1; i < KERNEL_SIZE; i = i + 1) 
		begin:layer2_1 //latency = 6 including layer1 latency
			for(j = 0; j < KERNEL_SIZE/2; j = j + 1) begin
				xbip_dsp48_macro_preadder_macc_l6 preadder_macc2_1 (
					.CLK(clk),  // input CLK
					.SEL(col_neg),  // input [0 : 0] SEL
					.A(din_array[(i+1)*KERNEL_SIZE-j-1]),      // input [8 : 0] A latency = 6
					.B(kernel_array[i*KERNEL_SIZE+j]),      // input [5 : 0] B 
					.C(layer_1_2[(i-(KERNEL_SIZE/2)-1)*(KERNEL_SIZE/2)+j]),      // input [14 : 0] C latency = 4
					.D(din_array[i*KERNEL_SIZE+j]),      // input [8 : 0] D latency = 6
					.P(layer_2_3[(i-(KERNEL_SIZE/2)-1)*(KERNEL_SIZE/2)+j])      // output [15 : 0] P latency = 6
				);
			end
		end	
		for(i = 0; i < KERNEL_SIZE/2; i = i + 1) 
		begin:layer2_2 //latency = 6 including layer1 latency
			xbip_dsp48_macro_preadder_macc_l6 preadder_macc2_2 (
				.CLK(clk),  // input CLK
				.SEL(row_neg),  // input [0 : 0] SEL
				.A(din_array[(KERNEL_SIZE-i-1)*KERNEL_SIZE + KERNEL_SIZE/2]),      // input [8 : 0] A latency = 6
				.B(kernel_array[i*KERNEL_SIZE + (KERNEL_SIZE/2)]),      // input [5 : 0] B 
				.C(layer_1_2[(KERNEL_SIZE/2)*(KERNEL_SIZE/2)+i]),      // input [14 : 0] C latency = 4
				.D(din_array[i*KERNEL_SIZE + (KERNEL_SIZE/2)]),      // input [8 : 0] D latency = 6
				.P(layer_2_3[(KERNEL_SIZE/2)*(KERNEL_SIZE/2)+i])      // output [15 : 0] P latency = 6
			);
		end
		
		//layer 3
		xbip_dsp48_macro_macc_l3 macc3 (
			.CLK(clk),  // input CLK
			.A(layer_1_3[5]),      // input [8 : 0] A
			.B(kernel_array[(KERNEL_SIZE/2)*KERNEL_SIZE + (KERNEL_SIZE/2)]),      // input [5 : 0] B
			.C(layer_2_3[0]),      // input [15 : 0] C
			.P(layer_1_3_4)      // output [16 : 0] P
		);
    endgenerate
    
	integer k; 
	always@(posedge clk) begin   
		if( resetn == 1'b0 ) begin    
			
    	end
		else begin
			layer_1_3[0] <= din_array[(KERNEL_SIZE/2)*KERNEL_SIZE+KERNEL_SIZE/2];
			for(k = 1; k < 8; k = k + 1) begin
				layer_1_3[k] <= layer_1_3[k-1];
			end
			
			for(k = 1; k < layer_1_size; k = k + 1) begin
				layer_3_4[k*3] <= {layer_2_3[k][15], layer_2_3[k]};
			end
			
			for(k = 1; k < layer_1_size; k = k + 1) begin
				layer_3_4[k*3+1] <= layer_3_4[k*3];
				layer_3_4[k*3+2] <= layer_3_4[k*3+1];
			end
		end
	end
	
	
	// adder tree
	parameter adder_tree_data_size = (2**adder_tree_layer);	
	reg [31:0] adder_tree_data [adder_tree_data_size-1:0];	// array tree structure
	reg  [31:0] layer_end;		
	assign dout = layer_end;
	assign dout_valid = layer_valid[latency-1]; 
    
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
			//layer 4
			adder_tree_data[adder_tree_data_size/2] <= {{15{layer_1_3_4[16]}}, layer_1_3_4};
			for(k = 1; k < layer_1_size; k = k + 1) begin
				adder_tree_data[adder_tree_data_size/2+k] <= {{15{layer_3_4[k*3+2][16]}}, layer_3_4[k*3+2]};
			end			
			
			
			//layer 5 ~ ...
			for(k = 1; k < adder_tree_data_size/2; k = k + 1) begin
				adder_tree_data[k] <= adder_tree_data[k*2]+adder_tree_data[k*2+1];
			end
	   	    layer_end <= adder_tree_data[1];
			
			layer_valid <= {layer_valid, din_valid};
        end
    end	
	
endmodule
