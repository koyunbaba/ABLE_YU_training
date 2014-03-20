`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/19 16:06:09
// Design Name: 
// Module Name: filter_tb
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

module filter_tb;
	parameter KERNEL_SIZE = 3;	
	parameter DATA_NUM = 20;
	//-------------------------------------------------------
	parameter DATA_IN_SIZE = KERNEL_SIZE*KERNEL_SIZE*8;
	parameter KERNEL_DATA_SIZE = KERNEL_SIZE*KERNEL_SIZE*6;
	parameter DATA_INPUT_SIZE = KERNEL_SIZE*(DATA_NUM+2)*8;
    reg		clk;	
    reg		resetn;
	reg		row_neg;
	reg		col_neg;
    reg	[DATA_IN_SIZE-1:0]	din;		
	reg signed	[KERNEL_DATA_SIZE-1:0] 	kernel;	    
    wire signed	[31:0]	dout;				
    wire	dout_valid;

	reg		din_valid;
	reg [8*KERNEL_SIZE-1:0] din_piso_result;
	
	reg update_kernel;
	wire [5:0] kernel_piso_result;		
	wire kernel_piso_valid_result;

	filter_wrapper #(.KERNEL_SIZE(KERNEL_SIZE))	filter_wrapper_uut
	(
		.clk(clk),
		.resetn(resetn),
		.col_neg(col_neg),
		.row_neg(row_neg),
		.din(din_piso_result),		
		.kernel(kernel_piso_result),	
		.kernel_valid(kernel_piso_valid_result),	
		.din_valid(din_valid),
		.dout(dout),				
		.dout_valid(dout_valid)
    );
	
	reg data_tranmit_en;
    reg [7:0] counter1;
    reg [7:0] counter2;
	reg [7:0] counter3;
    
    reg [31:0] fifo[0:1023];
    reg [9:0]  rd_ptr;
    reg [9:0]  wr_ptr;
    
    wire signed [31:0] ans;
    reg [31:0] temp;    
    reg [DATA_INPUT_SIZE-1 : 0] long_adder;
    
    parameter clk_period = 10;
    initial clk = 1'b0;
	
    always #(clk_period/2) clk = ~clk;

	
    initial begin
        
        resetn = 1'b0;
		update_kernel = 1'b0;
		row_neg = 1'b0;
		col_neg = 1'b0;	
		din_valid = 1'b0;		
		data_tranmit_en = 1'b0;
		kernel = {3{-6'd1, 6'd2, -6'd1}}; 
				  
        #100        
        resetn = 1'b1;
		#(clk_period)
		update_kernel <= 1'b1;
		#(clk_period)
		update_kernel <= 1'b0;
		#(clk_period*KERNEL_SIZE*KERNEL_SIZE)
		#(clk_period/2)
		data_tranmit_en <= 1'b1;
    end
    
    integer i;
    integer j;
    assign ans = fifo[rd_ptr];
	reg ans_valid;
    
    //assign din = long_adder[0 +: DATA_IN_SIZE];

	reg [31:0] sum;
	reg [14:0] sum_temp;
	
    always@(*) begin
        
        // golden answer preparing
		sum = 0;		
		for(i = 0; i < KERNEL_SIZE*KERNEL_SIZE; i = i + 1) begin
			sum_temp = { 7'b0, {din[i*8 +: 8]} } * { {9{kernel[i*6+5]}}, kernel[i*6+:6]}; // signed mul  din * kernel
			sum = sum + {{17{sum_temp[14]}}, sum_temp};			
		end				
		temp = sum;
    end
    
    // answer fifo
    always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
        
            // fifo clean and pointer reset
            wr_ptr <= 0;
            rd_ptr <= 0;            
            for(i = 0; i < 1024; i = i + 1) begin                
                fifo[i] <= 0;                
            end
        end
        else begin
                
            if( ans_valid == 1'b1 ) begin
            
                // answer push-in
                fifo[wr_ptr] <= temp;
                wr_ptr       <= wr_ptr + 1;
            end
            
            if( dout_valid == 1'b1 ) begin
            
                // answer pop-out
                rd_ptr <= rd_ptr + 1;
            end
        end
    end
    
    // wrong answer detect and alarm
    always@(posedge clk) begin
    
        if( dout_valid == 1'b1 &&
            dout       != ans     ) begin
        
            $display("fail %d, correct %d, @  %t", dout, ans, $time);
        end
    end
    
    // counter1 for data transmition		
    always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
			din_valid <= 1'b0;
			ans_valid <= 1'b0;
            counter1 <= 0;           
			din_piso_result <= 0;
			long_adder <= 0;
			//  	1	2 	3
			// [	4	5 	6    
			//  	7	8 	9
			//  	10	11 	12
			
        end
        else begin            
			if(data_tranmit_en == 1'b1) begin				
				if(counter1 > DATA_NUM+1) begin
					data_tranmit_en <= 1'b0;
					counter1 <= 0;
					din_valid <= 1'b0;
					ans_valid <= 1'b0;
				end
				else begin
					din_valid <= 1'b1;
					counter1 <= counter1 + 1;
					din_piso_result <= long_adder[counter1*KERNEL_SIZE*8 +: 8*KERNEL_SIZE];	
					if(counter1 < 2) begin
						din <= long_adder[0 +: DATA_IN_SIZE];
						ans_valid <= 1'b0;
					end
					else begin
						din <= long_adder[(counter1-2)*KERNEL_SIZE*8 +: DATA_IN_SIZE];
						ans_valid <= 1'b1;
					end					
				end
			end       
			else begin
				counter1 <= 0;
				din_valid <= 1'b0;
				ans_valid <= 1'b0;
				din_piso_result <= 0;
			end
        end
    end
	
	// counter2,3 for enable data transmition		
    always@(posedge clk) begin
	
		if(resetn == 1'b0) begin
			counter2 <= 0;
			counter3 <= 10;
		end
		else begin
			if(data_tranmit_en == 1'b0)	 begin
				if(counter2 == counter3) begin
					counter2 <= 0;
					counter3 <= counter3 + 1;
					data_tranmit_en = 1'b1;
					for(i = 0; i < KERNEL_SIZE*(DATA_NUM+2); i = i + 1) begin
						long_adder[i*8 +: 8] <= $random % 256;
					end
				end
				else begin 
					counter2 <= counter2 + 1;
				end
				
				if(counter3 > 30) begin
					counter3 <= 10;
				end			
				
			end
		end
			
	end
	    
	
	// initial kernel matrix	
	reg [5:0] kernel_piso [KERNEL_SIZE*KERNEL_SIZE-1+1:0];	
	reg [KERNEL_SIZE*KERNEL_SIZE-1+1:0] kernel_piso_valid;
	assign kernel_piso_valid_result = kernel_piso_valid[KERNEL_SIZE*KERNEL_SIZE];
	assign kernel_piso_result = kernel_piso[KERNEL_SIZE*KERNEL_SIZE];
	always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
			update_kernel <= 1'b0;
			kernel_piso_valid <= 0;
			for(i = 0; i < KERNEL_SIZE*KERNEL_SIZE+1; i = i + 1) begin				
				kernel_piso[i] <= 0;
			end			
        end
        else begin        
            if(update_kernel == 1'b1) begin //initial the parallel in values		
				for(i = 0; i < KERNEL_SIZE; i = i + 1) begin
					for(j = 0; j < KERNEL_SIZE; j = j + 1) begin						
						kernel_piso[i*KERNEL_SIZE+j] <= kernel[(i*KERNEL_SIZE+j)*6 +: 6];
						kernel_piso_valid[i*KERNEL_SIZE+j] <= 1'b1;
					end
				end		
				update_kernel <= 1'b0;
            end
            else begin
				if( (|kernel_piso_valid) == 1'b1) begin // serial out	until piso_valid is 0				
					kernel_piso_valid <= {kernel_piso_valid, 1'b0};
					for(i = 1; i < KERNEL_SIZE*KERNEL_SIZE+1; i = i + 1) begin						
						kernel_piso[i] <= kernel_piso[i-1];						
					end
				end
                
            end
        end        
    end
	
endmodule
