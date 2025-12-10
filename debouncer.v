`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/10/2025 01:21:02 PM
// Design Name: 
// Module Name: debouncer
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

module debouncer (
    input wire clk,
    input wire btn_in,
    output reg btn_out
);
    // 20ms debounce at 100MHz -> ~2,000,000 cycles
    // 21 bits covers up to 2,097,152
    reg [20:0] count;
    reg btn_sync_0, btn_sync_1;
    
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
    end

    always @(posedge clk) begin
        if (btn_sync_1 == btn_out) begin
            count <= 0;
        end else begin
            count <= count + 1;
            if (count == 21'd1_000_000) begin // 10ms threshold
                btn_out <= btn_sync_1;
                count <= 0;
            end
        end
    end
endmodule
