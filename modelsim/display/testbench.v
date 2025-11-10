`timescale 1ns / 1ps

module testbench ();

    // ==== 仿真参数 (simulation parameter) ====
    parameter CLOCK_PERIOD = 10; // 100MHz -> 10ns

    // ==== 与你示例一致的外设风格 (same style as your example) ====
    // SW[0]=match_signal, SW[1]=halt_signal, SW[3:2]=state[1:0]
    reg  [3:0] SW;
    reg  [0:0] KEY;  // KEY[0]=clk (仅为保持风格，display_hex 不用时钟)

    // ==== 显示相关输入 (display inputs) ====
    reg  [7:0] buy_price;
    reg  [7:0] sell_price;
    reg  [7:0] spread_now;
    reg  [7:0] trade_count;

    // ==== 输出到数码管与LED (HEX & LEDR outputs) ====
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [9:0] LEDR;

    // ==== 初始时钟电平并产生时钟 (keep your style) ====
    initial KEY[0] <= 1'b0;
    always @(*) begin : Clock_Generator
        #((CLOCK_PERIOD)/2) KEY[0] <= ~KEY[0];
    end

    // ==== 激励序列 (stimulus) ====
    initial begin
        // 初值
        SW      <= 4'b0000;  // match=0, halt=0, state=00
        buy_price  <= 8'd50;
        sell_price <= 8'd60;
        spread_now <= 8'd10;
        trade_count<= 8'd0;

        // 逐步改变价格与状态，观察 HEX/LEDR 显示
        #30  buy_price  <= 8'd75;  sell_price <= 8'd70;  spread_now <= 8'd5;   // 买>卖
        #30  buy_price  <= 8'd66;  sell_price <= 8'd80;  spread_now <= 8'd14;  // 卖>买
        #30  SW[0] <= 1'b1;                     // match_signal=1
        #40  SW[0] <= 1'b0;                     // match_signal=0
        #40  SW[3:2] <= 2'b01;                  // state=01（例如 MATCH）
        #40  SW[3:2] <= 2'b10;                  // state=10
        #40  SW[1]   <= 1'b1;                   // halt_signal=1（停机）

        // 累加交易计数以驱动 LEDR[9:4]
        repeat (16) begin
            #20 trade_count <= trade_count + 1;
        end

        // 再改几组价格看数码管变化
        #60  buy_price <= 8'd81; sell_price <= 8'd55; spread_now <= 8'd26;
        #60  buy_price <= 8'd52; sell_price <= 8'd86; spread_now <= 8'd34;

        $finish;
    end

    // ==== 例化被测模块 (instantiate UUT) ====
    // 模块名：display_hex
    display_hex U1 (
        .buy_price     (buy_price),
        .sell_price    (sell_price),
        .spread_now    (spread_now),
        .trade_count   (trade_count),
        .state         (SW[3:2]),
        .halt_signal   (SW[1]),
        .match_signal  (SW[0]),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
        .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
        .LEDR(LEDR)
    );

    // ==== 打印观测 (monitor) ====
    initial begin
        $display(" time  match halt state  buy sell sprd  tcount");
        $monitor("%5t   %b     %b   %02b    %3d  %3d  %3d   %3d",
                 $time, SW[0], SW[1], SW[3:2], buy_price, sell_price, spread_now, trade_count);
    end

endmodule
