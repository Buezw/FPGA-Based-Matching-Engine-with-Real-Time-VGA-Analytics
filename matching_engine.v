// =====================================================
// Module: matching_engine_8
// =====================================================

module matching_engine_8 (
    input  clk,
    input  reset,
    input  [7:0] buy_price,
    input  [7:0] sell_price,
    output reg   match_flag,
    output reg [7:0] trade_price,
    output reg [7:0] best_bid,
    output reg [7:0] best_ask
);

    // -------------------------------------------------
    // 8-entry FIFO queues for buy and sell
    // -------------------------------------------------
    reg [7:0] buy_q0, buy_q1, buy_q2, buy_q3, buy_q4, buy_q5, buy_q6, buy_q7;
    reg [7:0] sell_q0, sell_q1, sell_q2, sell_q3, sell_q4, sell_q5, sell_q6, sell_q7;

    // -------------------------------------------------
    // Queue update (shift right each clock tick)
    // -------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            buy_q0  <= 8'd0;
            buy_q1  <= 8'd0;
            buy_q2  <= 8'd0;
            buy_q3  <= 8'd0;
            buy_q4  <= 8'd0;
            buy_q5  <= 8'd0;
            buy_q6  <= 8'd0;
            buy_q7  <= 8'd0;

            sell_q0 <= 8'hFF;
            sell_q1 <= 8'hFF;
            sell_q2 <= 8'hFF;
            sell_q3 <= 8'hFF;
            sell_q4 <= 8'hFF;
            sell_q5 <= 8'hFF;
            sell_q6 <= 8'hFF;
            sell_q7 <= 8'hFF;
        end else begin
            // Shift older buy orders
            buy_q7 <= buy_q6;
            buy_q6 <= buy_q5;
            buy_q5 <= buy_q4;
            buy_q4 <= buy_q3;
            buy_q3 <= buy_q2;
            buy_q2 <= buy_q1;
            buy_q1 <= buy_q0;
            buy_q0 <= buy_price;

            // Shift older sell orders
            sell_q7 <= sell_q6;
            sell_q6 <= sell_q5;
            sell_q5 <= sell_q4;
            sell_q4 <= sell_q3;
            sell_q3 <= sell_q2;
            sell_q2 <= sell_q1;
            sell_q1 <= sell_q0;
            sell_q0 <= sell_price;
        end
    end


    // -------------------------------------------------
    // Find best bid (max) and best ask (min)
    // -------------------------------------------------
    always @(*) begin
        best_bid = buy_q0;
        if (buy_q1 > best_bid) best_bid = buy_q1;
        if (buy_q2 > best_bid) best_bid = buy_q2;
        if (buy_q3 > best_bid) best_bid = buy_q3;
        if (buy_q4 > best_bid) best_bid = buy_q4;
        if (buy_q5 > best_bid) best_bid = buy_q5;
        if (buy_q6 > best_bid) best_bid = buy_q6;
        if (buy_q7 > best_bid) best_bid = buy_q7;

        best_ask = sell_q0;
        if (sell_q1 < best_ask) best_ask = sell_q1;
        if (sell_q2 < best_ask) best_ask = sell_q2;
        if (sell_q3 < best_ask) best_ask = sell_q3;
        if (sell_q4 < best_ask) best_ask = sell_q4;
        if (sell_q5 < best_ask) best_ask = sell_q5;
        if (sell_q6 < best_ask) best_ask = sell_q6;
        if (sell_q7 < best_ask) best_ask = sell_q7;
    end

    // -------------------------------------------------
    // Matching condition and trade price
    // -------------------------------------------------
    always @(*) begin
        if (best_bid >= best_ask && best_bid != 0 && best_ask != 8'hFF)
            match_flag = 1'b1;
        else
            match_flag = 1'b0;

        trade_price = (best_bid + best_ask) >> 1; // midpoint
    end
endmodule
