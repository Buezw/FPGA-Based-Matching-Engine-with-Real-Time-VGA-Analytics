module counter (slow_clk, reset, match_signal, enable_count, trade_count, halt_signal);

    input slow_clk;
    input reset;
    input match_signal;
    input enable_count;
    output reg [7:0] trade_count;
    output reg halt_signal;


always @(posedge slow_clk or posedge reset) begin
    if (reset) begin
        trade_count <= 8'd0;
        halt_signal <= 1'b0;
    end else begin
        if (enable_count && !halt_signal) begin
            if (trade_count == 8'd99) begin
                halt_signal <= 1'b1;   // assert halt
            end else begin
                trade_count <= trade_count + 1'b1;
            end
        end
    end
end

endmodule


