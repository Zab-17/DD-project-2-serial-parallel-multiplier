//====================================================
// top_module.v
// Test module for BCD conversion, view mode control,
// and 7-segment display
// Hardcoded value: -65535
// Target: Basys 3 board
//====================================================
module top_module (
    input  wire        clk,           // 100 MHz clock (W5)
    input  wire        rst,           // Reset button BTNU (T18)
    input  wire        btn_scroll,    // View mode scroll button BTNC (U18)

    // 7-segment display outputs (4 displays)
    output wire [6:0]  seg,           // Segment outputs {CA-CG}
    output wire        dp,            // Decimal point
    output wire [3:0]  an             // Anode control (active-low)
);

    // Hardcoded test value: -65535
    localparam [15:0] TEST_VALUE = 16'd65535;  // Magnitude
    localparam        TEST_SIGN  = 1'b1;       // Negative

    // Internal signals
    wire [1:0]  view_mode;            // Current view mode from controller

    // BCD digit outputs
    wire [3:0] d0, d1, d2, d3, d4, d5;
    wire [3:0] disp0, disp1, disp2, disp3;

    // 7-segment multiplexing signals
    reg [1:0]  digit_select;          // Which digit to display (0-3)
    reg [16:0] refresh_counter;       // Counter for display refresh
    wire [3:0] current_bcd;           // Current BCD digit to display

    //====================================================
    // 1. View Mode Controller
    //    Cycles through 3 view modes using BTNC
    //====================================================
    view_mode_ctrl view_ctrl (
        .clk(clk),
        .rst(rst),
        .btn_scroll(btn_scroll),
        .view_mode(view_mode)
    );

    //====================================================
    // 2. BCD Conversion
    //    Converts 16-bit binary input to BCD digits
    //    with view mode windowing
    //====================================================
    bin16_to_bcd_view bcd_conv (
        .bin_in(TEST_VALUE),          // Hardcoded: 65535
        .sign_neg(TEST_SIGN),         // Hardcoded: negative
        .view_mode(view_mode),        // View mode from controller
        .d0(d0),                      // All 6 BCD digits
        .d1(d1),
        .d2(d2),
        .d3(d3),
        .d4(d4),
        .d5(d5),
        .disp0(disp0),                // 4 digits selected by view mode
        .disp1(disp1),
        .disp2(disp2),
        .disp3(disp3)
    );

    //====================================================
    // 3. 7-Segment Display Multiplexing
    //    Refreshes display at ~1kHz (100MHz / 100000)
    //    Each digit shown for ~250Hz
    //====================================================
    always @(posedge clk) begin
        if (rst) begin
            refresh_counter <= 0;
            digit_select <= 0;
        end else begin
            refresh_counter <= refresh_counter + 1;
            // Change digit every 25000 clocks
            if (refresh_counter[14:0] == 15'd24999) begin
                digit_select <= digit_select + 1;
            end
        end
    end

    // Anode control: active-low, one-hot encoded
    assign an = ~(4'b0001 << digit_select);

    // Multiplexer: select which BCD digit to display
    assign current_bcd = (digit_select == 2'd0) ? disp0 :
                        (digit_select == 2'd1) ? disp1 :
                        (digit_select == 2'd2) ? disp2 :
                                                 disp3;

    //====================================================
    // 4. BCD to 7-Segment Decoder
    //    Converts BCD digit to 7-segment encoding
    //====================================================
    bcd_to_7seg seg_decoder (
        .bcd(current_bcd),
        .dp_on(1'b0),                 // Decimal point always off
        .seg(seg),
        .dp(dp)
    );

endmodule
