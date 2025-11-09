// =====================================================
// Module: Matching Engine (gate-level comparator + spread)
// =====================================================

module matching_engine (
    input  wire [7:0] buy_price,   // from order_generator
    input  wire [7:0] sell_price,  // from order_generator
    output wire       match_flag,  // 1 when buy >= sell
    output wire [7:0] spread       // absolute difference |buy - sell|
);

    // A - B using two's complement: A + (~B + 1)
    wire [7:0] diff_ab;
    wire       cout_ab;
    ripple_add8 u_sub_ab (buy_price, ~sell_price, 1'b1, diff_ab, cout_ab);

    // B - A (for absolute value when buy < sell)
    wire [7:0] diff_ba;
    wire       cout_ba;
    ripple_add8 u_sub_ba (sell_price, ~buy_price, 1'b1, diff_ba, cout_ba);

    // cout_ab==1 → buy >= sell
    assign match_flag = cout_ab;
    assign spread     = match_flag ? diff_ab : diff_ba;

endmodule


// =====================================================
// 8-bit Ripple-Carry Adder
// =====================================================
module ripple_add8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] c;

    full_adder fa0 (a[0], b[0], cin,  sum[0], c[0]);
    full_adder fa1 (a[1], b[1], c[0], sum[1], c[1]);
    full_adder fa2 (a[2], b[2], c[1], sum[2], c[2]);
    full_adder fa3 (a[3], b[3], c[2], sum[3], c[3]);
    full_adder fa4 (a[4], b[4], c[3], sum[4], c[4]);
    full_adder fa5 (a[5], b[5], c[4], sum[5], c[5]);
    full_adder fa6 (a[6], b[6], c[5], sum[6], c[6]);
    full_adder fa7 (a[7], b[7], c[6], sum[7], cout);
endmodule


// =====================================================
// Full Adder (1-bit)
// =====================================================
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule