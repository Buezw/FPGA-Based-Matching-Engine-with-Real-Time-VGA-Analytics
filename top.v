// ============================================================================
// 文件名: top.v
// 说明: 顶层模块，集成交易引擎、音频反馈及VGA价格走势显示
// ============================================================================

module top (
    // --- 基础输入 ---
    CLOCK_50, KEY, 
    // --- 数码管与LED输出 ---
    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR, 
    // --- 音频端口 ---
    I2C_SDAT, I2C_SCLK, AUD_XCK, AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT, AUD_DACDAT,
    // --- [新增] VGA端口 ---
    VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS
);

    // ========================================================================
    // 1. 端口定义
    // ========================================================================
    input CLOCK_50;
    input [3:0] KEY;

    output [6:0] HEX0;
    output [6:0] HEX1;
    output [6:0] HEX2;
    output [6:0] HEX3;
    output [6:0] HEX4;
    output [6:0] HEX5;
    output [9:0] LEDR;

    // 音频 IO
    inout  I2C_SDAT;
    output I2C_SCLK;
    output AUD_XCK;
    output AUD_BCLK;
    output AUD_ADCLRCK;
    output AUD_DACLRCK;
    input  AUD_ADCDAT;
    output AUD_DACDAT;

    // [新增] VGA IO
    output [3:0] VGA_R;
    output [3:0] VGA_G;
    output [3:0] VGA_B;
    output VGA_HS;
    output VGA_VS;

    // ========================================================================
    // 2. 内部信号定义
    // ========================================================================
    wire clk_50;
    wire reset;
    wire KEY4;

    assign clk_50 = CLOCK_50;
    assign reset = ~KEY[0];
    assign KEY4 = ~KEY[3];

    // 时钟与交易信号
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

    // [新增] VGA 内部信号
    wire [9:0] h_cnt;
    wire [9:0] v_cnt;
    wire video_on;

    // ========================================================================
    // 3. 模块实例化
    // ========================================================================

    // --- 基础时钟 ---
    // 1. 分频器: (clk_in, reset, clk_out)
    // 产生 25MHz 时钟供 VGA 使用
    clk_div2 div25(clk_50, reset, clk_25);

    // --- 交易核心逻辑 ---
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

    // --- 音频反馈逻辑 (补全你代码中缺失的部分) ---
    // 8. 触发器: 检测 match_signal 上升沿产生脉冲
    audio_trigger u_trig(CLOCK_50, reset, match_signal, play_pulse);

    // 9. 音调生成器: 产生声音波形
    my_tone u_tone(CLOCK_50, reset, play_pulse, audio_allowed, audio_write, aud_left, aud_right);

    // 10. 芯片配置: 配置 WM8731 芯片
    avconf u_conf(CLOCK_50, reset, I2C_SCLK, I2C_SDAT);

    // 11. 音频控制器: 负责数据传输
    audio_controller #( .AUDIO_DATA_WIDTH(32) ) u_ctrl (
        .CLOCK_50(CLOCK_50), 
        .reset(reset), 
        .clear_audio_out_memory(1'b0), 
        .clear_audio_in_memory(1'b0),
        .write_audio_out(audio_write), 
        .audio_out_allowed(audio_allowed),
        .left_channel_audio_out(aud_left), 
        .right_channel_audio_out(aud_right),
        .AUD_ADCDAT(AUD_ADCDAT), 
        .AUD_DACDAT(AUD_DACDAT), 
        .AUD_BCLK(AUD_BCLK), 
        .AUD_ADCLRCK(AUD_ADCLRCK), 
        .AUD_DACLRCK(AUD_DACLRCK), 
        .I2C_SDAT(I2C_SDAT), 
        .I2C_SCLK(I2C_SCLK), 
        .AUD_XCK(AUD_XCK)
    );

    // --- [新增] VGA 动画显示逻辑 ---
    
    // 12. VGA 控制器: 产生行场同步信号和坐标 (引用你已有的 vga_controller.v)
    vga_controller vga_ctrl_inst (
        .clk_25mhz(clk_25), 
        .reset(reset), 
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt), 
        .hsync(VGA_HS), 
        .vsync(VGA_VS), 
        .video_on(video_on)
    );

    // 13. VGA 走势图显示: 维护价格历史并输出颜色 (引用你需要新建的 vga_trend_display.v)
    vga_trend_display vga_trend_inst (
        .clk(CLOCK_50),          // 用于数据移位
        .reset(reset),
        .video_on(video_on),     // VGA显示有效区
        .h_cnt(h_cnt),           // 当前像素X
        .v_cnt(v_cnt),           // 当前像素Y
        .trade_price(trade_price), // 输入：当前最新成交价
        .match_signal(match_signal), // 输入：触发更新信号
        .spread(spread_now),     // 输入：当前价差
        .R(VGA_R), 
        .G(VGA_G), 
        .B(VGA_B)
    );

endmodule