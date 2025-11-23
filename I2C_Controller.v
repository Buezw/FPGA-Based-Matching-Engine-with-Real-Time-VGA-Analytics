module I2C_Controller (
    input CLOCK,
    output I2C_SCLK,
    inout I2C_SDAT,
    input [23:0] I2C_DATA,
    input GO,
    input RESET,
    output reg END
);

    reg [6:0] SD_COUNTER;
    reg SDO;
    reg SCLK;
    
    wire I2C_BIT = I2C_DATA[23-SD_COUNTER];

    assign I2C_SCLK = SCLK | (((SD_COUNTER >= 4) & (SD_COUNTER <= 30)) ? ~CLOCK : 0);
    assign I2C_SDAT = SDO ? 1'bz : 1'b0;

    always @(negedge CLOCK or posedge RESET) begin
        if (RESET) begin
            SCLK <= 1;
            SDO <= 1;
            SD_COUNTER <= 0;
            END <= 1;
        end else begin
            if (GO) begin
                END <= 0;
                if (SD_COUNTER < 41) begin
                    SD_COUNTER <= SD_COUNTER + 1;
                    
                    case(SD_COUNTER)
                        0:  begin SDO <= 1; SCLK <= 1; end // Start condition setup
                        1:  begin SDO <= 0; SCLK <= 1; end // Start
                        2:  begin SDO <= 0; SCLK <= 0; end
                        // Data transmission is handled by logic driving SCLK above
                        // and logic driving SDO below
                        
                        // ACK slots (ignore actual ACK for simplicity in pure Verilog)
                        11: SDO <= 1; // ACK 1
                        20: SDO <= 1; // ACK 2
                        29: SDO <= 1; // ACK 3
                        
                        30: begin SDO <= 0; SCLK <= 0; end // Stop setup
                        31: begin SDO <= 0; SCLK <= 1; end // Stop
                        32: begin SDO <= 1; SCLK <= 1; end // Stop complete
                    endcase

                    // Data Bits Logic
                    if ((SD_COUNTER >= 3) && (SD_COUNTER <= 10)) SDO <= I2C_DATA[23 - (SD_COUNTER - 3)]; // Byte 1
                    if ((SD_COUNTER >= 12) && (SD_COUNTER <= 19)) SDO <= I2C_DATA[15 - (SD_COUNTER - 12)]; // Byte 2
                    if ((SD_COUNTER >= 21) && (SD_COUNTER <= 28)) SDO <= I2C_DATA[7 - (SD_COUNTER - 21)];  // Byte 3
                    
                end else begin
                    END <= 1; // Done
                end
            end else begin
                SD_COUNTER <= 0;
                SDO <= 1;
                SCLK <= 1;
            end
        end
    end
endmodule