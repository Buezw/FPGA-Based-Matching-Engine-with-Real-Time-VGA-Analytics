module vga_trend_display(
    input clk,
    input reset,
    input video_on,
    input [9:0] h_cnt, //(0-639)
    input [9:0] v_cnt, //(0-479)
    input [7:0] trade_price,
    input match_signal,
    input [7:0] spread, 
    input [7:0] trade_count,
    output [3:0] R, G, B
);

    reg [7:0] price_history [0:639];
    integer i;
    reg match_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            match_prev <= 0;
            for (i = 0; i < 640; i = i + 1) price_history[i] <= 8'd0;
        end
        else begin
            match_prev <= match_signal;
            // history shift left
            if (match_signal && !match_prev) begin
                for (i = 0; i < 639; i = i + 1) begin
                    price_history[i] <= price_history[i+1];
                end
                //in
                price_history[639] <= trade_price; 
            end
        end
    end

    // Red Spread line
    // X < 20
    // h = spread * 4
    wire [10:0] spread_height = {3'b0, spread} << 2; 
    wire is_spread_bar;
    assign is_spread_bar = (h_cnt < 20) && (v_cnt >= (11'd480 - spread_height));

    // Blue trade count bot 10, Y >= 470
    // h = trade_count * 6 (100 * 6 = 600)
    wire [9:0] trade_bar_width = {2'b0, trade_count} * 6;
    wire is_trade_bar;
    assign is_trade_bar = (v_cnt >= 470) && (h_cnt < trade_bar_width);

    // scale
    wire is_scale;
    // (X=20~25) 50 pixel横杠
    wire is_spread_tick = (h_cnt >= 20 && h_cnt < 25) && (v_cnt % 50 == 0);
    // (X > 40) 50 pixel水平虚线
    wire is_price_grid = (h_cnt > 40) && (v_cnt % 50 == 0) && (h_cnt[2] == 1'b0);
    
    assign is_scale = is_spread_tick || is_price_grid;

    // green trade line
    wire is_trend_line;
    wire [7:0] current_x_price;
    wire [10:0] y_pos; 

    assign current_x_price = price_history[h_cnt]; 
    
    // Y = 800 - (price * 8)
    assign y_pos = 11'd800 - ({3'b0, current_x_price} << 3); 

    // 7 pixel
    assign is_trend_line = (h_cnt > 40 && v_cnt < 470) && 
                           (v_cnt >= y_pos - 3 && v_cnt <= y_pos + 3);

    //color
    assign R = !video_on ? 4'h0 : 
               (is_scale      ? 4'h7 :  // 灰
                is_spread_bar ? 4'hF :  // 红
                4'h0);

    assign G = !video_on ? 4'h0 : 
               (is_scale      ? 4'h7 :  // 灰
                is_trend_line ? 4'hF :  // 绿
                4'h0);

    assign B = !video_on ? 4'h0 : 
               (is_trade_bar  ? 4'hF :  // 蓝
                is_scale      ? 4'h7 :  // 灰
                4'h0);


endmodule
