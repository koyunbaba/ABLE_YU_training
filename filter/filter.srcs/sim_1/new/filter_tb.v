`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/12 13:10:34
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

    reg	clk;
    reg	resetn;
    wire	[7:0]	din00;
    wire	[7:0]	din01;
    wire	[7:0]	din02;
    wire	[7:0]	din10;
    wire	[7:0]	din11;
    wire	[7:0]	din12;
    wire	[7:0]	din20;
    wire	[7:0]	din21;
    wire	[7:0]	din22;
    reg	din_valid;
    wire	[7:0]	dout;				
    wire	dout_valid;


    filter filter_uut
	(
        .clk(clk),
        .resetn(resetn),
        .din00(din00),
        .din01(din01),
        .din02(din02),
        .din10(din10),
        .din11(din11),
        .din12(din12),
        .din20(din20),
        .din21(din21),
        .din22(din22),
        .din_valid(din_valid),
        .dout(dout),
        .dout_valid(dout_valid)
    );

    reg [7:0] counter1;
    reg [7:0] counter2;
    
    reg [7:0] fifo[0:1023];
    reg [9:0]  rd_ptr;
    reg [9:0]  wr_ptr;
    
    wire [7:0] ans;
    reg [15:0] temp;
    
    reg [8*9-1 : 0] long_adder;
    
    parameter clk_period = 2;
    initial clk = 1'b0;
    always #(clk_period/2) clk = ~clk;
    
    initial begin
        
        resetn = 1'b0;
        
        #100
        
        resetn = 1'b1;
    end
    
    integer i;
    
    assign ans = fifo[rd_ptr];
    
    assign din00 = long_adder[0 +: 8];
    assign din01 = long_adder[8 +: 8];
    assign din02 = long_adder[16 +: 8];
    
    assign din10 = long_adder[24 +: 8];
    assign din11 = long_adder[32 +: 8];
    assign din12 = long_adder[40 +: 8];

    assign din20 = long_adder[48 +: 8];
    assign din21 = long_adder[56 +: 8];
    assign din22 = long_adder[64 +: 8];
    
    
    always@(*) begin
        
        // golden answer preparing
	    temp <= {8'b0, din00} 			+ {7'b0, din01, 1'b0} + {8'b0, din02} 		+  			 
    			{7'b0, din10, 1'b0} 	+ {6'b0, din11, 2'b0} + {7'b0, din12, 1'b0} +
    			{8'b0, din20} 			+ {7'b0, din21, 1'b0} + {8'b0, din22} 		;
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
                fifo[wr_ptr] <= temp[4 +: 8];
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
        
            $display("fail @ %t", $time);
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
            
            long_adder <= 0;
        end
        else begin
        
            if(counter1 < counter2) begin
            
                din_valid <= 1'b1;
                
                if(long_adder < 72'hFF_FF_FF_FF_FF_FF_FF_FF_FF) begin
                
                    long_adder <= long_adder + 1;
                end                
            end
            else begin                                
                
                din_valid <= 1'b0;
            end
        end        
    end

    always@(posedge clk) begin
    
        if( din22  == 8'hFF  &&
            wr_ptr == rd_ptr &&
            dout_valid == 1'b1  ) begin
        
            $stop;
        end
    end
    
endmodule
