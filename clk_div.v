// =====================================================
// Module: clk_div2
// Function: Divide input clock by 2 (e.g. 50 MHz → 25 MHz)
// =====================================================

module clk_div2 (clk_in, reset, clk_out);

    input clk_in;     // 输入时钟，如板载50MHz
    input reset;      // 异步复位，低电平有效
    output clk_out;   // 输出时钟，为输入频率的一半

    reg clk_out

    always @(posedge clk_in or posedge reset)
    begin
        if (reset)
            clk_out <= 1'b0;
        else
            clk_out <= ~clk_out;   // 每个上升沿翻转一次
    end

endmodule
