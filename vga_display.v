// =====================================================
// Module: VGA Display (old Verilog style)
// Function: Visualize trading data on VGA screen
// =====================================================

module vga_display(clk_25mhz, video_on, h_cnt, v_cnt,
                   buy_price, sell_price, trade_count, spread,
                   halt_signal, R, G, B);

    input clk_25mhz;
    input video_on;
    input [9:0] h_cnt;
    input [9:0] v_cnt;
    input [7:0] buy_price;
    input [7:0] sell_price;
    input [7:0] trade_count;
    input [7:0] spread;
    input halt_signal;
    output [3:0] R;
    output [3:0] G;
    output [3:0] B;

    // map prices to vertical positions
    wire [9:0] y_buy;
    wire [9:0] y_sell;
    assign y_buy  = 10'd480 - {buy_price, 1'b0};
    assign y_sell = 10'd480 - {sell_price, 1'b0};


    // detect if current pixel near line
    wire buy_line;
    wire sell_line;
    assign buy_line  = (v_cnt > y_buy-1  && v_cnt < y_buy+1);
    assign sell_line = (v_cnt > y_sell-1 && v_cnt < y_sell+1);

    // bottom bars
    wire spread_bar;
    wire progress_bar;
    assign spread_bar   = (v_cnt > 460) && (h_cnt < (spread * 5));
    assign progress_bar = (v_cnt > 470) && (h_cnt < (trade_count * 6));

    wire in_display;
    assign in_display = video_on && !halt_signal;

    assign R = (in_display && (sell_line || spread_bar)) ? 4'hF :
               (halt_signal ? 4'h8 : 4'h0);

    assign G = (in_display && (buy_line || progress_bar)) ? 4'hF :
               (halt_signal ? 4'h8 : 4'h0);

    assign B = (halt_signal ? 4'hA : 4'h0);

endmodule
