module vga_trend_display(
    input clk,              // 系统时钟 50MHz
    input reset,
    input video_on,         // VGA 控制器输出的显示有效信号
    input [9:0] h_cnt,      // VGA 当前扫描的横坐标
    input [9:0] v_cnt,      // VGA 当前扫描的纵坐标
    input [7:0] trade_price,// 当前成交价
    input match_signal,     // 撮合成功信号（用于触发更新）
    input [7:0] spread,     // 价差（用于显示底部条形图）
    output [3:0] R, G, B    // VGA 颜色输出
);

    // ============================================================
    // 1. 历史价格存储器 (History Memory)
    // ------------------------------------------------------------
    // 定义一个 640 深度、8 位宽的寄存器数组，用来存屏幕上每一列对应的价格
    reg [7:0] price_history [0:639];
    
    integer i;
    
    // 这里的逻辑是：检测 match_signal 的上升沿，每成交一次，图表向左滚动一格
    reg match_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            match_prev <= 0;
            // 复位时清空历史
            for (i = 0; i < 640; i = i + 1) begin
                price_history[i] <= 8'd0; 
            end
        end
        else begin
            match_prev <= match_signal;
            
            // 如果检测到 match_signal 上升沿 (0->1)，更新历史记录
            if (match_signal && !match_prev) begin
                // 移位操作：所有数据向左移一位
                for (i = 0; i < 639; i = i + 1) begin
                    price_history[i] <= price_history[i+1];
                end
                // 最右边填入最新的成交价
                price_history[639] <= trade_price;
            end
        end
    end

    // ============================================================
    // 2. 绘制逻辑 (Draw Logic)
    // ------------------------------------------------------------
    wire is_trend_line;
    wire [7:0] current_x_price;
    wire [9:0] y_pos;

    // 取出当前扫描到的这一列(h_cnt) 对应的历史价格
    // 注意：必须确保 h_cnt 在 0-639 范围内，否则数组越界可能读出垃圾值
    assign current_x_price = (h_cnt < 640) ? price_history[h_cnt] : 8'd0;

    // 将价格映射到 Y 坐标 (价格越高，Y越小/越靠上)
    // 假设价格范围 0-255，屏幕高度 480。我们让价格 0 对应 Y=400，价格 255 对应 Y=145
    assign y_pos = 10'd400 - current_x_price; 

    // 判断当前像素点是否在走势线上 (画 2 个像素宽度的点，以此增强可见度)
    assign is_trend_line = (v_cnt >= y_pos && v_cnt <= y_pos + 2);

    // 底部价差条 (Spread Bar) - 红色表示
    wire is_spread_bar;
    assign is_spread_bar = (v_cnt > 460) && (h_cnt < (spread * 5));

    // ============================================================
    // 3. 颜色输出
    // ------------------------------------------------------------
    // 走势线为绿色，价差条为红色，背景黑色
    assign R = (video_on && is_spread_bar) ? 4'hF : 4'h0;
    assign G = (video_on && is_trend_line) ? 4'hF : 4'h0;
    assign B = 4'h0;

endmodule