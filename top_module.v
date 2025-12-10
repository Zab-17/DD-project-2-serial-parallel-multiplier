`timescale 1ns/1ps

module top_module (
    input wire clk,             // 100 MHz Oscillator
    input wire [15:0] sw,       // SW15..8 (Multiplicand), SW7..0 (Multiplier)
    input wire btnC,            // Start Calculation
    input wire btnU,            // Reset (NEW)
    input wire btnL,            // Scroll Left
    input wire btnR,            // Scroll Right
    output wire [6:0] seg,      // 7-segment 
    output wire [3:0] an,       // Anodes
    output wire [15:0] led      // Status LEDs
);

    // --- Signals ---
    wire rst;                   // Reset signal
    assign rst = btnU;          // Connect Reset to Top Button

    wire start_clean;           // Debounced Start
    wire [15:0] product;        // Result from SPM
    wire done_flag;             // Done signal
    wire sign_flag;             // Result sign
    wire [1:0] view_mode;       // From scroll controller
    
    // BCD Digits
    wire [3:0] disp0_bcd, disp1_bcd, disp2_bcd, disp3_bcd;
    
    // Segment Patterns
    wire [6:0] seg0_pat, seg1_pat, seg2_pat, seg3_pat;
    
    // Unused full digits
    wire [3:0] d0, d1, d2, d3, d4, d5; 

    // --- LED ASSIGNMENTS ---
    assign led[0] = done_flag;    // LED 0: Done
    assign led[1] = start_clean;  // LED 1: Start Button Status
    assign led[2] = rst;          // LED 2: Reset Status
    assign led[15:3] = 13'b0;     // All other LEDs OFF

    // 1. Debounce Start Button (BTNC)
    debouncer U_DEBOUNCE_START (
        .clk(clk),
        .btn_in(btnC),
        .btn_out(start_clean)
    );

    // 2. Signed Serial-Parallel Multiplier
    SPM U_SPM (
        .clk(clk),
        .rst(rst),
        .start(start_clean),
        .a(sw[7:0]),
        .b(sw[15:8]),
        .prod(product),
        .done(done_flag),
        .sign_flag(sign_flag)
    );

    // 3. Scroll Controller (BTNL / BTNR)
    view_mode_ctrl U_SCROLL (
        .clk(clk),
        .rst(rst),
        .btn_l(btnL),
        .btn_r(btnR),
        .view_mode(view_mode)
    );

    // 4. Binary to BCD View Converter
    wire [15:0] product_mag;
    assign product_mag = (product[15]) ? (~product + 1) : product;
    wire product_is_neg = product[15]; 

    bin16_to_bcd_view U_BIN_BCD (
        .bin_in(product_mag),
        .sign_neg(product_is_neg),
        .view_mode(view_mode),
        .d0(d0), .d1(d1), .d2(d2), .d3(d3), .d4(d4), .d5(d5),
        .disp0(disp0_bcd),
        .disp1(disp1_bcd),
        .disp2(disp2_bcd),
        .disp3(disp3_bcd)
    );

    // 5. BCD to 7-Segment Decoders
    bcd_to_7seg U_DEC0 (.bcd(disp0_bcd), .seg(seg0_pat));
    bcd_to_7seg U_DEC1 (.bcd(disp1_bcd), .seg(seg1_pat));
    bcd_to_7seg U_DEC2 (.bcd(disp2_bcd), .seg(seg2_pat));
    bcd_to_7seg U_DEC3 (.bcd(disp3_bcd), .seg(seg3_pat));

    // 6. 7-Segment Scanner
    seven_seg_scanner U_SCANNER (
        .clk(clk),
        .rst(rst),
        .seg0(seg0_pat),
        .seg1(seg1_pat),
        .seg2(seg2_pat),
        .seg3(seg3_pat),
        .an(an),
        .seg_out(seg)
    );

endmodule
