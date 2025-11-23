// Module: Counter (Fixed for Level-Triggered Counting)

module counter (clk, reset, match_signal, enable_count, trade_count, halt_signal);

    input clk;
    input reset;
    input match_signal;
    input enable_count;
    output [7:0] trade_count;
    output halt_signal;

    reg [7:0] trade_count;
    reg halt_signal;


    parameter MAX_TRADES = 8'd99;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            trade_count <= 8'd0;
            halt_signal <= 1'b0;
        end 
        else begin

            if (enable_count && match_signal && !halt_signal) begin
                trade_count <= trade_count + 8'd1;
            end

            if (trade_count >= MAX_TRADES) begin
                halt_signal <= 1'b1;
            end
        end
    end

endmodule