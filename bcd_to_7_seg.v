//====================================================
// File: bcd_to_7seg.v
// One BCD digit (0–9, plus 'A' for minus) -> 7-segment
// Target: Basys 3 (common-anode, active-low)
// seg = {CA, CB, CC, CD, CE, CF, CG}
// dp  = decimal point (active-low)
//====================================================
module bcd_to_7seg (
    input  wire [3:0] bcd,   // BCD digit 0–9, or 4'hA = '-'
    input  wire       dp_on, // 1 = turn DP ON, 0 = DP OFF
    output reg  [6:0] seg,   // {CA, CB, CC, CD, CE, CF, CG}
    output reg        dp
);

    always @* begin
        // default: all segments OFF (inactive = 1 for common-anode)
        seg = 7'b111_1111;

        case (bcd)
            4'd0: seg = 7'b000_0001; // 0
            4'd1: seg = 7'b100_1111; // 1
            4'd2: seg = 7'b001_0010; // 2
            4'd3: seg = 7'b000_0110; // 3
            4'd4: seg = 7'b100_1100; // 4
            4'd5: seg = 7'b010_0100; // 5
            4'd6: seg = 7'b010_0000; // 6
            4'd7: seg = 7'b000_1111; // 7
            4'd8: seg = 7'b000_0000; // 8
            4'd9: seg = 7'b000_0100; // 9

            4'hA: seg = 7'b111_1110; // '-' minus sign: only middle segment (G) ON

            default: seg = 7'b111_1111; // blank for anything else (e.g. 4'hF)
        endcase

        // Decimal point (also active-low)
        dp = dp_on ? 1'b0 : 1'b1;
    end

endmodule
