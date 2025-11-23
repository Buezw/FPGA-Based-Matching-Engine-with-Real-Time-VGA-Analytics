module avconf (
    input CLOCK_50,
    input reset,
    output FPGA_I2C_SCLK,
    inout  FPGA_I2C_SDAT
);
    reg [23:0] i2c_data;
    reg [3:0]  lut_index;
    reg        start;
    wire       done;
    reg [15:0] mI2C_CLK_DIV;

    I2C_Controller u0 (
        .CLOCK(CLOCK_50),
        .I2C_SCLK(FPGA_I2C_SCLK),
        .I2C_SDAT(FPGA_I2C_SDAT),
        .I2C_DATA(i2c_data),
        .GO(start),
        .END(done),
        .RESET(reset)
    );

    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            lut_index <= 0;
            start <= 0;
            mI2C_CLK_DIV <= 0;
        end else begin
            if (lut_index < 10) begin
                if (mI2C_CLK_DIV < 10000) begin
                    mI2C_CLK_DIV <= mI2C_CLK_DIV + 1;
                end else begin
                    mI2C_CLK_DIV <= 0;
                    start <= 1; // Trigger I2C send
                end
                
                if (done) begin
                    if (start) begin
                       start <= 0; 
                       lut_index <= lut_index + 1;
                    end
                end
            end
        end
    end

    // Configuration Data for WM8731
    always @(*) begin
        case(lut_index)
            // Register Address (7bit) + Data (9bit)
            // Format: {8'h34, 7'hRegAddr, 9'hData}
            // Reset
            0: i2c_data = {8'h34, 7'h0F, 9'h000}; 
            // Left Line In (Unmute)
            1: i2c_data = {8'h34, 7'h00, 9'h017}; 
            // Right Line In (Unmute)
            2: i2c_data = {8'h34, 7'h01, 9'h017}; 
            // Left Headphone Out (Vol)
            3: i2c_data = {8'h34, 7'h02, 9'h07F}; 
            // Right Headphone Out (Vol)
            4: i2c_data = {8'h34, 7'h03, 9'h07F}; 
            // Analog Audio Path (DAC Select)
            5: i2c_data = {8'h34, 7'h04, 9'h012}; 
            // Digital Audio Path (No De-emphasis)
            6: i2c_data = {8'h34, 7'h05, 9'h000}; 
            // Power Down Control (All On)
            7: i2c_data = {8'h34, 7'h06, 9'h000}; 
            // Digital Audio Interface Format (I2S, 16bit, Slave Mode)
            8: i2c_data = {8'h34, 7'h07, 9'h002}; 
            // Sampling Control (Normal, 48k approx)
            9: i2c_data = {8'h34, 7'h08, 9'h000}; 
            // Active Control (Activate)
            10: i2c_data = {8'h34, 7'h09, 9'h001}; 
            default: i2c_data = {8'h34, 7'h00, 9'h000};
        endcase
    end
endmodule