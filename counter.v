// Module: Counter

module counter (clk, reset, match_signal, enable_count, trade_count, halt_signal);

    input clk;
    input reset;
    input match_signal;
    input enable_count;
    output [7:0] trade_count;
    output halt_signal;

    reg [7:0] trade_count;
    reg halt_signal;

    reg enable_d;
    wire enable_edge;

    always @(posedge clk or posedge reset) begin
        if (reset)
            enable_d <= 1'b0;
        else
            enable_d <= enable_count;
    end


    assign enable_edge = enable_count & ~enable_d; 

    parameter MAX_TRADES = 8'd99; 

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            trade_count <= 8'd0;
            halt_signal <= 1'b0;
        end 
        else begin

            if (enable_edge && !halt_signal)
                trade_count <= trade_count + 8'd1;

            if (trade_count >= MAX_TRADES)
                halt_signal <= 1'b1;
        end
    end

endmodule


