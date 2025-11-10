`timescale 1ns / 1ps

module testbench ();

    // ==== 仿真参数 (simulation parameter) ====
    parameter CLOCK_PERIOD = 10; // 100MHz -> 10ns

    // ==== 与你示例一致的 KEY/SW 风格 (same style as your example) ====
    // KEY[0]=clk
    // SW[0]=reset(高有效, active-high)
    // SW[1]=enable_count
    // SW[2]=match_siganl   // 按 DUT 的实际拼写
    reg  [2:0] SW;
    reg  [0:0] KEY;

    // ==== 输入价格 (price inputs) ====
    reg  [7:0] buy_price;
    reg  [7:0] sell_price;

    // ==== 输出 (output) ====
    wire [7:0] spread;

    // ==== 初始时钟电平 (initial clock level) ====
    initial KEY[0] <= 1'b0;

    // ==== 时钟发生器 (clock generator) ====
    always @(*) begin : Clock_Generator
        #((CLOCK_PERIOD)/2) KEY[0] <= ~KEY[0];
    end

    // ==== 例化被测模块 (instantiate UUT) ====
    spread U1 (
        .clk          (KEY[0]),
        .reset        (SW[0]),
        .match_siganl (SW[2]),
        .enable_count (SW[1]),
        .buy_price    (buy_price),
        .sell_price   (sell_price),
        .spread       (spread)
    );

    // ==== 激励序列 (stimulus) ====
    // 目标：仅当 enable_count=1 且 match_siganl=1 时，spread 更新为 buy - sell
    initial begin
        // 上电复位
        SW <= 3'b000;
        SW[0] <= 1'b1;             // reset=1
        buy_price  <= 8'd0;
        sell_price <= 8'd0;

        // 保持复位 5 个时钟
        repeat (5) @(posedge KEY[0]);
        SW[0] <= 1'b0;             // 释放复位

        // A) 未使能 -> 不更新
        SW[1] <= 1'b0; SW[2] <= 1'b1; // enable=0, match=1
        send_price(8'd80, 8'd70, 3);  // 期望 spread 仍保持复位值0

        // B) 仅使能，无撮合 -> 不更新
        SW[1] <= 1'b1; SW[2] <= 1'b0; // enable=1, match=0
        send_price(8'd75, 8'd74, 3);  // 期望不更新

        // C) 满足条件（enable=1 & match=1）-> 更新
        SW[1] <= 1'b1; SW[2] <= 1'b1;
        send_price(8'd82, 8'd78, 2);  // 期望 spread=4
        send_price(8'd70, 8'd65, 2);  // 期望 spread=5

        // D) 观察 buy<sell 情况（无符号减法会回绕 wrap-around）
        send_price(8'd60, 8'd72, 2);  // 60-72=8'hF4=244 (unsigned)

        // 再来一组
        send_price(8'd81, 8'd55, 3);  // 期望 26

        // 收尾
        repeat (10) @(posedge KEY[0]);
        $finish;
    end

    // ==== 打印观测 (monitor/printf) ====
    initial begin
        $display(" time  rst en match | buy  sell | spread");
        forever begin
            @(posedge KEY[0]);
            $display("%5t  %b   %b   %b   | %3d  %3d | %3d",
                     $time, SW[0], SW[1], SW[2],
                     buy_price, sell_price, spread);
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
