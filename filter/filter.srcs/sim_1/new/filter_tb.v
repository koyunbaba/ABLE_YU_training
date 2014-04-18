`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/03/24 10:51:43
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
	parameter KERNEL_SIZE = 7;		
	parameter COLS = 2048;
	parameter ROWS = 10;
	parameter M_BYTES_IN = 4;
	parameter DATA_NUM = 1;
	parameter MAX_IMAGE_SIZE = $clog2(COLS)+1;
	//-------------------------------------------------------
	parameter DATA_IN_SIZE =8;
	parameter KERNEL_DATA_SIZE = KERNEL_SIZE*KERNEL_SIZE*6;
	parameter DATA_INPUT_SIZE = COLS*ROWS*8;
	parameter DATA_INPUT_COUNT = COLS*ROWS*DATA_NUM;
    reg		clk;	
    reg		resetn;
	reg		row_neg;
	reg		col_neg;
	reg [MAX_IMAGE_SIZE-1:0]	cols;
	reg [MAX_IMAGE_SIZE-1:0]	rows;
    //reg	[DATA_IN_SIZE-1:0]	din;		
	reg signed	[KERNEL_DATA_SIZE-1:0] 	kernel;	    
    wire signed	[32*M_BYTES_IN-1:0]	dout;				
    wire [M_BYTES_IN-1:0] dout_valid;

	reg	din_valid;
	reg [M_BYTES_IN*8-1:0] din_piso_result;
	
	reg update_kernel;
	wire [5:0] kernel_piso_result;		
	wire kernel_piso_valid_result;

	filter_top #(.KERNEL_SIZE(KERNEL_SIZE), .M_BYTES_IN(M_BYTES_IN), .MAX_IMAGE_SIZE(MAX_IMAGE_SIZE))	filter_top_uut
	(
		.clk(clk),
		.resetn(resetn),
		.col_neg(col_neg),
		.row_neg(row_neg),
		.din(din_piso_result),		
		.kernel(kernel_piso_result),	
		.kernel_valid(kernel_piso_valid_result),	
		.d_cols(cols),
		.d_rows(rows),
		.din_valid(din_valid),
		.en(1'b1),
		.dout(dout),				
		.dout_valid(dout_valid)
    );
	
	reg data_tranmit_en;
    reg [15:0] counter1;
    reg [15:0] counter2;
	reg [15:0] counter3;
    reg signed [MAX_IMAGE_SIZE+1-1:0] counter_col;
	reg [MAX_IMAGE_SIZE+1-1:0] counter_row;
	
	
    reg [31:0] fifo[0:COLS+1];
    reg [$clog2(COLS+1):0]  rd_ptr;
    reg [$clog2(COLS+1):0]  wr_ptr;
    
    wire signed [31:0] ans[M_BYTES_IN-1:0];
    reg [31:0] temp [M_BYTES_IN-1:0];    
    reg [DATA_INPUT_SIZE*DATA_NUM-1 : 0] long_adder;
    
    parameter clk_period = 10;
    initial clk = 1'b0;
	
    always #(clk_period/2) clk = ~clk;

	integer signed ii;
	integer signed i;
    integer signed j;
	integer signed k;
	integer signed m;
	integer signed p;
	integer signed q;
	
    initial begin
        
        resetn = 1'b0;
		update_kernel = 1'b0;
		row_neg = 1'b0;
		col_neg = 1'b0;	
		rows = ROWS;
		cols = COLS;
		din_valid = 0;		
		data_tranmit_en = 1'b0;
		/*kernel = { 6'd1,  6'd2,  6'd2, -6'd2, -6'd1,
				   6'd2,  6'd4,  6'd4, -6'd4, -6'd2,
				   6'd1,  6'd2,  6'd4, -6'd2, -6'd1,
				  -6'd2, -6'd4, -6'd4,  6'd4,  6'd2,
				  -6'd1, -6'd2, -6'd2,  6'd2,  6'd1}; */
		
		kernel = {KERNEL_SIZE*KERNEL_SIZE{6'd1}}; 
		
		i = 0;
		j = 0;
		k = 0;
		m = 0;
		p = 0;
		q = 0;
				  
        #100        
        resetn = 1'b1;
		#(clk_period)
		update_kernel <= 1'b1;
		#(clk_period)
		update_kernel <= 1'b0;		
    end
    
	genvar gi;
    generate
		for(gi = 0; gi < M_BYTES_IN; gi = gi + 1) begin
			assign ans[gi] = fifo[rd_ptr+gi];
		end
    endgenerate
    //assign din = long_adder[0 +: DATA_IN_SIZE];

	reg [31:0] sum;
	reg [14:0] sum_temp;
	reg signed [14:0] counter_row_temp;
	reg signed [14:0] counter_col_temp;
	
	//ans
    always@(*) begin
        
		if(resetn == 1'b0) begin
			sum <= 0;
			sum_temp <= 0;
			for(ii = 0; ii < M_BYTES_IN; ii = ii + 1) begin
				temp[ii] <= 0;
			end
			counter_row_temp <= 0;
			counter_col_temp <= 0;
		end
		else begin
        // golden answer preparing
			for(ii = 0; ii < M_BYTES_IN; ii = ii + 1) begin
				sum = 0;		
				sum_temp = 0;
				counter_row_temp = counter_row;
				counter_col_temp = $signed(counter_col - ii);
				if(counter_col_temp < 0) begin
					counter_col_temp = counter_col_temp + COLS;
					counter_row_temp = counter_row_temp - 1;
				end
					
				for(j = $signed(counter_row_temp - KERNEL_SIZE/2); j <= $signed(counter_row_temp + KERNEL_SIZE/2); j = j + 1) begin			
					if($signed(j) < 0) begin
						k = -j;
					end
					else if( j >= ROWS) begin
						k = (ROWS-1)-(j-ROWS+1);
					end
					else begin
						k = j;
					end
					
					k = ROWS - k - 1;
					p = j - $signed(counter_row_temp - KERNEL_SIZE/2);
					
					for(i = $signed(counter_col_temp - KERNEL_SIZE/2); i <= $signed(counter_col_temp + KERNEL_SIZE/2); i = i + 1) begin		
						q = i - $signed(counter_col_temp - KERNEL_SIZE/2);
						if($signed(i) < 0) begin
							m = -i;
						end
						else if( i >= COLS) begin
							m = (COLS-1)-(i-COLS+1);
						end
						else begin
							m = i;
						end			
						m = COLS - m - 1;
						if($signed(j) < 0 || $signed(i) < 0 || j >= ROWS || i >= COLS) begin
							sum_temp = 0;
						end
						else begin
							sum_temp = { 7'b0, {long_adder[( (k*COLS+m) *8) +: 8]} } * { {9{kernel[(p*KERNEL_SIZE+q )*6+5]}}, kernel[ (p*KERNEL_SIZE+q )*6+:6]}; // signed mul  din * kernel
						end
						sum = sum + {{17{sum_temp[14]}}, sum_temp};		
					end
					
				end	
				temp[M_BYTES_IN-1-ii] = sum;
				//$display("%d: result %d %d %h @ %t", ii, counter_col_temp, counter_row_temp, sum, $time);
			end
			//$display("result %d @ %t", sum, $time);		
		
		end
    end
    
    // answer fifo
    always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
        
            // fifo clean and pointer reset
            wr_ptr <= 0;
            rd_ptr <= 0;            
            for(i = 0; i < 4096; i = i + 1) begin                
                fifo[i] <= 0;                
            end
        end
        else begin            
			if( din_valid == 1'b1 ) begin
				for(ii = 0; ii < M_BYTES_IN; ii = ii + 1) begin
								
					// answer push-in
					fifo[wr_ptr] = temp[ii];											
					wr_ptr = wr_ptr + 1;
				end
			end
			
        end
    end
    
    // wrong answer detect and alarm
    always@(posedge clk) begin
    
		for(ii = 0; ii < M_BYTES_IN; ii = ii + 1) begin
			if( dout_valid[ii] == 1'b1) begin
				if(dout[32*ii +: 32] != ans[ii]) begin        
					$display("%d: fail %h, correct %h, @  %t", ii, dout[32*ii +: 32], ans[ii], $time);
				end				
				/*else begin
					$display("%d: Result %h, correct %h, @  %t", ii, dout[32*ii +: 32], ans[ii], $time);
				end*/
				rd_ptr = rd_ptr + 1;
			end
			
		end
	end
    
    // counter1 for data transmition		
    always@(posedge clk) begin
    
        if(resetn == 1'b0) begin
			din_valid <= 0;			
            counter1 <= 0;           
			din_piso_result <= 0;			
			counter_col <= -1;
			counter_row <= 0;
			
        end
        else begin            
			if(data_tranmit_en == 1'b1) begin				
				if(counter1 >= DATA_INPUT_COUNT) begin
					data_tranmit_en <= 1'b0;
					counter1 <= 0;
					din_valid <= 0;					
					counter_col <= -1;
					counter_row <= 0;
				end
				else begin					
					counter1 <= counter1 + M_BYTES_IN;
					for(i = 0; i < M_BYTES_IN; i = i + 1) begin
						if($signed(DATA_INPUT_COUNT-counter1-1-i) >= 0) begin
							din_piso_result[i*8 +: 8] <= long_adder[(DATA_INPUT_COUNT-counter1-1-i)*8 +: 8];	
							din_valid <= 1'b1;
						end
						else begin
							din_piso_result[i*8 +: 8] <= 0;						
							din_valid <= 1'b0;
						end
					end
					
					if(counter1 < 2) begin
						//din <= long_adder[0 +: DATA_IN_SIZE];						
					end
					else begin
						//din <= long_adder[(counter1-2)*8 +: DATA_IN_SIZE];										
					end					
					
					if(counter_col + M_BYTES_IN > COLS - 1) begin
						counter_col <= counter_col + M_BYTES_IN - COLS;
						counter_row <= counter_row + 1;
					end
					else begin
						counter_col <= counter_col + M_BYTES_IN;
					end
				end
			end       
			else begin
				counter1 <= 0;
				din_valid <= 0;				
				din_piso_result <= 0;
				counter_col <= -1;
				counter_row <= 0;
			end
        end
    end
	
	// counter2,3 for enable data transmition		
    always@(posedge clk) begin
	
		if(resetn == 1'b0) begin
			counter2 <= 0;
			counter3 <= 30;
			for(i = 0; i < DATA_INPUT_COUNT; i = i + 1) begin
				long_adder[i*8 +: 8] <= DATA_INPUT_COUNT-i;
			end
			/*long_adder <= {8'd01, 8'd02, 8'd03, 8'd04, 8'd05, 8'd06, 8'd07, 
						   8'd08, 8'd09, 8'd10, 8'd11, 8'd12, 8'd13, 8'd14, 
						   8'd15, 8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd21, 
						   8'd22, 8'd23, 8'd24, 8'd25, 8'd26, 8'd25, 8'd25};*/
		end
		else begin
			if(kernel_piso_valid_result == 1'b0)  begin
				if(data_tranmit_en == 1'b0)	 begin
					if(counter2 == counter3) begin
						counter2 <= 0;
						counter3 <= counter3 + 1;
						data_tranmit_en = 1'b1;
						//for(i = 0; i < KERNEL_SIZE*(DATA_NUM+2); i = i + 1) begin
							//long_adder[i*8 +: 8] <= $random % 256;
						//end
					end
					else begin 
						counter2 <= counter2 + 1;
					end
					
					if(counter3 > 305) begin
						counter3 <= 1;
						counter2 <= 0;
					end			
					
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

