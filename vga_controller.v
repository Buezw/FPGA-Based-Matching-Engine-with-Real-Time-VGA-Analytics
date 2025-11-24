module vga_controller(clk_25mhz, reset, h_cnt, v_cnt, hsync, vsync, video_on);

    input clk_25mhz;
    input reset;
    output [9:0] h_cnt;
    output [9:0] v_cnt;
    output hsync;
    output vsync;
    output video_on;

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    // VGA timing parameters
    parameter H_VISIBLE = 640;
    parameter H_FRONT = 16;
    parameter H_SYNC = 96;
    parameter H_BACK = 48;
    parameter V_VISIBLE = 480;
    parameter V_FRONT = 10;
    parameter V_SYNC = 2;
    parameter V_BACK = 33;

    wire h_end;
    wire v_end;

    assign h_end = (h_cnt == H_VISIBLE + H_FRONT + H_SYNC + H_BACK - 1);
    assign v_end = (v_cnt == V_VISIBLE + V_FRONT + V_SYNC + V_BACK - 1);

    // Horizontal counter
    always @(posedge clk_25mhz or posedge reset) begin
        if (reset)
            h_cnt <= 10'd0;
        else if (h_end)
            h_cnt <= 10'd0;
        else
            h_cnt <= h_cnt + 10'd1;
    end

    // Vertical counter
    always @(posedge clk_25mhz or posedge reset) begin
        if (reset)
            v_cnt <= 10'd0;
        else if (h_end)
            if (v_end)
                v_cnt <= 10'd0;
            else
                v_cnt <= v_cnt + 10'd1;
    end

    // Sync and visible area
    always @* 
    begin
    if (h_cnt >= H_VISIBLE + H_FRONT && h_cnt < H_VISIBLE + H_FRONT + H_SYNC) begin
        hsync = 1'b0;
    end else begin
        hsync = 1'b1;
    end

    if (v_cnt >= V_VISIBLE + V_FRONT && v_cnt < V_VISIBLE + V_FRONT + V_SYNC) begin
        vsync = 1'b0;
    end else begin
        vsync = 1'b1;
    end

    if (h_cnt < H_VISIBLE && v_cnt < V_VISIBLE) begin
        video_on = 1'b1;
    end else begin
        video_on = 1'b0;
        end
    end

endmodule
