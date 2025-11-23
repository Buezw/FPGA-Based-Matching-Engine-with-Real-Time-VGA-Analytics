module audio_tone_generator (
    input wire clk,                 
    input wire reset,               
    input wire trigger_signal,      
    output reg [31:0] left_channel, 
    output reg [31:0] right_channel 
);

    parameter TONE_DIVIDER = 50000; // 频率控制
    parameter AMPLITUDE = 32'd50000000; // 音量控制

    reg [16:0] counter;
    reg clk_tone;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_tone <= 0;
        end else if (trigger_signal) begin
            if (counter >= TONE_DIVIDER) begin
                counter <= 0;
                clk_tone <= ~clk_tone; 
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;
            clk_tone <= 0;
        end
    end

    always @(*) begin
        if (trigger_signal) begin
            if (clk_tone) begin
                left_channel  = AMPLITUDE;
                right_channel = AMPLITUDE;
            end else begin
                left_channel  = -AMPLITUDE; 
                right_channel = -AMPLITUDE;
            end
        end else begin
            left_channel  = 32'd0;
            right_channel = 32'd0;
        end
    end
endmodule