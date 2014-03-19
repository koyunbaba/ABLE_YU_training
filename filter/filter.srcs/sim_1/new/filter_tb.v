`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/17 18:09:18
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
	parameter KERNEL_SIZE = 5;
	//-------------------------------------------------------
	parameter DATA_IN_SIZE = KERNEL_SIZE*KERNEL_SIZE*8;
	parameter KERNEL_DATA_SIZE = KERNEL_SIZE*KERNEL_SIZE*6;
    reg		clk;	
    reg		resetn;
    wire	[DATA_IN_SIZE-1:0]	din;		
	reg signed	[KERNEL_DATA_SIZE-1:0] 	kernel;	
    reg		din_valid;
    wire signed	[31:0]	dout;				
    wire	dout_valid;
	
	reg [7:0] din_piso [KERNEL_SIZE*KERNEL_SIZE-1+1:0];
	reg [6:0] kernel_piso [KERNEL_SIZE*KERNEL_SIZE-1+1:0];
	reg [KERNEL_SIZE*KERNEL_SIZE-1+1:0] piso_valid;
	wire [7:0] din_piso_result;
	wire [7:0] kernel_piso_result;
	wire piso_valid_result;
	
	filter_wrapper #(.KERNEL_SIZE(KERNEL_SIZE))	filter_wrapper_uut
	(
		.clk(clk),
		.resetn(resetn),
		.din(din_piso_result),		
		.kernel(kernel_piso_result),		
		.din_valid(piso_valid_result),
		.dout(dout),				
		.dout_valid(dout_valid)
    );
	
	
	
    reg [7:0] counter1;
    reg [7:0] counter2;
    
    reg [31:0] fifo[0:1023];
    reg [9:0]  rd_ptr;
    reg [9:0]  wr_ptr;
    
    wire signed [31:0] ans;
    reg [31:0] temp;    
    reg [DATA_IN_SIZE-1 : 0] long_adder;
    
    parameter clk_period = 10;
    initial clk = 1'b0;
	
    always #(clk_period/2) clk = ~clk;

	
    initial begin
        
        resetn = 1'b0;
		piso_valid = 0;
		kernel = {5{-6'd31, -6'd31, -6'd19, -6'd31,  -6'd31}};
				  
        #100
        
        resetn = 1'b1;
    end
    
    integer i;
    integer j;
    assign ans = fifo[rd_ptr];
    
    assign din = long_adder[0 +: DATA_IN_SIZE];

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
                
            if( din_valid == 1'b1 ) begin
            
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
    
    // counter for din_valid switching
    always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
        
            counter1 <= 0;
            counter2 <= 0;
        end
        else begin
                                
            if(counter1 == counter2) begin
            
                counter1 <= 0;
                counter2 <= counter2 + 1;
            end
            else if( |piso_valid == 0) begin            
			
                counter1 <= counter1 + 1;
            end
        end
    end
    
    // test data generate
    // 
    // test all combination of din (100% coverage)
    //
    // FIXME: very long simulation time and cause memory fill up... 
    //
    // TODO: generate more effective data set
    //
    always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
        
            din_valid <= 1'b0;
            
            long_adder <= 0;
        end
        else begin
			if(|piso_valid == 1'b0) begin
			
				if(counter1 < counter2) begin				
					din_valid <= 1'b1;					
					long_adder <= long_adder + {5{40'h05_04_03_02_01}};					
				end
				else begin                                					
					din_valid <= 1'b0;
				end
			end
			else begin
				din_valid <= 1'b0;
			end
        end        
    end
	
	// test data parallel in serial out
	assign din_piso_result = din_piso[KERNEL_SIZE*KERNEL_SIZE];
	assign kernel_piso_result = kernel_piso[KERNEL_SIZE*KERNEL_SIZE];
	assign piso_valid_result = piso_valid[KERNEL_SIZE*KERNEL_SIZE];
	always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
			piso_valid <= 0;
			for(i = 0; i < KERNEL_SIZE+1; i = i + 1) begin
				din_piso[i] <= 0;
				kernel_piso[i] <= 0;
			end			
        end
        else begin
        
            if(din_valid == 1'b1) begin //initial the parallel in values		
				for(i = 0; i < KERNEL_SIZE; i = i + 1) begin
					for(j = 0; j < KERNEL_SIZE; j = j + 1) begin
						din_piso[i*KERNEL_SIZE+j] <= din[(i*KERNEL_SIZE+j)*8 +: 8];
						kernel_piso[i*KERNEL_SIZE+j] <= kernel[(i*KERNEL_SIZE+j)*6 +: 6];
						piso_valid[i*KERNEL_SIZE+j] <= 1'b1;
					end
				end		
				din_valid <= 1'b0;
            end
            else begin
				if( (|piso_valid) == 1'b1) begin // serial out	until piso_valid is 0				
					piso_valid <= {piso_valid, 1'b0};
					for(i = 1; i < KERNEL_SIZE*KERNEL_SIZE+1; i = i + 1) begin
						din_piso[i] <= din_piso[i-1];
						kernel_piso[i] <= kernel_piso[i-1];						
					end
				end
                
            end
        end        
    end

    /*always@(posedge clk) begin
    
        if( din[71-:8]  == 8'hFF  &&
            wr_ptr == rd_ptr &&
            dout_valid == 1'b1  ) begin
			$display("Complete @ %t", $time);
            $stop;
        end
    end*/
    
endmodule
