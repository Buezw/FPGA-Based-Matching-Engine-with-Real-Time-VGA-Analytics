module top (CLOCK_50, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS);

    input CLOCK_50;
    input [3:0] KEY;

    output [6:0] HEX0;
    output [6:0] HEX1;
    output [6:0] HEX2;
    output [6:0] HEX3;
    output [6:0] HEX4;
    output [6:0] HEX5;

    output [9:0] LEDR;

    output [3:0] VGA_R;
    output [3:0] VGA_G;
    output [3:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    
    wire clk_50;
    wire reset;
    wire KEY4;

    assign clk_50 = CLOCK_50;
    assign reset = ~KEY[0];
    assign KEY4 = ~KEY[3];

    wire clk_25;
    clk_div2 div25(clk_50, reset, clk_25);

    wire [7:0] buy_price;
    wire [7:0] sell_price;
    wire [7:0] best_bid;
    wire [7:0] best_ask;
    wire [7:0] trade_price;
    wire [7:0] spread_now;
    wire [7:0] trade_count;

    wire [1:0] state;

    wire match_signal;
    wire halt_signal;
    wire enable_count;

    order_generator generator(clk_50, reset, buy_price, sell_price, KEY4);

    matching_engine engine(clk_50, reset, buy_price, sell_price, match_signal, trade_price, best_bid, best_ask);

    controller_fsm controller(clk_50, reset, match_signal, halt_signal, state, enable_count);

    counter trade_counter(clk_50, reset, match_signal, enable_count, trade_count, halt_signal);

    spread spread_calc(clk_50, reset, match_signal, enable_count, buy_price, sell_price, spread_now);

    display_hex display_unit(buy_price, sell_price, spread_now, trade_count, state, halt_signal, match_signal,
                             HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);


endmodule
