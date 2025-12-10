`timescale 1ns/1ps
//====================================================
// view_mode_ctrl.v (UPDATED)
// Scrolls through view modes using BTNL (left) and BTNR (right).
//
// view_mode = 2'b00 -> show d0..d3 (Rightmost/LSBs)
// view_mode = 2'b01 -> show d1..d4
// view_mode = 2'b10 -> show d2..d5 (Leftmost/MSBs+Sign)
//====================================================
module view_mode_ctrl (
    input  wire       clk,        // 100 MHz clock
    input  wire       rst,        // reset
    input  wire       btn_l,      // BTNL (Scroll Left / Decrement mode)
    input  wire       btn_r,      // BTNR (Scroll Right / Increment mode)
    output reg  [1:0] view_mode   // 00, 01, 10
);

    // 1) Synchronize buttons
    reg l_ff1, l_ff2, r_ff1, r_ff2;
    always @(posedge clk) begin
        l_ff1 <= btn_l;
        l_ff2 <= l_ff1;
        r_ff1 <= btn_r;
        r_ff2 <= r_ff1;
    end

    // 2) Rising-edge detection
    reg l_prev, r_prev;
    wire l_rise = l_ff2 & ~l_prev;
    wire r_rise = r_ff2 & ~r_prev;

    always @(posedge clk) begin
        if (rst) begin
            view_mode <= 2'b00;
            l_prev <= 0;
            r_prev <= 0;
        end else begin
            l_prev <= l_ff2;
            r_prev <= r_ff2;

            if (r_rise) begin
                // Move Right (increase index towards MSBs)
                if (view_mode < 2'b10)
                    view_mode <= view_mode + 1;
            end 
            else if (l_rise) begin
                // Move Left (decrease index towards LSBs)
                if (view_mode > 2'b00)
                    view_mode <= view_mode - 1;
            end
        end
    end
endmodule
