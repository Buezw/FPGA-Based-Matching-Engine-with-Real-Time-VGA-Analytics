// =====================================================
// Module: Controller FSM
// =====================================================

module controller_fsm (clk, reset, match_flag, halt_flag, state, enable_count);
    input  clk;
    input  reset;
    input  match_flag;
    input  halt_flag;
    output [1:0] state;
    output enable_count;

    reg [1:0] state;
    reg enable_count;


    // -------------------------------------------------
    // State encoding
    // -------------------------------------------------
    parameter IDLE = 2'b00;
    parameter MATCH = 2'b01;
    parameter HALT = 2'b10;

    reg [1:0] next_state;

    // -------------------------------------------------
    // Sequential state register
    // -------------------------------------------------
    always @(posedge clk or posedge reset) 
    begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -------------------------------------------------
    // Next-state logic
    // -------------------------------------------------
    always @(*) begin
        case (state)
            IDLE: begin
                if (halt_flag)
                    next_state = HALT;
                else if (match_flag)
                    next_state = MATCH;
                else
                    next_state = IDLE;
            end

            MATCH: begin
                if (halt_flag)
                    next_state = HALT;
                else if (!match_flag)
                    next_state = IDLE;
                else
                    next_state = MATCH;
            end

            HALT: begin
                if (reset)
                    next_state = IDLE;
                else
                    next_state = HALT;
            end

            default: next_state = IDLE;
        endcase
    end

    // -------------------------------------------------
    // Output logic
    // -------------------------------------------------
    always @(*) begin
        case (state)
            IDLE: begin
                enable_count = 1'b0;
            end
            MATCH: begin
                enable_count = 1'b1; // only count trades when matching
            end
            HALT: begin
                enable_count = 1'b0;
            end
            default: enable_count = 1'b0;
        endcase
    end

endmodule