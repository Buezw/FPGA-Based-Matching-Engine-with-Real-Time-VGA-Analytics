module top (
    // 端口定义
    CLOCK_50, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, 
    // 音频端口
    I2C_SDAT, I2C_SCLK, AUD_XCK, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT, AUD_DACDAT
);

    input CLOCK_50;
    input [3:0] KEY;

    output [6:0] HEX0;
    output [6:0] HEX1;
    output [6:0] HEX2;
    output [6:0] HEX3;
    output [6:0] HEX4;
    output [6:0] HEX5;
    output [9:0] LEDR;

    inout  I2C_SDAT;
    output I2C_SCLK;
    output AUD_XCK;
    output AUD_BCLK;
    output AUD_ADCLRCK;
    output AUD_DACLRCK;
    input  AUD_ADCDAT;
    output AUD_DACDAT;

    wire clk_50;
    wire reset;
    wire KEY4;

    assign clk_50 = CLOCK_50;
    assign reset = ~KEY[0];
    assign KEY4 = ~KEY[3];

    wire clk_25;
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

    // 音频内部信号
    wire play_pulse;
    wire audio_allowed;
    wire audio_write;
    wire [31:0] aud_left;
    wire [31:0] aud_right;

    // --- 核心逻辑 (全部使用位置调用) ---

    // 1. 分频器: (clk_in, reset, clk_out)
    clk_div2 div25(clk_50, reset, clk_25);

    // 2. 订单生成: (clk, reset, buy_price, sell_price, KEY4)
    order_generator generator(clk_50, reset, buy_price, sell_price, KEY4);

    // 3. 撮合引擎: (clk, reset, buy_price, sell_price, match_signal, trade_price, best_bid, best_ask)
    matching_engine engine(clk_50, reset, buy_price, sell_price, match_signal, trade_price, best_bid, best_ask);

    // 4. 控制器 FSM: (clk, reset, match_signal, halt_flag, state, enable_count)
    controller_fsm controller(clk_50, reset, match_signal, halt_signal, state, enable_count);

    // 5. 计数器: (clk, reset, match_signal, enable_count, trade_count, halt_signal)
    counter trade_counter(clk_50, reset, match_signal, enable_count, trade_count, halt_signal);

    // 6. 价差计算: (clk, reset, match_signal, enable_count, buy_price, sell_price, spread)
    spread spread_calc(clk_50, reset, match_signal, enable_count, buy_price, sell_price, spread_now);

    // 7. 显示: (buy, sell, spread, trade, state, halt, match, HEX0...HEX5, LEDR)
    display_hex display_unit(buy_price, sell_price, spread_now, trade_count, state, halt_signal, match_signal, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

   
endmodule