// =====================================================
// Module: display_hex
// =====================================================
module display_hex (buy_price,sell_price,spread_now,trade_count, 
    state, halt_signal, match_siganl, HEX0,HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

    input [7:0] buy_price;
    input [7:0] sell_price;
    input [7:0] spread_now;
    input [7:0] trade_count;
    input [1:0] state;
    input halt_signal;
    input match_siganl;

    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output [9:0] LEDR;

    // BCD
    wire [3:0] buy_lo, buy_hi, sell_lo, sell_hi, spread_lo, spread_hi;

    assign buy_lo = buy_price[3:0];
    assign buy_hi = buy_price[7:4];
    assign sell_lo = sell_price[3:0];
    assign sell_hi = sell_price[7:4];
    assign spread_lo = spread_now[3:0];
    assign spread_hi = spread_now[7:4];

    //Dispaly on HEX
    seg7 h0 (buy_lo, HEX0);
    seg7 h1 (buy_hi, HEX1);
    seg7 h2 (sell_lo, HEX2);
    seg7 h3 (sell_hi, HEX3);
    seg7 h4 (spread_lo, HEX4);
    seg7 h5 (spread_hi, HEX5);

    // LED Indicators
    assign LEDR[0] = match_siganl;
    assign LEDR[1] = halt_signal;  
    assign LEDR[3:2] = state;
    assign LEDR[9:4] = trade_count[5:0];

endmodule


module seg7 (
    input [3:0] hex,
    output reg [6:0] seg
);
    always @(*) 
    begin
        case (hex)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
