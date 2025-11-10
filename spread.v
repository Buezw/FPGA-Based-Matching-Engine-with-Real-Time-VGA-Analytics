// =====================================================
// Module: Spread Calculator
// =====================================================

module spread (clk, reset, match_siganl, enable_count, buy_price, sell_price, spread);

    input clk;              
    input reset;            
    input match_siganl;        
    input enable_count;     
    input [7:0] buy_price;
    input [7:0] sell_price; 
    
    output [7:0] spread;    
    reg [7:0] spread;       
    always @(posedge clk or posedge reset) 
    begin
        if (reset)
            spread <= 8'd0;
        else if (enable_count && match_siganl) 
        begin
            if (buy_price > sell_price)
            begin
            spread <= buy_price - sell_price; 
            end
            else if (sell_price > buy_price)
            begin
            spread <= sell_price - buy_price;
            end
            else
            begin
            spread <= 8'd0;
            end
        end
    end

endmodule
