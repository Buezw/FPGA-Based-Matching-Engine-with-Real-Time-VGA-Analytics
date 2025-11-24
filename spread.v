module spread (clk, reset, match_signal, enable_count, buy_price, sell_price, spread_now);

    input clk;              
    input reset;            
    input match_signal;        
    input enable_count;
    input [7:0] buy_price;
    input [7:0] sell_price; 
    
    output [7:0] spread_now;    
    reg [7:0] spread;

    wire [7:0] calculated_spread;

    always @* begin
        if (sell_price == 8'hFF || buy_price == 8'd0) begin
            calculated_spread = 8'd0;
        end 
        else if (buy_price >= sell_price) 
        begin
            calculated_spread = buy_price - sell_price;
        end 
        else begin
            calculated_spread = sell_price - buy_price;
        end
    end

    always @(posedge clk or posedge reset) 
    begin
        if (reset)
            spread <= 8'd0;
        // enable_count && match_signal
        else if (match_signal && enable_count) begin
            spread <= calculated_spread;
        end else begin
            spread <= 8'd88;
        end
    end

    

    assign spread_now = spread;

endmodule
