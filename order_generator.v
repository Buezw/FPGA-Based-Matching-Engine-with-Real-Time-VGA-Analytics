module order_generator (clk, reset, buy_price, sell_price, KEY4);
    input clk;         
    input reset;       
    output [7:0] buy_price;  
    output [7:0] sell_price; 
    input KEY4;

    // Pseudo-Random Shift Register, has a sequence of 2^15 
    reg [15:0] lfsr1;
    reg [15:0] lfsr2;
    reg [25:0] div;

    reg [1:0] key4_sync;

    // Clock divider
    always @(posedge clk or posedge reset) 
    begin
        if (reset) 
        begin
            div <= 0;
        end 
        else 
        begin
            div <= div + 1;
        end
    end

    wire slow_clk = div[25];


    always @(posedge slow_clk or posedge reset) begin
        if (reset) 
        begin
            key4_sync <= 2'b11;      
        end 
        else 
        begin
            key4_sync <= {key4_sync[0], KEY4};
        end
    end

    wire key4_press = (key4_sync[1] == 1'b1) && (key4_sync[0] == 1'b0);


    always @(posedge slow_clk or posedge reset) begin
        if (reset) begin
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'h3C21;
        end 

        else if (key4_press)
        begin
            lfsr1 <= ({lfsr1[7:0], div[7:0]} == 16'h0000) ? 16'h0001 : {lfsr1[7:0], div[7:0]};
            lfsr2 <= ({lfsr2[7:0], div[15:8]} == 16'h0000) ? 16'h0001 : {lfsr2[7:0], div[15:8]};
        end
        else 
        begin
            // lfsr1 shift
            lfsr1[15] <= lfsr1[14];
            lfsr1[14] <= lfsr1[13];
            lfsr1[13] <= lfsr1[12];
            lfsr1[12] <= lfsr1[11];
            lfsr1[11] <= lfsr1[10];
            lfsr1[10] <= lfsr1[9];
            lfsr1[9]  <= lfsr1[8];
            lfsr1[8]  <= lfsr1[7];
            lfsr1[7]  <= lfsr1[6];
            lfsr1[6]  <= lfsr1[5];
            lfsr1[5]  <= lfsr1[4];
            lfsr1[4]  <= lfsr1[3];
            lfsr1[3]  <= lfsr1[2];
            lfsr1[2]  <= lfsr1[1];
            lfsr1[1]  <= lfsr1[0];
            lfsr1[0]  <= (lfsr1[15] ^ lfsr1[13] ^ lfsr1[12] ^ lfsr1[10]);

            // lfsr2 shift
            lfsr2[15] <= lfsr2[14];
            lfsr2[14] <= lfsr2[13];
            lfsr2[13] <= lfsr2[12];
            lfsr2[12] <= lfsr2[11];
            lfsr2[11] <= lfsr2[10];
            lfsr2[10] <= lfsr2[9];
            lfsr2[9]  <= lfsr2[8];
            lfsr2[8]  <= lfsr2[7];
            lfsr2[7]  <= lfsr2[6];
            lfsr2[6]  <= lfsr2[5];
            lfsr2[5]  <= lfsr2[4];
            lfsr2[4]  <= lfsr2[3];
            lfsr2[3]  <= lfsr2[2];
            lfsr2[2]  <= lfsr2[1];
            lfsr2[1]  <= lfsr2[0];
            lfsr2[0]  <= (lfsr2[15] ^ lfsr2[14] ^ lfsr2[12] ^ lfsr2[3]);
        end
    end

    // Assign Pseudo-Random
    assign buy_price  = 8'd50 + lfsr1[4:0];  
    assign sell_price = 8'd55 + lfsr2[4:0];

endmodule
