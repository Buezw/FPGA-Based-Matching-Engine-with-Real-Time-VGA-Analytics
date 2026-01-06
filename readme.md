# FPGA-Based Matching Engine with Real-Time VGA Analytics

An high-performance hardware implementation of a financial matching engine designed in Verilog. This system simulates a high-frequency trading (HFT) environment, processes orders through a sliding window matching algorithm, and provides real-time data visualization via VGA.



## 1. Project Overview
The system generates a stream of pseudo-random market prices, identifies trading opportunities based on a 8-depth order book window, and visualizes the results.

### Key Features:
* **Hardware Order Generation:** Uses dual 16-bit Linear Feedback Shift Registers (LFSR) with frequency division for stable price simulation.
* **Best-Bid-Best-Offer (BBO) Logic:** Real-time calculation of $max(Buy\_Window)$ and $min(Sell\_Window)$.
* **VGA Analytics Suite:** 640x480 @ 60Hz resolution display featuring:
    * **Price Trend Charts:** Real-time scrolling line graphs for Buy and Sell prices.
    * **Dynamic Spread Monitor:** Visual representation of the gap between prices.
    * **Trade Volume Tracking:** Progress bar and numerical count for completed matches.
* **State Machine Control:** Robust FSM managing `IDLE`, `MATCH`, and `HALT` (triggered at 100 trades).

---

## 2. System Architecture

### Modular Breakdown:
1.  **`order_generator.v`**: Generates 8-bit prices (Buy: 50-81, Sell: 55-86).
2.  **`matching_engine_8.v`**: 8-stage shift register window. Computes `match_flag` when $BestBid \ge BestAsk$.
3.  **`controller_fsm.v`**: Oversees system states and stops execution when `MAX_TRADES` is reached.
4.  **`vga_visualizer.v`**: The graphics engine. Maps price data to screen coordinates and manages the frame buffer for the line chart.
5.  **`display_7seg.v`**: Drives HEX displays for immediate local monitoring.



---

## 3. VGA Visualization Logic (Core Snippet)

The visualization module converts price history into a pixel-map. Below is the simplified logic for rendering the trend lines:

```verilog
// Mapping Price to Y-Coordinate (Vertical Inversion)
// Screen is 480 pixels high; Price range is mapped to a 200-pixel vertical band.
wire [8:0] plot_y_buy  = 300 - (history_buffer_buy[x_pos] << 1);
wire [8:0] plot_y_sell = 300 - (history_buffer_sell[x_pos] << 1);

always @(*) begin
    if (!video_on) 
        {vga_r, vga_g, vga_b} = 12'h000;
    else begin
        // Default Background
        {vga_r, vga_g, vga_b} = 12'h111; 
        
        // Render Buy Price Line (Blue)
        if (y_pos == plot_y_buy)
            {vga_r, vga_g, vga_b} = 12'h05F;
            
        // Render Sell Price Line (Red)
        if (y_pos == plot_y_sell)
            {vga_r, vga_g, vga_b} = 12'hF22;
            
        // Render Spread Indicator
        if (x_pos > 600 && y_pos < (480 - current_spread))
            {vga_r, vga_g, vga_b} = 12'hFF0; // Yellow bar
    end
end
