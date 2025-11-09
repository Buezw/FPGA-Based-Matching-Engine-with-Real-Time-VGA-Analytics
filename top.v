// =====================================================
// Module: system_top
// =====================================================

module system_top (CLOCK_50, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

    // -----------------------------
    // Port declarations
    // -----------------------------
    input  CLOCK_50;
    input  [0:0] KEY;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output [9:0] LEDR;

    // -----------------------------
    // Internal wires
    // -----------------------------
    wire clk;
    wire reset;

    assign clk   = CLOCK_50;
    assign reset = ~KEY[0];  // active-high reset (KEY0 pressed = reset)

    wire [7:0] buy_price;
    wire [7:0] sell_price;
    wire [7:0] best_bid;
    wire [7:0] best_ask;
    wire [7:0] trade_price;
    wire [7:0] spread_now;
    wire [7:0] trade_count;
    wire [1:0] state;
    wire match_flag;
    wire halt_flag;
    wire enable_count;

    // -----------------------------
    // Module Instantiations
    // -----------------------------

    // 1. Order Generator
    order_generator u_gen(clk, reset, buy_price, sell_price);

    // 2. Matching Engine
    //   Calculates best_bid / best_ask / trade_price / match_flag
    matching_engine_8 u_match(
        clk,
        reset,
        buy_price,
        sell_price,
        match_flag,
        trade_price,
        best_bid,
        best_ask
    );

    // 3. Controller FSM
    controller_fsm u_ctrl(clk, reset, match_flag, halt_flag, state, enable_count);

    // 4. Trade Counter
    counter u_count(clk, reset, match_flag, enable_count, trade_count, halt_flag);

    // 5. Spread Accumulator
    spread_accumulator u_spread(clk, reset, best_bid, best_ask, enable_count, match_flag, spread_now);

    // 6. Display (HEX + LED)
    display_hex u_disp(
        buy_price, sell_price, spread_now, trade_count,
        state, halt_flag, match_flag,
        HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR
    );

endmodule
