`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/19 14:00:00
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
	parameter KERNEL_WIDTH = 7;
	parameter KERNEL_HEIGHT = 5;
	//-------------------------------------------------------
`define PISOs

	parameter DATA_IN_SIZE = KERNEL_WIDTH*KERNEL_HEIGHT*8;
	parameter KERNEL_DATA_SIZE = KERNEL_WIDTH*KERNEL_HEIGHT*6;
    reg		clk;	
    reg		resetn;
    wire	[DATA_IN_SIZE-1:0]	din;		
	reg signed	[KERNEL_DATA_SIZE-1:0] 	kernel;	
    reg		din_valid;
    wire signed	[31:0]	dout;				
    wire	dout_valid;

`ifdef PISO	 
	reg [7:0] din_piso [KERNEL_WIDTH*KERNEL_HEIGHT-1+1:0];
	reg [6:0] kernel_piso [KERNEL_WIDTH*KERNEL_HEIGHT-1+1:0];
	reg [KERNEL_WIDTH*KERNEL_HEIGHT-1+1:0] piso_valid;
	wire [7:0] din_piso_result;
	wire [7:0] kernel_piso_result;
	wire piso_valid_result;
`endif	
	
	
`ifdef PISO	
	filter_wrapper #(.KERNEL_WIDTH(KERNEL_WIDTH), .KERNEL_HEIGHT(KERNEL_HEIGHT))	filter_wrapper_uut
	(
		.clk(clk),
		.resetn(resetn),
		.din(din_piso_result),		
		.kernel(kernel_piso_result),		
		.din_valid(piso_valid_result),
		.dout(dout),				
		.dout_valid(dout_valid)
    );
`else
	filter #(.KERNEL_WIDTH(KERNEL_WIDTH), .KERNEL_HEIGHT(KERNEL_HEIGHT)) filter_uut 
	(
        .clk(clk),
        .resetn(resetn),
        .din(din), //[71:0], 9 * 8, 0~255
        .kernel(kernel), //[53:0], 9 * 6, -32~31			
        .din_valid(din_valid),
        .dout(dout), //[15:0], signed 16bit
        .dout_valid(dout_valid)		
    );
`endif	
	
	
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
`ifdef PISO			
		piso_valid = 0;
`endif		
		kernel = {5{6'd1, -6'd16, 6'd1, 6'd31, -6'd1, 6'd16, -6'd1}};
				  
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
		for(i = 0; i < KERNEL_WIDTH*KERNEL_HEIGHT; i = i + 1) begin
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
`ifdef PISO
            else if( |piso_valid == 0) begin            
`else
			else begin
`endif			
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
`ifdef PISO		
			if(|piso_valid == 1'b0) begin
`endif			
				if(counter1 < counter2) begin				
					din_valid <= 1'b1;					
					long_adder <= long_adder + {5{56'h01_02_03_04_05_06_07}};					
				end
				else begin                                					
					din_valid <= 1'b0;
				end
`ifdef PISO				
			end
			else begin
				din_valid <= 1'b0;
			end
`endif						
        end        
    end
	
`ifdef PISO	
	// test data parallel in serial out
	assign din_piso_result = din_piso[KERNEL_WIDTH*KERNEL_HEIGHT];
	assign kernel_piso_result = kernel_piso[KERNEL_WIDTH*KERNEL_HEIGHT];
	assign piso_valid_result = piso_valid[KERNEL_WIDTH*KERNEL_HEIGHT];
	always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
			piso_valid <= 0;
			for(i = 0; i < KERNEL_WIDTH*KERNEL_HEIGHT+1; i = i + 1) begin
				din_piso[i] <= 0;
				kernel_piso[i] <= 0;
			end			
        end
        else begin
        
            if(din_valid == 1'b1) begin //initial the parallel in values		
				for(i = 0; i < KERNEL_HEIGHT; i = i + 1) begin
					for(j = 0; j < KERNEL_WIDTH; j = j + 1) begin
						din_piso[i*KERNEL_WIDTH+j] <= din[(i*KERNEL_WIDTH+j)*8 +: 8];
						kernel_piso[i*KERNEL_WIDTH+j] <= kernel[(i*KERNEL_WIDTH+j)*6 +: 6];
						piso_valid[i*KERNEL_WIDTH+j] <= 1'b1;
					end
				end		
				din_valid <= 1'b0;
            end
            else begin
				if( (|piso_valid) == 1'b1) begin // serial out	until piso_valid is 0				
					piso_valid <= {piso_valid, 1'b0};
					for(i = 1; i < KERNEL_WIDTH*KERNEL_HEIGHT+1; i = i + 1) begin
						din_piso[i] <= din_piso[i-1];
						kernel_piso[i] <= kernel_piso[i-1];						
					end
				end
                
            end
        end        
    end
`endif    
    
endmodule
