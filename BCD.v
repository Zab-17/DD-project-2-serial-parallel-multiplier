module bin16_to_bcd_view (
    input  wire [15:0] bin_in,     // 16-bit MAGNITUDE (absolute value)
    input  wire        sign_neg,   // 1 = negative, 0 = positive
    input  wire [1:0]  view_mode,  // 00,01,10 -> 3 view modes

    output reg  [3:0] d0,          // ones
    output reg  [3:0] d1,          // tens
    output reg  [3:0] d2,          // hundreds
    output reg  [3:0] d3,          // thousands
    output reg  [3:0] d4,          // ten-thousands
    output reg  [3:0] d5,          // sign digit

    // 4 digits actually sent to display logic (after view-mode window)
    output reg  [3:0] disp0,       // rightmost display digit
    output reg  [3:0] disp1,
    output reg  [3:0] disp2,
    output reg  [3:0] disp3        // leftmost display digit
);

    // Internal temporary variable used for /10 and %10
    integer temp;

    always @* begin
        // start from the magnitude
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

        // sign digit (d5):
        // encode minus as 4'hA (special code),
        // positive as 4'hF (we'll treat >9 as blank)
        if (sign_neg)
            d5 = 4'hA;  // show '-'
        else
            d5 = 4'hF;  // blank
    end

    always @* begin
        case (view_mode)
            2'b00: begin
                // Mode 1: show d0..d3 (ones..thousands)
                disp0 = d0;  // rightmost
                disp1 = d1;
                disp2 = d2;
                disp3 = d3;  // leftmost
            end

            2'b01: begin
                // Mode 2: show d1..d4 (tens..ten-thousands)
                disp0 = d1;  // rightmost
                disp1 = d2;
                disp2 = d3;
                disp3 = d4;  // leftmost
            end

            2'b10: begin
                // Mode 3: show d2..d5 (hundreds..sign)
                disp0 = d2;  // rightmost
                disp1 = d3;
                disp2 = d4;
                disp3 = d5;  // leftmost = sign digit
            end

            default: begin
                // safe default
                disp0 = 4'd0;
                disp1 = 4'd0;
                disp2 = 4'd0;
                disp3 = 4'd0;
            end
        endcase
    end

endmodule
