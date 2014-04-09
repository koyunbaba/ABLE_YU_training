module col_sym
(
    input clk,
    input resetn,
    input en,
    
    input [8*5-1:0] din,
    input           din_valid,
    
    input [11:0]    width,
    input [11:0]    height,
    
    output [8*5-1:0]    dout,
    output              dout_valid
);

    reg [11:0] row_cnt;
    reg [11:0] col_cnt;
    
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
    
    always@(posedge clk) begin
        
        if( resetn == 1'b0 ) begin
        
            dout <= 0;
        end
        else begin
        
            if( en == 1'b1 ) begin
            
                // first half
                for( i = 0; i < (5-1)/2; i = i + 1 ) begin
                
                    if( col_cnt <= height - ((5-1)/2 - i)) begin
                    
                        dout[8*i +: 8] <= din[8*i +: 8];
                    end
                    else begin
                    
                        dout[8*i +: 8] <= din[ 8*((height - col_cnt)*2 + (5-1)/2) +: 8];
                    end
                end            
                
                // center
                dout[8*((5-1)/2) +: 8]  <= din[8*((5-1)/2) +: 8];
                
                // last half
                for( i = 0; i < (5-1)/2; i = i + 1 ) begin
                
                    if( col_cnt > i)) begin
                    
                        dout[8*((5-1)/2 + i + 1) +: 8] <= din[8*((5-1)/2 + i + 1) +: 8];
                    end
                    else begin
                    
                        dout[8*((5-1)/2 + i + 1) +: 8] <= din[8*((5-1)/2 - col_cnt*2) +: 8];
                    end
                end                        
            end
        end
    end
    
endmodule
