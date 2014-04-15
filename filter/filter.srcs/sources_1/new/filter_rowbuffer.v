`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/28 09:29:04
// Design Name: 
// Module Name: rowbuffer
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


module filter_rowbuffer
#(
	parameter KERNEL_SIZE = 3,
	parameter MAX_IMAGE_SIZE = 10,// bit
	parameter M_BYTES_IN = 1
)
(
	input clk,
	input resetn,
	input [MAX_IMAGE_SIZE-1:0] d_cols,
	input [MAX_IMAGE_SIZE-1:0] d_rows,
	input [M_BYTES_IN*8-1:0] din,
	input din_valid,
	input en,
	output [KERNEL_SIZE*M_BYTES_IN*8-1:0] dout,
	output dout_valid
);	
	
	parameter ROWBUFFER_COUNT = KERNEL_SIZE - 1;
	parameter M_BYTES_IN_BIT = $clog2(M_BYTES_IN);
	wire [M_BYTES_IN*9-1:0] bram_out [ROWBUFFER_COUNT-1:0];			
	reg  [M_BYTES_IN*9-1:0] sfifo_in [ROWBUFFER_COUNT-1:0];			
					
	reg [(MAX_IMAGE_SIZE-M_BYTES_IN_BIT-1):0] address;
	
	wire [M_BYTES_IN*8+1-1:0] rowbuffer_fifo_out [KERNEL_SIZE-1:0];	
			
	assign rowbuffer_fifo_out[0] = sfifo_in[0];
	
	genvar gi;
	genvar gj;
	
	generate 					
	
		bram_single_macro_d1024 #(.DATA_WIDTH(M_BYTES_IN*8+1), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE)) rowbuffer_end (
			.clka(clk),    
			.rsta(!resetn),   
			.ena(en),    
			.wea({(M_BYTES_IN){en}}),     
			.addra(address),  
			.dina({din_valid, din}),    
			.douta(bram_out[ROWBUFFER_COUNT-1]) 
		);
		
		simple_fifo #(.LATENCY(ROWBUFFER_COUNT-1), .SIZE(M_BYTES_IN*8+1)) outputfifo_uut (
			.clk(clk),
			.resetn(resetn),
			.din(sfifo_in[ROWBUFFER_COUNT-1]),
			.en(en),
			.dout(rowbuffer_fifo_out[ROWBUFFER_COUNT-1])
		);
		
		bram_single_macro_d1024 #(.DATA_WIDTH(M_BYTES_IN*8+1), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE)) rowbuffer_begin (
				.clka(clk),    
				.rsta(!resetn),   
				.ena(en),    
				.wea({(M_BYTES_IN){en}}),     
				.addra(address),  
				.dina(bram_out[1]), 
				.douta(bram_out[0]) 
			);
		
		for(gi = 1; gi < ROWBUFFER_COUNT-1; gi = gi + 1) 
		begin: r_b
		
			bram_single_macro_d1024 #(.DATA_WIDTH(M_BYTES_IN*8+1), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE)) rowbuffer (
				.clka(clk),    
				.rsta(!resetn),    
				.ena(en),     
				.wea({(M_BYTES_IN){en}}),     
				.addra(address),  
				.dina(bram_out[gi+1]),   
				.douta(bram_out[gi])  
			);
			simple_fifo #(.LATENCY(gi), .SIZE(M_BYTES_IN*8+1)) outputfifo_uut (
				.clk(clk),
				.resetn(resetn),
				.din(sfifo_in[gi]),
				.en(en),
				.dout(rowbuffer_fifo_out[gi])
			);		
		end
		
		simple_fifo #(.LATENCY(ROWBUFFER_COUNT+1), .SIZE(M_BYTES_IN*8+1)) outputfifo_din_uut (
			.clk(clk),
			.resetn(resetn),
			.din({din_valid, din}),
			.en(en),
			.dout(rowbuffer_fifo_out[KERNEL_SIZE-1])
		);
		
		assign dout_valid = rowbuffer_fifo_out[KERNEL_SIZE/2][M_BYTES_IN*8];
		for(gi = 0; gi < KERNEL_SIZE; gi = gi + 1) begin		
			
			assign dout[gi*M_BYTES_IN*8 +: M_BYTES_IN*8] = rowbuffer_fifo_out[gi][0 +: M_BYTES_IN*8];			
		end						
		
	endgenerate
	
	integer ii;
	integer ij;

	always@(posedge clk) begin
		if(resetn == 1'b0) begin
		
			for(ii = 0;  ii < ROWBUFFER_COUNT; ii = ii + 1) begin
			
				sfifo_in[ii] <= 0;
			end		
		end
		else begin
			if(en == 1'b1) begin
				for(ii = 0; ii < ROWBUFFER_COUNT; ii = ii + 1) begin
				
					sfifo_in[ii] <= bram_out[ii];					
				end
			end		
		end
	end			

	always@(posedge clk) begin	
		if(resetn == 1'b0) begin 		
		
			address <= 0;
		end
		else begin						
			if(en == 1'b1) begin
			
				if(address + 1 < d_cols[MAX_IMAGE_SIZE-1:M_BYTES_IN_BIT]) begin
				
					address <= address + 1;
				end
				else begin
				
					address <= 0;
				end			
			end
		end
	
	end
	
endmodule


