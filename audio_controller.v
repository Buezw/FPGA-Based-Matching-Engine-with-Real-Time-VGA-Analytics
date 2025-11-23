module Audio_Controller (
    input clk,
    input rst_n,
    input [15:0] left_data,
    input [15:0] right_data,
    output reg AUD_BCLK,
    output reg AUD_DACLRCK,
    output reg AUD_DACDAT
);

    reg [3:0] bit_counter;
    reg [15:0] shift_reg;
    reg [7:0] clk_divider;

    // BCLK Generator: 50MHz / 4 approx 12.5MHz (Simple divider)
    // 为了简化，我们使用一个简单的计数器来生成 BCLK
    // WM8731 在 50MHz XCK 下可以接受较宽范围的 BCLK
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            clk_divider <= 0;
        else 
            clk_divider <= clk_divider + 1;
    end

    // Use bit 2 of divider as BCLK (approx 6MHz)
    wire bclk_internal = clk_divider[2];

    always @(*) AUD_BCLK = bclk_internal;

    // State machine for sending data
    always @(negedge bclk_internal or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            AUD_DACLRCK <= 1;
            AUD_DACDAT <= 0;
            shift_reg <= 0;
        end else begin
            if (bit_counter == 0) begin
                AUD_DACLRCK <= ~AUD_DACLRCK; // Toggle Left/Right
                if (AUD_DACLRCK) // Was High (Left), now Low (Right)
                    shift_reg <= right_data;
                else             // Was Low (Right), now High (Left)
                    shift_reg <= left_data;
            end
            
            AUD_DACDAT <= shift_reg[15];
            shift_reg <= {shift_reg[14:0], 1'b0};
            bit_counter <= bit_counter + 1;
        end
    end
endmodule