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

    reg		clk;	
    reg		resetn;
    wire	[71:0]	din;		
	reg signed	[53:0] 	kernel;	
    reg		din_valid;
    wire signed	[15:0]	dout;				
    wire	dout_valid;

    filter filter_uut
	(
        .clk(clk),
        .resetn(resetn),
        .din(din), //[71:0], 9 * 8, 0~255
        .kernel(kernel), //[53:0], 9 * 6, -32~31			
        .din_valid(din_valid),
        .dout(dout), //[15:0], signed 16bit
        .dout_valid(dout_valid)		
    );

    reg [7:0] counter1;
    reg [7:0] counter2;
    
    reg [15:0] fifo[0:1023];
    reg [9:0]  rd_ptr;
    reg [9:0]  wr_ptr;
    
    wire signed [15:0] ans;
    reg [15:0] temp;    
    reg [8*9-1 : 0] long_adder;
    
    parameter clk_period = 10;
    initial clk = 1'b0;
	
    always #(clk_period/2) clk = ~clk;

	
    initial begin
        
        resetn = 1'b0;
        kernel = {-6'd1, 6'd0, 6'd1, 
				  -6'd2, 6'd0, 6'd2, 
				  -6'd1, 6'd0, 6'd1};	
		
        #100
        
        resetn = 1'b1;
    end
    
    integer i;
    
    assign ans = fifo[rd_ptr];
    
    assign din = long_adder[0 +: 72];

	reg [15:0] sum;
	reg [14:0] sum_temp;
	
    always@(*) begin
        
        // golden answer preparing
		sum = 0;		
		for(i = 0; i < 9; i = i + 1) begin
			sum_temp = { 7'b0, {din[i*8 +: 8]} } * { {9{kernel[i*6+5]}}, kernel[i*6+:6]}; // signed mul  din * kernel
			sum = sum + {sum_temp[14], sum_temp};			
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
            else begin
            
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
            
            long_adder <= 72'h00_00_00_00_00_00_00_00_00;
        end
        else begin
        
            if(counter1 < counter2) begin
            
                din_valid <= 1'b1;
                
                if(long_adder < 72'hFF_FF_FF_FF_FF_FF_FF_FF_FF) begin
                
                    long_adder <= long_adder + 72'h09_08_07_06_05_04_03_02_01;
                end				
            end
            else begin                                
                
                din_valid <= 1'b0;
            end
        end        
    end

    always@(posedge clk) begin
    
        if( din[71-:8]  == 8'hFF  &&
            wr_ptr == rd_ptr &&
            dout_valid == 1'b1  ) begin
			$display("Complete @ %t", $time);
            $stop;
        end
    end
    
endmodule
