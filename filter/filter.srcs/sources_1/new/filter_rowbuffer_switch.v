`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/09 16:45:56
// Design Name: 
// Module Name: filter_rowbuffer_switch
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

module filter_rowbuffer_switch
#(
	parameter KERNEL_SIZE = 3,
	parameter MAX_IMAGE_SIZE = 10, //bit
	parameter M_BYTES_IN = 1
)
(
	input clk,
	input resetn,
	input   [MAX_IMAGE_SIZE-1:0] d_cols,
    input   [MAX_IMAGE_SIZE-1:0] d_rows,		
	input 	[M_BYTES_IN*KERNEL_SIZE*8-1:0] din,
	input 	din_valid,
	input 	en,
	output  [M_BYTES_IN*KERNEL_SIZE*8-1:0] dout,
	output  reg dout_valid
);	
		
	wire [M_BYTES_IN*8-1:0] din_array [KERNEL_SIZE-1:0];	
	reg [M_BYTES_IN*8-1:0] dout_array [KERNEL_SIZE-1:0];	
	
	genvar gi;
	genvar gj;
	generate
	
		for(gi = 0; gi < KERNEL_SIZE; gi = gi + 1) begin
		
			assign din_array[gi] = din[gi*M_BYTES_IN*8 +: M_BYTES_IN*8];			
			assign dout[gi*M_BYTES_IN*8 +: M_BYTES_IN*8] = dout_array[gi];
		end
		
	endgenerate
	
	reg [(MAX_IMAGE_SIZE+1)-1:0] counter_col;
	reg [(MAX_IMAGE_SIZE+1)-1:0] counter_row;
	
	always@(posedge clk)  begin
		if(resetn == 1'b0) begin
		
			counter_col <= 0;
			counter_row <= 0;		
		end
		else begin
		
			if(en == 1'b1) begin
			
				if(din_valid == 1'b1) begin
				
					if(counter_col ==  d_cols - M_BYTES_IN) begin
					
						counter_col <= 0;
						if(counter_row == d_rows - 1) begin		
						
							counter_row <= 0;
						end
						else begin		
						
							counter_row <= counter_row + 1;
						end
					end
					else begin
					
						counter_col <= counter_col + M_BYTES_IN;
					end
				end
			end
		end		
	end
	
	
	integer ii;
	integer ij;
	always@(posedge clk) begin
		if(resetn == 1'b0) begin	
			
			for(ii = 0; ii < KERNEL_SIZE; ii = ii + 1) begin
				
				dout_array[ii] <= 0;				
			end			
			dout_valid <= 1'b0;
		end
		else begin
		
			dout_valid <= din_valid;
			
			if(en == 1'b1) begin
						
				// up mirror
				for(ii = 0; ii < KERNEL_SIZE/2; ii = ii + 1) begin
				
					if(counter_row + ii < KERNEL_SIZE/2) begin		
						
						dout_array[ii] <= 0;//din_array[ KERNEL_SIZE - 1 - ii - (counter_row*2)];
							// ii <=   (KERNEL_SIZE/2 - row) + [ (KERNEL_SIZE/2 - row) - ii ];
					end					
					else begin
					
						dout_array[ii] <= din_array[ii];
					end
				end
				
				dout_array[KERNEL_SIZE/2] <= din_array[KERNEL_SIZE/2];
				
				
				// down mirror
				for(ii = KERNEL_SIZE/2+1; ii < KERNEL_SIZE; ii = ii + 1) begin
				
					if(counter_row + (ii-KERNEL_SIZE/2) >= d_rows ) begin
					
						dout_array[ii] <= 0;//din_array[((KERNEL_SIZE-2-(counter_row + KERNEL_SIZE/2 - d_rows))*2 ) - ii];
							//  ii <=   ( KERNEL_SIZE - 2 - ( counter_row + KERNEL_SIZE/2 - d_rows)) - [ ii - ( KERNEL_SIZE - 2 - ( counter_row + KERNEL_SIZE/2 - d_rows))  ] 						
					end
					else begin
						
						dout_array[ii] <= din_array[ii];						
					end
				end
			end			
		end			
	end
    
endmodule
