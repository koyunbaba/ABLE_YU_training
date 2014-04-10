`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/09 22:29:11
// Design Name: 
// Module Name: col_sym_tb
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


module col_sym_tb;

    parameter FILTER_SZ     = 5;
    parameter DATA_WIDTH    = 8;
    parameter MAX_WIDTH     = 4096;
    parameter MAX_HEIGHT    = 4096; 
    
    reg clk;
    reg resetn;
    reg en;
    
    reg [DATA_WIDTH*FILTER_SZ-1:0] din;
    reg           din_valid;
    
    reg [$clog2(MAX_WIDTH)-1:0]    width;
    reg [$clog2(MAX_HEIGHT)-1:0]   height;
    
    wire [DATA_WIDTH*FILTER_SZ-1:0]    dout;
    wire              dout_valid;

    col_sym col_sym_uut
    (
        .clk(clk),
        .resetn(resetn),
        .en(en),
        
        .din(din),
        .din_valid(din_valid),
        
        .width(width),
        .height(height),
        
        .dout(dout),
        .dout_valid(dout_valid)
    );
    
    parameter clk_period = 10;
    initial clk = 0;
    always #(clk_period/2) clk = ~clk;
    
    integer i;
    reg [$clog2(MAX_WIDTH)-1:0] count;
    
    initial begin
    
        resetn = 1'b0;
        
        width = 9;
        height = 9;
        
        #100
        
        resetn = 1'b1;
    end
    
    always@(posedge clk) begin
        if( resetn == 1'b0 ) begin
        
            count <= 0;         
        end
        else begin
        
            if( din_valid == 1'b1 ) begin
            
                if( count == width ) begin
                
                    count <= 0;             
                end
                else begin
                
                    count <= count + 1;
                end
            end
        end
    end
    
    always@(posedge clk) begin
    
        if( resetn == 1'b0 ) begin
        
            for( i = 0; i < FILTER_SZ; i = i + 1) begin
            
                din[DATA_WIDTH*i +: DATA_WIDTH] <= FILTER_SZ-i;
            end

            din_valid <= 1'b0;
            en <= 1'b0;
            
        end
        else begin

            if( count == width ) begin
            
                din[DATA_WIDTH*0 +: DATA_WIDTH] <= din[DATA_WIDTH*0 +: DATA_WIDTH] + 1;
                
                for( i = 1; i < FILTER_SZ; i = i + 1) begin
            
                    din[DATA_WIDTH*i +: DATA_WIDTH] <= din[DATA_WIDTH*(i-1) +: DATA_WIDTH];
                end

            end
            
            din_valid <= 1'b1;
            en <= 1'b1;
        end
    end
endmodule
