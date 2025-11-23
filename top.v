// ============================================================================
// 文件名: top.v (修复编译错误版)
// ============================================================================

module top (
    // --- 基础输入 ---
    input CLOCK_50,
    input [3:0] KEY,
    
    // --- 数码管与LED输出 ---
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR,

    // --- 音频端口 ---
    inout  I2C_SDAT,
    output I2C_SCLK,
    output AUD_XCK,      // 音频主时钟
    output AUD_BCLK,
    output AUD_ADCLRCK,
    output AUD_DACLRCK,
    input  AUD_ADCDAT,
    output AUD_DACDAT,

    // --- VGA端口 (8位宽 + 控制信号) ---
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_CLK,      // 必须：像素时钟
    output VGA_BLANK_N,  // 必须：消隐信号
    output VGA_SYNC_N    // 必须：同步信号
);

    // ========================================================================
    // 内部信号定义
    // ========================================================================
    wire reset = ~KEY[0];
    wire clk_25;
    wire clk_50;
    wire slow_clk;
    assign clk_50 = CLOCK_50;

    // 交易信号
    wire [7:0] buy_price, sell_price, trade_price, spread_now, trade_count, best_bid, best_ask;
    wire [1:0] state;
    wire match_signal, halt_signal, enable_count;

    // 音频信号
    wire play_pulse, audio_allowed, audio_write;
    wire [31:0] aud_left, aud_right;

    // VGA 信号
    wire [9:0] h_cnt, v_cnt;
    wire video_on;
    wire [3:0] vga_r_4bit, vga_g_4bit, vga_b_4bit; 

    // ========================================================================
    // 关键硬件驱动逻辑
    // ========================================================================
    
    // [VGA] 驱动芯片控制信号
    assign VGA_BLANK_N = 1'b1;   
    assign VGA_SYNC_N  = 1'b0;   
    assign VGA_CLK     = clk_25; 

    // [VGA] 颜色扩展 (4位 -> 8位)
    assign VGA_R = {vga_r_4bit, 4'b0000};
    assign VGA_G = {vga_g_4bit, 4'b0000};
    assign VGA_B = {vga_b_4bit, 4'b0000};

    // ========================================================================
    // 模块实例化
    // ========================================================================

    // 1. 分频器
    clk_div2 div25(.clk_in(CLOCK_50), .reset(reset), .clk_out(clk_25));

    // 2. 交易核心
order_generator generator(clk_50, reset, buy_price, sell_price, KEY, slow_clk);

    matching_engine engine(clk_50, reset, buy_price, sell_price, match_signal, trade_price, best_bid, best_ask);

    controller_fsm controller(clk_50, reset, match_signal, halt_signal, state, enable_count);

    counter trade_counter(slow_clk, reset, match_signal, enable_count, trade_count, halt_signal);

    spread spread_calc(clk_50, reset, match_signal, enable_count, buy_price, sell_price, spread_now);

    display_hex display_unit(buy_price, sell_price, spread_now, trade_count, state, halt_signal, match_signal,
                             HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

    // 3. 音频逻辑
    audio_trigger u_trig(CLOCK_50, reset, match_signal, play_pulse);

    // [修复点 1] 使用 defparam 方式修改参数，兼容性更好
    my_tone u_tone (
        .clk(CLOCK_50), 
        .reset(reset), 
        .play_trigger(play_pulse), 
        .audio_out_allowed(audio_allowed), 
        .write_out(audio_write), 
        .left_out(aud_left), 
        .right_out(aud_right)
    );
    // 修改为 1kHz 频率, 200ms 时长
    defparam u_tone.HALF_PERIOD = 25000;
    defparam u_tone.DURATION = 10000000;

    avconf u_conf(CLOCK_50, reset, I2C_SCLK, I2C_SDAT);
    
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

    // 4. VGA 逻辑
    vga_controller vga_ctrl_inst (
        .clk_25mhz(clk_25), 
        .reset(reset), 
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt), 
        .hsync(VGA_HS), 
        .vsync(VGA_VS), 
        .video_on(video_on)
    );

    // [修复点 2] 补全 .trade_count 端口连接
    vga_trend_display vga_trend_inst (
        .clk(CLOCK_50),          
        .reset(reset),
        .video_on(video_on),     
        .h_cnt(h_cnt),           
        .v_cnt(v_cnt),           
        .trade_price(trade_price), 
        .match_signal(match_signal), 
        .spread(spread_now),     
        .trade_count(trade_count), // 之前漏了这行
        .R(vga_r_4bit), 
        .G(vga_g_4bit), 
        .B(vga_b_4bit)
    );


endmodule

