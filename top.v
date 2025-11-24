module top (
    input CLOCK_50,
    input [3:0] KEY,
    
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
    output [9:0] LEDR,

	//vga
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output VGA_HS,
    output VGA_VS,
    output VGA_CLK,      //clk
    output VGA_BLANK_N,  //disappear
    output VGA_SYNC_N    //sync
);

    wire reset = ~KEY[0];
    wire clk_25;
	 wire clk_50;
    wire slow_clk;
    assign clk_50 = CLOCK_50;

    wire [7:0] buy_price, sell_price, trade_price, spread_now, trade_count, best_bid, best_ask;
    wire [1:0] state;
    wire match_signal, halt_signal, enable_count;

    // VGA
    wire [9:0] h_cnt, v_cnt;
    wire video_on;
    wire [3:0] vga_r_4bit, vga_g_4bit, vga_b_4bit; 

    assign VGA_BLANK_N = 1'b1;   
    assign VGA_SYNC_N  = 1'b0;   
    assign VGA_CLK     = clk_25; 

    assign VGA_R = {vga_r_4bit, 4'b0000};
    assign VGA_G = {vga_g_4bit, 4'b0000};
    assign VGA_B = {vga_b_4bit, 4'b0000};

    clk_div2 div25(.clk_in(CLOCK_50), .reset(reset), .clk_out(clk_25));

    order_generator generator(clk_50, reset, buy_price, sell_price, KEY, slow_clk);
	
    matching_engine engine(clk_50, reset, buy_price, sell_price, match_signal, trade_price, best_bid, best_ask);

    controller_fsm controller(clk_50, reset, match_signal, halt_signal, state, enable_count);

    counter trade_counter(slow_clk, reset, match_signal, enable_count, trade_count, halt_signal);

    spread spread_calc(clk_50, reset, match_signal, enable_count, buy_price, sell_price, spread_now);

    display_hex display_unit(buy_price, sell_price, spread_now, trade_count, state, halt_signal, match_signal,
                             HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

    vga_controller vga_ctrl_inst (
        .clk_25mhz(clk_25), 
        .reset(reset), 
        .h_cnt(h_cnt), 
        .v_cnt(v_cnt), 
        .hsync(VGA_HS), 
        .vsync(VGA_VS), 
        .video_on(video_on)
    );

    vga_trend_display vga_trend_inst (
        .clk(CLOCK_50),          
        .reset(reset),
        .video_on(video_on),     
        .h_cnt(h_cnt),           
        .v_cnt(v_cnt),           
        .trade_price(trade_price), 
        .match_signal(match_signal), 
        .spread(spread_now),     
        .trade_count(trade_count), 
        .R(vga_r_4bit), 
        .G(vga_g_4bit), 
        .B(vga_b_4bit)
    );
endmodule

