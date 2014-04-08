`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/04/03 23:39:18
// Design Name: 
// Module Name: row_sym
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

/**
    3:
    
    +------------------------------------+
    |                                    |
    +------------>[D]--+                 |
    |                  |                 |
    |                  +-->[M(1)]        +-->[M(1)] 
>>--+-->[M    ]-->[D]----->[M   ]-->[D]--+-->[M   ]-->[D]
    +-->[M(-1)]                          |
    |                                    |
    +------------------------------------+
    
    
    5:
    
    +---------------------------------------------------------------------------+
    |                                                                           |
    |                     +-----------------------------------+                 |
    |                     |                                   |                 |
    +-------------->[D]---+---------->[D]---+                 |                 |
    |                     |                 |                 |                 |
>>--+---->[M    ]         +-->[M(1)]        +-->[M(1)]        +-->[M(1)]        +-->[M(1)]
    +---->[M(-1)]--->[D]----->[M   ]-->[D]--+-->[M   ]-->[D]----->[M   ]-->[D]--+-->[M   ]-->[D]
    |  +->[M(-2)]                           |                                   |
    |  |                                    |                                   |
    |  +------------------------------------+                                   |
    |                                                                           |
    +---------------------------------------------------------------------------+
       
       
*/

module row_sym
#(
    parameter FILTER_SZ = 5,    
    parameter MAX_WIDTH = 4096
)
(
    input           clk,
    input           resetn,
    input           en,
    
    input   [7:0]   din,
    input           din_valid,
    
    input   [$clog2(MAX_WIDTH)-1:0] width,
    
    
    output  [ 8*FILTER_SZ-1:0 ] dout,
    output                                  dout_valid
);

    reg [$clog2(MAX_WIDTH)-1:0]     counter;
    
    reg [8:0]   buf_arr[0:(FILTER_SZ-1)/2 - 1];
    reg [8:0]   pipe_arr[0:(FILTER_SZ-1)];
    
    wire [8:0]  din_temp;
        
    integer i;
    
    genvar j;
    
    assign din_temp = {din_valid, din};
    assign dout_valid = pipe_arr[(FILTER_SZ-1)/2][8] & en;

    generate
    
        for( j = 0; j < FILTER_SZ; j = j + 1 ) begin
        
            assign dout[j*8 +: 8] = pipe_arr[j][7:0];
        end
    endgenerate
    
    always@(posedge clk) begin
        if( resetn == 1'b0 ) begin
        
            counter <= 0;
        end
        else begin
        
            if( en == 1'b1 ) begin
            
                if( buf_arr[(FILTER_SZ-1)/2-1][8]  == 1'b1 ) begin
                
                    if( counter == width ) begin
                    
                        counter <= 0;
                    end
                    else begin
                    
                        counter <= counter + 1;
                    end
                end
            end
        end
    end
    
    /*
        last half
    */
    always@(posedge clk) begin
        if( resetn == 1'b0 ) begin
        
            for( i = (FILTER_SZ-1)/2; i < FILTER_SZ; i = i+1 ) begin
            
                pipe_arr[i] <= 0;
            end
        end 
        else begin

            if( en == 1'b1 ) begin
            
                for( i = (FILTER_SZ-1)/2; i < FILTER_SZ-1; i = i+1 ) begin
                
                    if( counter == 0 ) begin
                        
                        pipe_arr[i] <= buf_arr[(FILTER_SZ-1)/2 - (i - (FILTER_SZ-1)/2) - 1];
                    end
                    else begin
                    
                        pipe_arr[i] <= pipe_arr[i-1];
                    end
                end         

                if( counter == 0 ) begin
                    
                    pipe_arr[FILTER_SZ - 1] <= din_temp;
                end
                else begin
                
                    pipe_arr[FILTER_SZ - 1] <= pipe_arr[FILTER_SZ - 2];
                end
            end
        end
    end

    /*
        begin half
    */
    always@(posedge clk) begin
        if( resetn == 1'b0 ) begin
        
            for( i = 1; i < (FILTER_SZ-1)/2; i = i+1 ) begin
            
                pipe_arr[i] <= 0;
            end
        end 
        else begin
            
            if( en == 1'b1 ) begin
                for( i = 1; i < (FILTER_SZ-1)/2; i = i+1 ) begin
                
                    if( counter == 0 ) begin
                        
                        pipe_arr[i] <= buf_arr[i-1];
                    end
                    else begin
                    
                        pipe_arr[i] <= pipe_arr[i-1];
                    end
                end         
            end
        end
    end

    /*
        pipe_arr[0]
    */
    always@(posedge clk) begin
        if( resetn == 1'b0 ) begin
        
            pipe_arr[0] <= 0;
        end 
        else begin
        
            if( en == 1'b1 ) begin
                if( counter <= width - (FILTER_SZ-1)/2 ) begin
                    
                    pipe_arr[0] <= din_temp;
                end
                else begin
                
                    pipe_arr[0] <= pipe_arr[((FILTER_SZ-1)/2 - (width - counter))*2 - 1];
                end
            end
        end
    end
    
    /*
        buf_arr
    */
    always@(posedge clk) begin
    
        if( resetn == 1'b0 ) begin
        
            for( i = 0; i < (FILTER_SZ-1)/2; i = i+1 ) begin
            
                buf_arr[i] <= 0;
            end
        end 
        else begin
            
            if( en == 1'b1 ) begin
                
                buf_arr[0] <= din_temp;
            
                for( i = 1; i < (FILTER_SZ-1)/2; i = i+1 ) begin
                    
                    buf_arr[i] <= buf_arr[i-1];
                end         
            end
        end 
    end
endmodule
