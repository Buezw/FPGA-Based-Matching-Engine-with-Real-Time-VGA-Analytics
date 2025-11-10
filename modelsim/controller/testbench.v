`timescale 1ns / 1ps

module testbench ();

    // ==== 仿真参数 (simulation parameter) ====
    parameter CLOCK_PERIOD = 10; // 100MHz -> 10ns

    // ==== 与你示例一致的外设风格 (same style as your example) ====
    // SW[0]=reset(高有效, active-high reset), SW[1]=match_flag, SW[2]=halt_flag
    reg  [2:0] SW;
    reg  [0:0] KEY;  // KEY[0]=clk (clock)

    // ==== 被测模块输出 (UUT outputs) ====
    wire       enable_count; // 计数使能 (enable_count)
    wire [1:0] state;        // 状态编码 (FSM state)

    // ==== 初始时钟电平 (initial clock level) ====
    initial begin
        KEY[0] <= 1'b0;
    end

    // ==== 时钟发生器 (clock generator) ====
    always @(*) begin : Clock_Generator
        #((CLOCK_PERIOD)/2) KEY[0] <= ~KEY[0];
    end

    // ==== 激励序列 (stimulus) ====
    initial begin
        // 上电：先复位 (assert reset)
        SW[0] <= 1'b1;  // reset
        SW[1] <= 1'b0;  // match_flag
        SW[2] <= 1'b0;  // halt_flag
        #30 SW[0] <= 1'b0;  // 释放复位 (deassert reset)

        // 提供一些 match_flag 脉冲，观察从 IDLE->MATCH
        #40 SW[1] <= 1'b1;  // match on
        #60 SW[1] <= 1'b0;  // match off
        #80 SW[1] <= 1'b1;  // another pulse
        #60 SW[1] <= 1'b0;

        // 触发停机 (HALT)：拉高 halt_flag
        #200 SW[2] <= 1'b1;

        // 再给 match_flag 也不应再使能计数 (enable_count 应保持 0)
        #100 SW[1] <= 1'b1;
        #60  SW[1] <= 1'b0;

        // 结束仿真
        #500 $finish;
    end

    // ==== 例化被测模块 (instantiate UUT) ====
    // 注意：这里用 .halt_flag，对应你的源文件端口名
    // 若你的源码端口名是 .halt（没有 _flag），把下一行改成 .halt(SW[2]) 即可
    controller_fsm U1 (
        .clk          (KEY[0]),
        .reset        (SW[0]),
        .match_flag   (SW[1]),
        .halt_flag    (SW[2]),
        .enable_count (enable_count),
        .state        (state)
    );

    // ==== 打印观测 (monitor) ====
    initial begin
        $display(" time  rst match halt  en  state");
        $monitor("%5t  %b    %b    %b    %b   %0d",
                 $time, SW[0], SW[1], SW[2], enable_count, state);
    end

endmodule
