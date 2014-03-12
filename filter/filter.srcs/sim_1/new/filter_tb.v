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
    reg	[7:0]	din00;
    reg	[7:0]	din01;
    reg	[7:0]	din02;
    reg	[7:0]	din10;
    reg	[7:0]	din11;
    reg	[7:0]	din12;
    reg	[7:0]	din20;
    reg	[7:0]	din21;
    reg	[7:0]	din22;
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
        
    parameter clk_period = 10;
    initial clk = 1'b0;
    always #(clk_period/2) clk = ~clk;
    
    initial begin
        
        resetn = 1'b0;
        
        #100
        
        resetn = 1'b1;
    end
        
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
    always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
        
            din_valid <= 1'b0;
            
            din00 <= 0;
            din01 <= 0;
            din02 <= 0;
            
            din10 <= 0;
            din11 <= 0;
            din12 <= 0;
            
            din20 <= 0;
            din21 <= 0;
            din22 <= 0;
        end
        else begin
        
            if(counter1 < counter2) begin
                din_valid <= 1'b1;
                
                din00 <= din00 + 1;
                din01 <= din01 + 1;
                din02 <= din02 + 1;
                din10 <= din10 + 1;
                din11 <= din11 + 1;
                din12 <= din12 + 1;
                din20 <= din20 + 1;
                din21 <= din21 + 1;
                din22 <= din22 + 1;
            end
            else begin
            
                din_valid <= 1'b0;
            end
        end        
    end
endmodule
