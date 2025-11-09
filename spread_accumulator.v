// =====================================================
// Module: Spread Accumulator
// =====================================================

module spread_accumulator (clk, reset, match_flag, enable_count, buy_price, sell_price, spread_sum);

    input clk;               // system clock
    input reset;             // async reset
    input match_flag;        // from Matching Engine
    input enable_count;      // from FSM Controller
    input [7:0] buy_price;   // from Order Generator
    input [7:0] sell_price;  // from Order Generator
    
    output [7:0] spread_sum;// accumulated spread total

    reg [7:0] spread_sum;   // must be reg for sequential always

    // -------------------------------------------------
    // Sequential logic: accumulate when match happens
    // -------------------------------------------------
    always @(posedge clk or posedge reset) 
    begin
        if (reset) 
        begin
            spread_sum <= 16'd0;
        end
        else if (enable_count && match_flag) 
        begin
            // accumulate (buy - sell)
            spread_sum <= (buy_price - sell_price);
        end
    end

endmodule
