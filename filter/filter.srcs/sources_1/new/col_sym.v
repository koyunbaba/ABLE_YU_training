module col_sym
#(
    parameter FILTER_SZ     = 5,
    parameter DATA_WIDTH    = 8,
    parameter MAX_WIDTH     = 4096,
    parameter MAX_HEIGHT    = 4096    
)
(
    input clk,
    input resetn,
    input en,
    
    input [DATA_WIDTH*FILTER_SZ-1:0] din,
    input           din_valid,
    
    input [$clog2(MAX_WIDTH)-1:0]  width,
    input [$clog2(MAX_HEIGHT)-1:0] height,
    
    output reg [DATA_WIDTH*FILTER_SZ-1:0]   dout,
    output reg             dout_valid
);

    reg [$clog2(MAX_WIDTH)-1:0]  row_cnt;
    reg [$clog2(MAX_HEIGHT)-1:0] col_cnt;
    
    always@(posedge clk) begin
    
        if( resetn == 1'b0 ) begin
        
            row_cnt <= 0;
            col_cnt <= 0;
        end
        else begin
        
            if( en == 1'b1 ) begin
            
                if( din_valid == 1'b1 ) begin
                
                    if( row_cnt == width ) begin
                    
                        row_cnt <= 0;
                        
                        if( col_cnt == height ) begin
                        
                            col_cnt <= 0;
                        end
                        else begin
                        
                            col_cnt <= col_cnt + 1;
                        end
                    end
                    else begin
                    
                        row_cnt <= row_cnt + 1;
                    end
                end                
            end
        end
    end
    
    integer i, j;
    
    /*
        din[ 8*0 +: 8]
        din[ 8*1 +: 8]
        din[ 8*2 +: 8]
        din[ 8*3 +: 8]
        din[ 8*4 +: 8]
    */
    
    always@(posedge clk) begin
        
        if( resetn == 1'b0 ) begin
        
            dout <= 0;
            
            dout_valid <= 1'b0;
        end
        else begin
        
            if( en == 1'b1 ) begin
                
                dout_valid <= din_valid;
                
                if( din_valid == 1'b1 ) begin
                    
                    // first half
                    for( i = 0; i < (FILTER_SZ-1)/2; i = i + 1 ) begin
                    
                        if( col_cnt <= height - ((FILTER_SZ-1)/2 - i)) begin
                        
                            dout[DATA_WIDTH*i +: DATA_WIDTH] <= din[DATA_WIDTH*i +: DATA_WIDTH];
                        end
                        else begin
                                                    
                            dout[DATA_WIDTH*i +: DATA_WIDTH] <= din[ DATA_WIDTH*((FILTER_SZ - i - 1) - (height - col_cnt)*2) +: DATA_WIDTH];
                            
                            // d0 <= d4 cnt == height
                            // d0 <= d2 cnt == height - 1
                            
                            // d1 <= d3 cnt == height
                        end
                    end            
                    
                    // center
                    dout[DATA_WIDTH*((FILTER_SZ-1)/2) +: DATA_WIDTH]  <= din[DATA_WIDTH*((FILTER_SZ-1)/2) +: DATA_WIDTH];
                    
                    // last half
                    for( i = 0; i < (FILTER_SZ-1)/2; i = i + 1 ) begin
                    
                        if( col_cnt > i) begin
                        
                            dout[DATA_WIDTH*((FILTER_SZ-1)/2 + i + 1) +: DATA_WIDTH] <= din[DATA_WIDTH*((FILTER_SZ-1)/2 + i + 1) +: DATA_WIDTH];
                        end
                        else begin
                                                    
                            dout[DATA_WIDTH*((FILTER_SZ-1)/2 + i + 1) +: DATA_WIDTH] <= din[DATA_WIDTH*(((FILTER_SZ-1)/2 - i - 1) + col_cnt*2) +: DATA_WIDTH];
                            
                            // d3 <= d1, cnt == 0
                            
                            // d4 <= d0, cnt == 0
                            // d4 <= d2, cnt == 1
                        end
                    end                        
                end
            end
        end
    end
    
endmodule
