`timescale 1ns/1ns
`include "SPM.v"

module SPM_TB;

    // -- Parameters --
    parameter CLK_PERIOD = 20; // 50 MHz Clock (20ns period)

    // -- DUT Signals --
    reg clk;
    reg rst;
    reg start;
    reg signed [7:0] a;
    reg signed [7:0] b;
    wire signed [15:0] prod;
    wire done;
    wire sign_flag;

    // -- Instantiate the Unit Under Test (UUT) --
    SPM uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .b(b),
        .prod(prod),
        .done(done),
        .sign_flag(sign_flag)
    );

    // -- Clock Generation --
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // -- Test Procedure --
    initial begin
        // 1. Initialize Inputs
        rst = 1;
        start = 0;
        a = 0;
        b = 0;

        // 2. Wait for Global Reset
        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD * 2);

        $display("==================================================");
        $display("Starting Signed SPM Controller Testbench");
        $display("==================================================");

        // -- Test Case 1: Positive * Positive (12 * 10 = 120) --
        run_test(8'd12, 8'd10, 16'd120);

        // -- Test Case 2: Positive * Negative (10 * -5 = -50) --
        run_test(8'd10, -8'd5, -16'd50);

        // -- Test Case 3: Negative * Positive (-20 * 3 = -60) --
        run_test(-8'd20, 8'd3, -16'd60);

        // -- Test Case 4: Negative * Negative (-8 * -8 = 64) --
        run_test(-8'd8, -8'd8, 16'd64);

        // -- Test Case 5: Zero Multiplication (25 * 0 = 0) --
        run_test(8'd25, 8'd0, 16'd0);
        
        // -- Test Case 6: Edge Case Max Positive (127 * 1 = 127) --
        run_test(8'd127, 8'd1, 16'd127);
        
        // -- Test Case 7: Edge Case Min Negative (-128 * 1 = -128) --
        // Note: abs(-128) in 8-bit is -128 (10000000), but unsigned interpretation is 128.
        // The logic should handle this via unsigned core.
        run_test(-8'd128, 8'd1, -16'd128);
        
        // -- Test Case 8: Large Negative Product (-100 * 10 = -1000)
        run_test(-8'd100, 8'd10, -16'd1000);

        // End Simulation
        #(CLK_PERIOD * 10);
        $display("==================================================");
        $display("All tests completed.");
        $finish;
    end

    // -- Task for Running a Single Test --
    task run_test;
        input signed [7:0] in_a;
        input signed [7:0] in_b;
        input signed [15:0] expected_prod;
        
        begin
            // Setup inputs
            a = in_a;
            b = in_b;
            
            // Pulse Start
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            // Wait for Done signal
            wait(done);
            
            // Allow signals to settle/latch on the done edge
            @(negedge clk); 

            // Check Result
            if (prod === expected_prod) begin
                $display("[PASS] A=%4d * B=%4d = %6d | SignFlag=%b", in_a, in_b, prod, sign_flag);
            end else begin
                $display("[FAIL] A=%4d * B=%4d = %6d (Expected: %6d) | SignFlag=%b", 
                         in_a, in_b, prod, expected_prod, sign_flag);
            end
            
            // Wait a few cycles before next test
            #(CLK_PERIOD * 5);
        end
    endtask

    // -- Waveform Dump --
    initial begin
        $dumpfile("SPM_TB.vcd");
        $dumpvars(0, SPM_TB);
    end

endmodule
