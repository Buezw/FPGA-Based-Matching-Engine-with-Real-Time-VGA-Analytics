// =====================================================
// Module: Counter
// =====================================================


module counter (clk, reset, match_flag, enable_count, trade_count, halt_flag);
    input  clk;             // system clock
    input  reset;           // async reset
    input  match_flag;      // from Matching Engine
    input  enable_count;    // from FSM Controller
    output [7:0] trade_count; // number of executed trades
    output halt_flag;       // stops system if over threshold

    reg [7:0] trade_count;
    reg       halt_flag;
    parameter MAX_TRADES = 8'd100;  // threshold for halt

    always @(posedge clk or posedge reset) 
    begin
        if (reset) 
        begin
            trade_count <= 8'd0;
            halt_flag   <= 1'b0;
        end
        else 
        begin
            if (enable_count && match_flag && !halt_flag) 
            begin
                trade_count <= trade_count + 1'b1;
            end

            // When the number of trades exceeds threshold, trigger halt
            if (trade_count >= MAX_TRADES)
                halt_flag <= 1'b1;
        end
    end

endmodule
