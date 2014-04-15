`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/03 15:32:05
// Design Name: 
// Module Name: filter_window
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


module filter_window
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
	input din_valid,
	input en,
	output [(KERNEL_SIZE+M_BYTES_IN-1)*KERNEL_SIZE*8-1:0] dout,
	output reg dout_valid
);
			
	//parameter EXTEND_NUM = KERNEL_SIZE/2 >= M_BYTES_IN ? ((KERNEL_SIZE/2)%M_BYTES_IN == 0 ? 0 :M_BYTES_IN - ((KERNEL_SIZE/2)%M_BYTES_IN) ) 
	//													: (M_BYTES_IN%(KERNEL_SIZE/2)) == 0 ? 0 : M_BYTES_IN - (M_BYTES_IN%(KERNEL_SIZE/2)));	
	parameter EXTEND_NUM = M_BYTES_IN - ((KERNEL_SIZE + M_BYTES_IN - 1) - KERNEL_SIZE/2) % M_BYTES_IN == 0 ? 0 : M_BYTES_IN - ((KERNEL_SIZE + M_BYTES_IN - 1) - KERNEL_SIZE/2) % M_BYTES_IN;
	parameter WINDOW_FIFO_WIDTH = KERNEL_SIZE+(M_BYTES_IN-1)+EXTEND_NUM;	
	parameter WINDOW_FIFO_OUT_WIDTH = KERNEL_SIZE+(M_BYTES_IN-1);
	
	integer ii;
	integer ij;
	genvar gi;
	genvar gj;
	genvar gk;		
	

	reg [KERNEL_SIZE/2-1:0] window_fifo_valid_buf;	
	reg [WINDOW_FIFO_WIDTH-1:0] window_fifo_valid;	
	always@(posedge clk) begin
	
		if(resetn == 1'b0) begin
		
			window_fifo_valid_buf <= 0;			
		end
		else begin
		
			if(en == 1'b1) begin						
				
				for(ij = 0; ij < M_BYTES_IN-EXTEND_NUM; ij = ij + 1) begin
				
					window_fifo_valid_buf[KERNEL_SIZE/2-1-ij] <= din_valid;
				end
				
				for(ij = 0; ij < EXTEND_NUM && ij <= ((WINDOW_FIFO_WIDTH-M_BYTES_IN)-(M_BYTES_IN-1+KERNEL_SIZE/2+1)); ij = ij + 1) begin
				
					window_fifo_valid_buf[(WINDOW_FIFO_WIDTH-1-M_BYTES_IN)-(M_BYTES_IN-1+KERNEL_SIZE/2+1)-ij] <= window_fifo_valid[WINDOW_FIFO_WIDTH-1-ij];
				end
				
				for(ij = 0; ij < KERNEL_SIZE/2-M_BYTES_IN; ij = ij + 1) begin
				
					window_fifo_valid_buf[ij] <= window_fifo_valid_buf[ij+M_BYTES_IN];					
				end		
			end
		end
	end
	
	
	reg [(MAX_IMAGE_SIZE+1)-1:0] counter_col;	
	
	always@(posedge clk) begin
	
		if(resetn == 1'b0) begin
		
			counter_col <= 0;			
		end
		else begin
		
			if(en == 1'b1) begin						
				
				if(M_BYTES_IN >= KERNEL_SIZE/2) begin
				
					if(din_valid == 1'b1) begin
					
						if(counter_col == d_cols) begin
						
							counter_col <= M_BYTES_IN;
						end
						else begin
						
							counter_col <= counter_col + M_BYTES_IN;
						end						
					end									
				end
				else begin
				
					if(window_fifo_valid_buf[M_BYTES_IN] == 1'b1) begin
					
						if(counter_col == d_cols) begin
						
							counter_col <= M_BYTES_IN;
						end
						else begin
						
							counter_col <= counter_col + M_BYTES_IN;
						end
					end					
				end
			end
		end
	end
	
	reg  dout_valid_buf;
	always@(posedge clk) begin
	
		if(resetn == 1'b0) begin		
			
			dout_valid <= 1'b0;
			dout_valid_buf <= 1'b0;
		end
		else begin
		
			if(en == 1'b1) begin				
			
				dout_valid_buf <= din_valid;
				
				if(M_BYTES_IN >= KERNEL_SIZE/2) begin			
										
					dout_valid <= dout_valid_buf;	
				end
				else begin		
					
					dout_valid <= window_fifo_valid_buf[0];
				end
			end
			else begin
			
				dout_valid <= 1'b0;
			end
		end
	end
	
	wire signed [(MAX_IMAGE_SIZE+1)-1:0] right_mirror_condition = KERNEL_SIZE/2 > M_BYTES_IN ? d_cols - ((KERNEL_SIZE/2)/M_BYTES_IN)*M_BYTES_IN : d_cols - 1 + 1;		
	
	generate 
		
		for(gi = 0; gi < KERNEL_SIZE; gi = gi + 1) 
		begin: Col_mirror
		
			filter_window_col_mirror #(.KERNEL_SIZE(KERNEL_SIZE), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE), .M_BYTES_IN(M_BYTES_IN))
			filter_window_col_mirro_uut
			(
				.clk(clk),
				.resetn(resetn),
				.d_cols(d_cols),				
				.counter_col(counter_col),
				.right_mirror_condition(right_mirror_condition),
				.din(din[gi*M_BYTES_IN*8 +: M_BYTES_IN*8]),				
				.en(en),
				.dout(dout[gi*WINDOW_FIFO_OUT_WIDTH*8 +: WINDOW_FIFO_OUT_WIDTH*8] )			 
			);
		
		end
	
	endgenerate
	
	
	
endmodule
