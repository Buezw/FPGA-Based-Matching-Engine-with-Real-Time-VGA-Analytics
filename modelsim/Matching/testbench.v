`timescale 1ns / 1ps

module testbench ();

    // ==== 仿真参数 (simulation parameter) ====
    parameter CLOCK_PERIOD = 10; // 100MHz -> 10ns

    // ==== 与你示例一致的外设风格 (KEY/SW style) ====
    // KEY[0] 作为时钟 (clock)
    // SW[0] 作为高有效复位 (active-high reset)
    reg  [0:0] KEY;
    reg  [0:0] SW;

    // ==== 输入价格流 (input price streams) ====
    reg  [7:0] buy_price;    // 买价 (buy price)
    reg  [7:0] sell_price;   // 卖价 (sell price)

    // ==== 输出观测 (observed outputs) ====
    wire [7:0] best_bid;     // 最佳买 (best bid)
    wire [7:0] best_ask;     // 最佳卖 (best ask)
    wire       match_siganl; // 撮合标志 (match flag) —— 按 DUT 的实际端口名
    wire [7:0] trade_price;  // 成交价 (trade price)

    // ==== 初始时钟电平 ====
    initial KEY[0] <= 1'b0;

    // ==== 时钟发生器 (clock generator) ====
    always @(*) begin : Clock_Generator
        #((CLOCK_PERIOD)/2) KEY[0] <= ~KEY[0];
    end

    // ==== 例化被测模块 (instantiate UUT) ====
    matching_engine U1 (
        .clk         (KEY[0]),
        .reset       (SW[0]),
        .buy_price   (buy_price),
        .sell_price  (sell_price),
        .best_bid    (best_bid),
        .best_ask    (best_ask),
        .match_siganl(match_siganl),  // << 修正端口名
        .trade_price (trade_price)
    );

    // ==== 激励序列 (stimulus) ====
    // A: 先填满窗口且 buy<sell 不成交；B: 让 buy>=sell 产生成交；C: 交替极值，验证滑窗更新
    initial begin
        // 上电复位
        SW[0]      <= 1'b1;
        buy_price  <= 8'd0;
        sell_price <= 8'd0;

        // 保持复位 5 个时钟
        repeat (5) @(posedge KEY[0]);
        SW[0] <= 1'b0;

        // -------- A：不成交（buy<sell），填充窗口 --------
        send_price(8'd60, 8'd90, 1);
        send_price(8'd62, 8'd88, 1);
        send_price(8'd64, 8'd86, 1);
        send_price(8'd66, 8'd84, 1);
        send_price(8'd68, 8'd82, 1);
        send_price(8'd70, 8'd80, 1);
        send_price(8'd72, 8'd78, 1);
        send_price(8'd74, 8'd76, 2); // 额外一拍稳定

        // -------- B：成交（buy>=sell）--------
        send_price(8'd80, 8'd78, 4);
        send_price(8'd82, 8'd75, 4);

        // -------- C：改变极值测试 best_* 的滑窗更新 --------
        send_price(8'd85, 8'd60, 4);
        send_price(8'd55, 8'd85, 4);

        // 收尾
        repeat (20) @(posedge KEY[0]);
        $finish;
    end

    // ==== 打印观测 (monitor) ====
    initial begin
        $display(" time  rst   buy  sell | best_bid best_ask | match trade");
        forever begin
            @(posedge KEY[0]);
            $display("%5t  %b   %3d  %3d |   %3d      %3d  |   %b     %3d",
                     $time, SW[0], buy_price, sell_price,
                     best_bid, best_ask, match_siganl, trade_price);
        end
    end

    // ==== 发送价格任务 (task) ====
    task send_price(input [7:0] b, input [7:0] s, input integer n_cycles);
        integer i;
        begin
            buy_price  <= b;
            sell_price <= s;
            for (i = 0; i < n_cycles; i = i + 1) begin
                @(posedge KEY[0]);
            end
        end
    endtask

endmodule
