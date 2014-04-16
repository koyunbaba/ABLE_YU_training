`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/15 10:45:31
// Design Name: 
// Module Name: window_col_mirror
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


module filter_window_col_mirror
#(
	parameter KERNEL_SIZE = 3,
	parameter MAX_IMAGE_SIZE = 10, //bit
	parameter M_BYTES_IN = 1
)
(
	input clk,
	input resetn,
	input [MAX_IMAGE_SIZE-1:0] d_cols,    
	input [MAX_IMAGE_SIZE+1-1:0] counter_col,   
	input signed [(MAX_IMAGE_SIZE+1)-1:0] right_mirror_condition,
	input [M_BYTES_IN*8-1:0] din,	
	input en,
	output [(KERNEL_SIZE+M_BYTES_IN-1)*8-1:0] dout
);

	//parameter EXTEND_NUM = KERNEL_SIZE/2 > M_BYTES_IN ? (KERNEL_SIZE/2)%M_BYTES_IN : M_BYTES_IN - KERNEL_SIZE/2;	
	//parameter EXTEND_NUM = KERNEL_SIZE/2 >= M_BYTES_IN ? ((KERNEL_SIZE/2)%M_BYTES_IN == 0 ? 0 :M_BYTES_IN - ((KERNEL_SIZE/2)%M_BYTES_IN) ) 
	//													: (M_BYTES_IN%(KERNEL_SIZE/2)) == 0 ? 0 : M_BYTES_IN - (M_BYTES_IN%(KERNEL_SIZE/2));	
	parameter EXTEND_NUM = M_BYTES_IN - ((KERNEL_SIZE + M_BYTES_IN - 1) - KERNEL_SIZE/2) % M_BYTES_IN == 0 ? 0 : M_BYTES_IN - ((KERNEL_SIZE + M_BYTES_IN - 1) - KERNEL_SIZE/2) % M_BYTES_IN;
	parameter WINDOW_FIFO_WIDTH = KERNEL_SIZE+(M_BYTES_IN-1)+EXTEND_NUM;
	parameter WINDOW_FIFO_OUT_WIDTH = KERNEL_SIZE+(M_BYTES_IN-1);

	reg [8-1:0] window_fifo_buf [KERNEL_SIZE/2-1:0];
	reg [8-1:0] window_fifo [WINDOW_FIFO_WIDTH-1:0];		
	wire [8-1:0] din_array [M_BYTES_IN-1:0];
	
	genvar gi;
	 
	generate
	
		for(gi = 0; gi < WINDOW_FIFO_OUT_WIDTH; gi = gi + 1) begin			
		
			assign dout[gi*8 +: 8] = window_fifo[gi][0+:8];			
		end		
		
		for(gi = 0; gi < M_BYTES_IN; gi = gi + 1) begin						
		
			assign din_array[gi] = din[gi*8 +: 8];			
		end		
	endgenerate
	
	integer ii;
	integer ij;
	
	always@(posedge clk) begin
	
		if(resetn == 1'b0) begin
		
			for(ii = 0; ii < WINDOW_FIFO_WIDTH; ii = ii + 1) begin		
			
				window_fifo[ii] <= 0;					
			end			
			
			for(ii = 0; ii < KERNEL_SIZE/2; ii = ii + 1) begin	
			
				window_fifo_buf[ii] <= 0;
			end							
		end
		else begin
		
			if(en == 1'b1) begin		
				
				//window_fifo_buf
				for(ij = 0; ij < M_BYTES_IN-EXTEND_NUM; ij = ij + 1) begin
				
					window_fifo_buf[KERNEL_SIZE/2-1-ij] <= din_array[M_BYTES_IN-1-ij-EXTEND_NUM];
				end
				
				for(ij = 0; ij < EXTEND_NUM && ij <= ((WINDOW_FIFO_WIDTH-M_BYTES_IN)-(M_BYTES_IN-1+KERNEL_SIZE/2+1)); ij = ij + 1) begin
				
					window_fifo_buf[(WINDOW_FIFO_WIDTH-1-M_BYTES_IN)-(M_BYTES_IN-1+KERNEL_SIZE/2+1)-ij] <= window_fifo[WINDOW_FIFO_WIDTH-1-ij];
				end
				
				for(ij = 0; ij < KERNEL_SIZE/2-M_BYTES_IN; ij = ij + 1) begin
				
					window_fifo_buf[ij] <= window_fifo_buf[ij+M_BYTES_IN];					
				end						
				
				//left mirror
				if(counter_col == M_BYTES_IN) begin
				
					//back
					for(ij = 0; ij < M_BYTES_IN; ij = ij + 1) begin
					
						window_fifo[WINDOW_FIFO_WIDTH - M_BYTES_IN + ij] <= din_array[ij];
					end
					
					//front mirror
					if(EXTEND_NUM == 0) begin
					
						window_fifo[0] <= din_array[0];
					end
					else begin
					
						window_fifo[0] <= window_fifo[WINDOW_FIFO_WIDTH-EXTEND_NUM];
					end
					
					//buf pipeline and buf mirror
					for(ij = 0; ij < KERNEL_SIZE/2; ij = ij + 1) begin
					
						window_fifo[1 + KERNEL_SIZE/2-1 + ij ] <= window_fifo_buf[ij];
					end
					
					for(ij = 1; ij < KERNEL_SIZE/2; ij = ij + 1) begin
					
						window_fifo[1 + KERNEL_SIZE/2-1 - ij] <= window_fifo_buf[ij];
					end
					
					//residual remained
					for(ij = KERNEL_SIZE - 1; ij < WINDOW_FIFO_WIDTH-M_BYTES_IN; ij = ij + 1) begin
					
						window_fifo[ij] <= window_fifo[ij+M_BYTES_IN];
					end

				end
				// right mirror
				else if(counter_col >= right_mirror_condition) begin
				
					//back extend remained
					for(ij = 0; ij < EXTEND_NUM; ij = ij + 1) begin       
					
						window_fifo[WINDOW_FIFO_WIDTH-1-ij] <= din_array[M_BYTES_IN-1-ij];
					end						
					
					//back mirror
					for(ij = EXTEND_NUM; ij < EXTEND_NUM + KERNEL_SIZE/2; ij = ij + 1) begin            
						
						if( ij <= M_BYTES_IN + counter_col - right_mirror_condition ) begin
							window_fifo[WINDOW_FIFO_WIDTH-1-ij] <= window_fifo[WINDOW_FIFO_WIDTH - M_BYTES_IN - 1 + ij - ((counter_col - right_mirror_condition)*2 )];
															//(WINDOW_FIFO_WIDTH-1-(counter_col - right_mirror_condition)) - [ (WINDOW_FIFO_WIDTH-1-ij) - (WINDOW_FIFO_WIDTH-1-M_BYTES_IN-(counter_col - right_mirror_condition))] 							
						end
						else begin
							window_fifo[WINDOW_FIFO_WIDTH-1-ij] <= window_fifo[WINDOW_FIFO_WIDTH-1-ij+M_BYTES_IN];
						end
					end
					
					//front remain
					for(ij = 0; ij < WINDOW_FIFO_WIDTH-EXTEND_NUM-KERNEL_SIZE/2; ij = ij + 1) begin 
					
						window_fifo[ij] <= window_fifo[ij+M_BYTES_IN];
					end	
					
				end
				
				else begin
					
					for(ij = 0; ij < M_BYTES_IN; ij = ij + 1)  begin
					
						window_fifo[WINDOW_FIFO_WIDTH-1 - ij] <= din_array[M_BYTES_IN-1-ij];
					end
					
					for(ij = 0; ij < WINDOW_FIFO_WIDTH - M_BYTES_IN; ij = ij + 1) begin
					
						window_fifo[ij] <= window_fifo[ij+M_BYTES_IN];
					end									
				end						
			end
		end		
	end
	
	
	
endmodule
