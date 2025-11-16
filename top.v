// =====================================================
// Top-level module with VGA added (old Verilog style)
// =====================================================

module top (
    CLOCK_50,
    KEY,
    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    LEDR,

    // === VGA Output ===
    VGA_R, VGA_G, VGA_B,
    VGA_HS, VGA_VS, KEY4
);

    input  CLOCK_50;
    input  [0:0] KEY;

    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    output [9:0] LEDR;

    // === VGA physical pins ===
    output [3:0] VGA_R;
    output [3:0] VGA_G;
    output [3:0] VGA_B;
    output VGA_HS;
    output VGA_VS;

    input KEY4;

    // ==============================
    // Basic clock & reset
    // ==============================
    wire clk_50;
    wire reset;

    assign clk_50 = CLOCK_50;
    assign reset  = ~KEY[0];   // KEY[0] active low

    // ==============================
    // VGA 25MHz clock divider
    // ==============================
    wire clk_25;

    clk_div2 div25 (
        .clk_in(clk_50),
        .reset(reset),
        .clk_out(clk_25)
    );

    // ==============================
    // Signals
    // ==============================
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

    // ==============================
    // 1. Order Generator
    // ==============================
    order_generator generator (
        .clk(clk_50),
        .reset(reset),
        .buy_price(buy_price),
        .sell_price(sell_price),
        .KEY4(KEY4)
    );

    // ==============================
    // 2. Matching Engine
    // ==============================
    matching_engine engine(clk, reset, buy_price, sell_price, match_signal,
                        trade_price, best_bid, best_ask);


    // ==============================
    // 3. Controller FSM
    // ==============================
    controller_fsm controller (
        .clk(clk_50),
        .reset(reset),
        .match_signal(match_signal),
        .halt_flag(halt_signal),
        .state(state),
        .enable_count(enable_count)
    );

    // ==============================
    // 4. Trade Counter
    // ==============================
    counter trade_counter (
        .clk(clk_50),
        .reset(reset),
        .match_signal(match_signal),
        .enable_count(enable_count),
        .trade_count(trade_count),
        .halt_signal(halt_signal)
    );

    // ==============================
    // 5. Spread Calculator
    // ==============================
    spread spread_calc (
        .clk(clk_50),
        .reset(reset),
        .match_signal(match_signal),
        .enable_count(enable_count),
        .buy_price(buy_price),
        .sell_price(sell_price),
        .spread(spread_now)
    );

    // ==============================
    // 6. HEX Display + LEDs
    // ==============================
    display_hex display_unit (
        .buy_price(buy_price),
        .sell_price(sell_price),
        .spread_now(spread_now),
        .trade_count(trade_count),
        .state(state),
        .halt_signal(halt_signal),
        .match_signal(match_signal),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .LEDR(LEDR)
    );

    // =====================================================
    // 7. VGA Controller + Display Engine
    // =====================================================

    wire [9:0] h_cnt;
    wire [9:0] v_cnt;
    wire video_on;

    vga_controller vga_ctrl (
        .clk_25mhz(clk_25),
        .reset(reset),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .video_on(video_on)
    );

    vga_display vga_disp (
        .clk_25mhz(clk_25),
        .video_on(video_on),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .buy_price(buy_price),
        .sell_price(sell_price),
        .trade_count(trade_count),
        .spread(spread_now),
        .halt_signal(halt_signal),
        .R(VGA_R),
        .G(VGA_G),
        .B(VGA_B)
    );

endmodule
