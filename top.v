// =====================================================
// Module: top
// =====================================================

module top (CLOCK_50, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);
    input  CLOCK_50;
    input  [0:0] KEY;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output [9:0] LEDR;

    wire clk;
    wire reset;

    assign clk   = CLOCK_50;
    assign reset = ~KEY[0];  

    wire [7:0] buy_price;
    wire [7:0] sell_price;
    wire [7:0] best_bid;
    wire [7:0] best_ask;
    wire [7:0] trade_price;
    wire [7:0] spread_now;
    wire [7:0] trade_count;
    wire [1:0] state;
    wire match_flag;
    wire halt_signal;
    wire enable_count;
 
    // 1. Order Generator
    order_generator generator(clk, reset, buy_price, sell_price);

    // 2. Matching Engine
    matching_engine match(clk, reset, buy_price, sell_price, match_siganl, trade_price, best_bid, best_ask);

    // 3. Controller FSM
    controller_fsm controller(clk, reset, match_siganl, halt_signal, state, enable_count);

    // 4. Trade Counter
    counter counter(clk, reset, match_siganl, enable_count, trade_count, halt_signal);

    // 5. Spread Accumulator
    spread spread(clk, reset, best_bid, best_ask, enable_count, match_siganl, spread_now);

    // 6. Display (HEX + LED)
    display_hex display(buy_price, sell_price, spread_now, trade_count,state,halt_signal, match_siganl,HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

endmodule
