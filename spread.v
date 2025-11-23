// Module: Spread Calculator


module spread (clk, reset, match_signal, enable_count, buy_price, sell_price, spread);

    input clk;              
    input reset;            
    input match_signal;        
    input enable_count;     
    input [7:0] buy_price;
    input [7:0] sell_price; 
    
    output [7:0] spread;    
    reg [7:0] spread;       
    always @(posedge clk or posedge reset) begin
        if (reset)
            spread <= 8'd0;
        else begin

            if (sell_price == 8'hFF || buy_price == 8'd0) begin
                spread <= 8'd0;
            end

            else if (buy_price >= sell_price) begin
                spread <= buy_price - sell_price; 

            end
            else begin

                spread <= sell_price - buy_price; 
            end
        end
    end

endmodule
