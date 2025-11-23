// =============================================================
// 文件名: audio_pack.v
// 说明: 包含音频触发、音调生成、CODEC配置及I2C控制器
// 风格: Verilog-1995 (Old Style Header)
// =============================================================

// -------------------------------------------------------------
// 模块 1: 音频触发器 (捕捉 match_signal 上升沿)
// -------------------------------------------------------------
module audio_trigger (clk, reset, match_signal, play_pulse);

    input clk;
    input reset;
    input match_signal;
    output play_pulse;

    reg play_pulse;
    reg match_d;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            match_d <= 1'b0;
            play_pulse <= 1'b0;
        end else begin
            match_d <= match_signal;
            // 当信号从 0 变 1 时，产生一个脉冲
            play_pulse <= (match_signal && !match_d); 
        end
    end
endmodule

// -------------------------------------------------------------
// 模块 2: 音调生成器 (收到脉冲后播放一段声音)
// -------------------------------------------------------------
module my_tone (clk, reset, play_trigger, audio_out_allowed, write_out, left_out, right_out);

    input  clk;
    input  reset;
    input  play_trigger;
    input  audio_out_allowed;
    output write_out;
    output [31:0] left_out;
    output [31:0] right_out;

    // 参数定义在模块内部
    parameter DURATION = 12000;     // 约 0.25秒
    parameter HALF_PERIOD = 55;     // 音调频率控制

    reg [15:0] time_cnt;
    reg [8:0] wave_cnt;
    reg tone_state;
    reg is_playing;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            is_playing <= 0;
            time_cnt <= 0;
            wave_cnt <= 0;
            tone_state <= 0;
        end else if (audio_out_allowed) begin
            if (play_trigger) begin
                is_playing <= 1;
                time_cnt <= 0;
            end else if (is_playing) begin
                if (time_cnt >= DURATION) 
                    is_playing <= 0;
                else 
                    time_cnt <= time_cnt + 1;
                
                if (wave_cnt >= HALF_PERIOD) begin
                    wave_cnt <= 0;
                    tone_state <= ~tone_state;
                end else 
                    wave_cnt <= wave_cnt + 1;
            end
        end
    end

    // 输出赋值
    assign left_out = is_playing ? (tone_state ? 32'h0FFFFFFF : 32'hF0000000) : 32'd0;
    assign right_out = left_out;
    assign write_out = is_playing && audio_out_allowed;

endmodule

// -------------------------------------------------------------
// 模块 3: avconf (WM8731 配置逻辑 - 保持原有旧版风格)
// -------------------------------------------------------------
module avconf (CLOCK_50, reset, FPGA_I2C_SCLK, FPGA_I2C_SDAT);
    
    input CLOCK_50;
    input reset;
    output FPGA_I2C_SCLK;
    inout FPGA_I2C_SDAT;

    reg [15:0] mI2C_CLK_DIV;
    reg [23:0] mI2C_DATA;
    reg mI2C_CTRL_CLK;
    reg mI2C_GO;
    wire mI2C_END;
    wire mI2C_ACK;
    wire iRST_N; 
    reg [15:0] LUT_DATA;
    reg [5:0] LUT_INDEX;
    reg [3:0] mSetup_ST;

    parameter CLK_Freq = 50000000;
    parameter I2C_Freq = 20000;
    parameter LUT_SIZE = 50;

    assign iRST_N = !reset;

    always@(posedge CLOCK_50 or negedge iRST_N) begin
        if(!iRST_N) begin
            mI2C_CTRL_CLK <= 0;
            mI2C_CLK_DIV <= 0;
        end else begin
            if( mI2C_CLK_DIV < (CLK_Freq/I2C_Freq) )
                mI2C_CLK_DIV <= mI2C_CLK_DIV+1;
            else begin
                mI2C_CLK_DIV <= 0;
                mI2C_CTRL_CLK <= ~mI2C_CTRL_CLK;
            end
        end
    end

    I2C_Controller u0 (
        .CLOCK(mI2C_CTRL_CLK),
        .FPGA_I2C_SCLK(FPGA_I2C_SCLK),
        .FPGA_I2C_SDAT(FPGA_I2C_SDAT),
        .I2C_DATA(mI2C_DATA),
        .GO(mI2C_GO),
        .END(mI2C_END),
        .ACK(mI2C_ACK),
        .RESET(iRST_N)
    );

    always@(posedge mI2C_CTRL_CLK or negedge iRST_N) begin
        if(!iRST_N) begin
            LUT_INDEX <= 0;
            mSetup_ST <= 0;
            mI2C_GO <= 0;
        end else if(LUT_INDEX<LUT_SIZE) begin
            case(mSetup_ST)
            0: begin
                if(LUT_INDEX<10) mI2C_DATA <= {8'h34,LUT_DATA};
                else             mI2C_DATA <= {8'h40,LUT_DATA};
                mI2C_GO <= 1;
                mSetup_ST <= 1;
            end
            1: begin
                if(mI2C_END) begin
                    if(!mI2C_ACK) mSetup_ST <= 2;
                    else mSetup_ST <= 0;
                    mI2C_GO <= 0;
                end
            end
            2: begin
                LUT_INDEX <= LUT_INDEX+1;
                mSetup_ST <= 0;
            end
            endcase
        end
    end

    // 配置表
    always @(*) begin
        case(LUT_INDEX)
        0: LUT_DATA = {7'h0, 9'd24};
        1: LUT_DATA = {7'h1, 9'd24};
        2: LUT_DATA = {7'h2, 9'd119};
        3: LUT_DATA = {7'h3, 9'd119};
        4: LUT_DATA = {7'h4, 9'd17};
        5: LUT_DATA = {7'h5, 9'd6};
        6: LUT_DATA = {7'h6, 9'h000};
        7: LUT_DATA = {7'h7, 9'd77};
        8: LUT_DATA = {7'h8, 9'd0};
        9: LUT_DATA = {7'h9, 9'h001};
        default: LUT_DATA = 16'h0000;
        endcase
    end
endmodule

// -------------------------------------------------------------
// 模块 4: I2C_Controller (保持原有旧版风格)
// -------------------------------------------------------------
module I2C_Controller (CLOCK, FPGA_I2C_SCLK, FPGA_I2C_SDAT, I2C_DATA, GO, END, ACK, RESET);

    input CLOCK;
    output FPGA_I2C_SCLK;
    inout FPGA_I2C_SDAT;
    input [23:0] I2C_DATA;
    input GO;
    output END;
    output ACK;
    input RESET;

    reg END;
    reg [5:0] SD_COUNTER;
    reg SDO;
    reg SCLK;
    reg ACK1,ACK2,ACK3;
    reg [23:0] SD;

    wire FPGA_I2C_SCLK;
    wire FPGA_I2C_SDAT;
    wire ACK;

    assign FPGA_I2C_SCLK = SCLK | ( ((SD_COUNTER >= 4) & (SD_COUNTER <=30))? ~CLOCK :0 );
    assign FPGA_I2C_SDAT = SDO ? 1'bz : 0;
    assign ACK = ACK1 | ACK2 | ACK3;

    always @(negedge RESET or posedge CLOCK ) begin
        if (!RESET) SD_COUNTER=6'b111111;
        else if (GO==0) SD_COUNTER=0;
        else if (SD_COUNTER < 6'b111111) SD_COUNTER=SD_COUNTER+1;
    end

    always @(negedge RESET or posedge CLOCK ) begin
        if (!RESET) begin SCLK=1;SDO=1; ACK1=0;ACK2=0;ACK3=0; END=1; end
        else case (SD_COUNTER)
            6'd0  : begin ACK1=0 ;ACK2=0 ;ACK3=0 ; END=0; SDO=1; SCLK=1;end
            6'd1  : begin SD=I2C_DATA;SDO=0;end
            6'd2  : SCLK=0;
            6'd3  : SDO=SD[23]; 6'd4: SDO=SD[22]; 6'd5: SDO=SD[21]; 6'd6: SDO=SD[20];
            6'd7  : SDO=SD[19]; 6'd8: SDO=SD[18]; 6'd9: SDO=SD[17]; 6'd10: SDO=SD[16];
            6'd11 : SDO=1'b1; 
            6'd12 : begin SDO=SD[15]; ACK1=FPGA_I2C_SDAT; end
            6'd13 : SDO=SD[14]; 6'd14: SDO=SD[13]; 6'd15: SDO=SD[12]; 6'd16: SDO=SD[11];
            6'd17 : SDO=SD[10]; 6'd18: SDO=SD[9]; 6'd19: SDO=SD[8]; 6'd20: SDO=1'b1;
            6'd21 : begin SDO=SD[7]; ACK2=FPGA_I2C_SDAT; end
            6'd22 : SDO=SD[6]; 6'd23: SDO=SD[5]; 6'd24: SDO=SD[4]; 6'd25: SDO=SD[3];
            6'd26 : SDO=SD[2]; 6'd27: SDO=SD[1]; 6'd28: SDO=SD[0]; 6'd29: SDO=1'b1;
            6'd30 : begin SDO=1'b0; SCLK=1'b0; ACK3=FPGA_I2C_SDAT; end
            6'd31 : SCLK=1'b1; 6'd32 : begin SDO=1'b1; END=1; end
        endcase
    end
endmodule