module order_generator (clk, reset, buy_price, sell_price, KEY, slow_clk);
    input clk;         
    input reset;   
    input [3:0] KEY;    
    output [7:0] buy_price;  
    output [7:0] sell_price; 
    output slow_clk;
    
    reg [15:0] lfsr1;
    reg [15:0] lfsr2;
    reg [25:0] div;

    reg [1:0] key3_sync;

    //key3 rising edge detection
    wire load_lfsr; 

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div <= 26'h0000000;
        end else begin
            div <= div + 1;
        end
    end

    assign slow_clk = div[25]; 

    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            key3_sync <= 2'b00;
        end else begin
            key3_sync <= {key3_sync[0], KEY[3]};
        end
    end
    
    assign load_lfsr = key3_sync[1] & (~key3_sync[0]); 

    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            // Reset
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'h3C21;
        end 
        else if (load_lfsr) begin
            lfsr1 <= ({lfsr1[7:0], div[7:0]} == 16'h0000) ? 16'h0001 : {lfsr1[7:0], div[7:0]};
            lfsr2 <= ({lfsr2[7:0], div[15:8]} == 16'h0000) ? 16'h0001 : {lfsr2[7:0], div[15:8]};
        end 
        else begin
            // Shift 
            lfsr1 <= {lfsr1[14:0], (lfsr1[15] ^ lfsr1[13] ^ lfsr1[12] ^ lfsr1[10])};
            lfsr2 <= {lfsr2[14:0], (lfsr2[15] ^ lfsr2[14] ^ lfsr2[12] ^ lfsr2[3])};
        end
    end

    assign buy_price  = 8'd50 + lfsr1[4:0];  
    assign sell_price = 8'd55 + lfsr2[4:0];

endmodule
