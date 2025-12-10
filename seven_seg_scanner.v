`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 01:20:11 PM
// Design Name: 
// Module Name: seven_seg_scanner
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seven_seg_scanner (
    input wire clk,             // 100MHz
    input wire rst,
    input wire [6:0] seg0,      // Segments for digit 0 (Rightmost)
    input wire [6:0] seg1,
    input wire [6:0] seg2,
    input wire [6:0] seg3,      // Segments for digit 3 (Leftmost)
    output reg [3:0] an,        // Anodes (Active Low)
    output reg [6:0] seg_out   // Cathodes (Active Low)
);

    // Clock Divider: 100MHz / 2^18 ~= 381 Hz refresh rate
    localparam N = 18;
    reg [N-1:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) count <= 0;
        else count <= count + 1;
    end

    // Use top 2 bits to select active digit
    always @* begin
        case (count[N-1:N-2])
            2'b00: begin
                an = 4'b1110;       // Digit 0 ON
                seg_out = seg0;
            end
            2'b01: begin
                an = 4'b1101;       // Digit 1 ON
                seg_out = seg1;
            end
            2'b10: begin
                an = 4'b1011;       // Digit 2 ON
                seg_out = seg2;
            end
            2'b11: begin
                an = 4'b0111;       // Digit 3 ON
                seg_out = seg3;
            end
            default: begin
                an = 4'b1111; 
                seg_out = 7'b1111111;
            end
        endcase
    end
endmodule
