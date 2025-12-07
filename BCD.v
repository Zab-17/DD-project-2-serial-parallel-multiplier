// 16-bit binary to 5-digit BCD with view-mode window
// Method: repeated /10 and %10 (combinational)
// view_mode = 0 -> show digits d0..d3 (ones..thousands)
// view_mode = 1 -> show digits d1..d4 (tens..ten-thousands)

module bin16_to_bcd_view (
    input  wire [15:0] bin_in,      // 16-bit binary input (e.g. product of 2x8-bit)
    input  wire        view_mode,   // 0: show d0-d3, 1: show d1-d4

    // Full BCD digits (for debug / other logic)
    output reg  [3:0] d0,           // ones
    output reg  [3:0] d1,           // tens
    output reg  [3:0] d2,           // hundreds
    output reg  [3:0] d3,           // thousands
    output reg  [3:0] d4,           // ten-thousands

    // 4 digits actually sent to display logic (after view-mode mux)
    output reg  [3:0] disp0,        // rightmost display digit
    output reg  [3:0] disp1,
    output reg  [3:0] disp2,
    output reg  [3:0] disp3         // leftmost display digit
);

    // Internal temporary variable used for /10 and %10
    integer temp;

    // -----------------------------
    // Binary -> BCD digits (combinational)
    // -----------------------------
    always @* begin
        // start from the input value
        temp = bin_in;

        // extract ones
        d0 = temp % 10;
        temp = temp / 10;

        // extract tens
        d1 = temp % 10;
        temp = temp / 10;

        // extract hundreds
        d2 = temp % 10;
        temp = temp / 10;

        // extract thousands
        d3 = temp % 10;
        temp = temp / 10;

        // extract ten-thousands
        d4 = temp % 10;
        // no need to divide again; 16-bit max 65535 fits in 5 digits
    end

    // -----------------------------
    // View-mode multiplexer
    // -----------------------------
    always @* begin
        case (view_mode)
            1'b0: begin
                // Mode 0: show d0..d3  (ones..thousands)
                disp0 = d0;  // rightmost
                disp1 = d1;
                disp2 = d2;
                disp3 = d3;  // leftmost
            end

            1'b1: begin
                // Mode 1: show d1..d4  (tens..ten-thousands)
                disp0 = d1;  // rightmost
                disp1 = d2;
                disp2 = d3;
                disp3 = d4;  // leftmost
            end

            default: begin
                // should never hit, but keep safe
                disp0 = 4'd0;
                disp1 = 4'd0;
                disp2 = 4'd0;
                disp3 = 4'd0;
            end
        endcase
    end

endmodule
