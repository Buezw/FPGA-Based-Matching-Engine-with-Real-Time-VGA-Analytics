// =====================================================
// Module: clk_div2
// Function: Divide input clock by 2 (e.g. 50 MHz → 25 MHz)
// =====================================================

module clk_div2 (clk_in, reset, clk_out);

    input clk_in;   
    input reset;      
    output clk_out;  

    reg clk_out

    always @(posedge clk_in or posedge reset)
    begin
        if (reset)
            clk_out <= 1'b0;
        else
            clk_out <= ~clk_out;   // 每个上升沿翻转一次
    end

endmodule
