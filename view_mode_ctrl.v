//====================================================
// view_mode_ctrl.v
// Scrolls through 3 view modes using the middle button (BTNC).
//
// Hook BTNC (pin U18 on Basys3) to the 'btn_scroll' port in the XDC.
//
// view_mode = 2'b00 -> show d0..d3
// view_mode = 2'b01 -> show d1..d4
// view_mode = 2'b10 -> show d2..d5
//
// Each rising edge on the button: 00 -> 01 -> 10 -> 00 ...
//====================================================
module view_mode_ctrl (
    input  wire       clk,        // 100 MHz clock
    input  wire       rst,        // synchronous reset, active-high
    input  wire       btn_scroll, // BTNC (U18)

    output reg  [1:0] view_mode   // 00, 01, 10
);

    // 1) Synchronize button to clock domain (2-FF sync)
    reg btn_ff1, btn_ff2;
    always @(posedge clk) begin
        btn_ff1 <= btn_scroll;
        btn_ff2 <= btn_ff1;
    end

    // 2) Rising-edge detection
    reg btn_prev;
    wire btn_rise = btn_ff2 & ~btn_prev;

    // 3) View-mode state machine (3 states)
    always @(posedge clk) begin
        if (rst) begin
            view_mode <= 2'b00;   // start at mode 0: d0..d3
            btn_prev  <= 1'b0;
        end else begin
            btn_prev <= btn_ff2;

            if (btn_rise) begin
                case (view_mode)
                    2'b00: view_mode <= 2'b01; // next: d1..d4
                    2'b01: view_mode <= 2'b10; // next: d2..d5
                    2'b10: view_mode <= 2'b00; // wrap around
                    default: view_mode <= 2'b00;
                endcase
            end
        end
    end

endmodule
