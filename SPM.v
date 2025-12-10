`timescale 1ns/1ps

// --- 1-bit Register ---
module d_reg (
    input wire clk,
    input wire rst,
    input wire d,
    output reg q
);
    always @(posedge clk or posedge rst) begin
        if (rst) q <= 1'b0;
        else     q <= d;
    end
endmodule

module full_adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire s,
    output wire cout
);
    assign s = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

// --- Pipe Unit (Bit-Serial Adder Stage) ---
// Logic: Full Adder + Carry Register (Feedback) + Sum Register (Feedforward)
module pipe (
    input wire clk,
    input wire rst,
    input wire a,   // Input from previous stage sum
    input wire b,   // Partial product bit (AND output)
    output wire q   // Registered Sum Output
);
    wire s_wire, cin_wire, cout_wire;
    wire current_cin; 
    
    // Full Adder
    full_adder fa_inst (
        .a(a), .b(b), .cin(current_cin), 
        .s(s_wire), .cout(cout_wire)
    );

    // Carry Register (Feedback loop)
    d_reg reg_carry (
        .clk(clk), .rst(rst), .d(cout_wire), .q(current_cin)
    );

    // Sum Register (Pipeline Output)
    d_reg reg_sum (
        .clk(clk), .rst(rst), .d(s_wire), .q(q)
    );
endmodule

// --- Serial Converter (Parallel-to-Serial) ---
// Shifts on FALLING EDGE (negedge) as per original design for setup timing
module serial_converter #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst,
    input wire load,
    input wire [WIDTH-1:0] d,
    output wire dout
);
    reg [WIDTH-1:0] buffer_s;

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            buffer_s <= 0;
        end else begin
            if (load)
                buffer_s <= d;
            else
                buffer_s <= {1'b0, buffer_s[WIDTH-1:1]}; // Shift Right (LSB first out)
        end
    end

    assign dout = buffer_s[0];
endmodule

// --- Shift Register Out (Serial-to-Parallel) ---
module shift_reg_out #(parameter WIDTH = 16) (
    input wire clk,
    input wire rst,
    input wire ena,
    input wire d, // Serial Input
    output wire [WIDTH-1:0] q_reg
);
    reg [WIDTH-1:0] buffer_s;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_s <= 0;
        end else if (ena) begin
            // Shift in from MSB (pushing LSBs down)
            buffer_s <= {d, buffer_s[WIDTH-1:1]};
        end
    end
    assign q_reg = buffer_s;
endmodule

// --- Bit Counter ---
module bit_counter #(parameter MAX_COUNT = 16) (
    input wire clk,
    input wire rst,
    input wire ena,
    output reg max_tick
);
    integer count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            max_tick <= 0;
        end else if (ena) begin
            if (count == MAX_COUNT) begin
                count <= 0;
                max_tick <= 1; // Pulse ready
            end else begin
                count <= count + 1;
                max_tick <= 0;
            end
        end else begin
            max_tick <= 0;
            count <= 0;
        end
    end
endmodule


// =========================================================
// 2. UNSIGNED 8-BIT CORE (sp_multiplier_8bit)
// =========================================================
module sp_multiplier_8bit (
    input wire clk,
    input wire rst,
    input wire ena,
    input wire load,
    input wire [7:0] a, // Multiplier (Parallel -> Serial)
    input wire [7:0] b, // Multiplicand (Parallel Constant)
    output wire data_ready,
    output wire [15:0] prod, // 16-bit Product
    output wire prod_ser
);

    // Internal Signals
    wire a_s;              // Serial 'a'
    wire [7:0] and_out;    // Partial Products (a_s AND b)
    wire [7:0] reg_out;    // Chain Connection Wires
    wire [15:0] prod_s;    // Internal Product Shift Register
    wire ready_s;

    // 1. Serial Converter (8-bit)
    serial_converter #(.WIDTH(8)) U_SER_CONV (
        .clk(clk), .rst(rst), .load(load), .d(a), .dout(a_s)
    );

    // 2. AND Array (8 Gates)
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : AND_ARRAY
            assign and_out[i] = a_s & b[i];
        end
    endgenerate

    // 3. The Processing Chain (MSB down to LSB)
    // U5: MSB Register (Start of chain)
    d_reg U_MSB_REG (
        .clk(clk), .rst(rst), .d(and_out[7]), .q(reg_out[7])
    );

    // Pipe Stages 6 down to 0
    pipe U_PIPE_6 (.clk(clk), .rst(rst), .a(reg_out[7]), .b(and_out[6]), .q(reg_out[6]));
    pipe U_PIPE_5 (.clk(clk), .rst(rst), .a(reg_out[6]), .b(and_out[5]), .q(reg_out[5]));
    pipe U_PIPE_4 (.clk(clk), .rst(rst), .a(reg_out[5]), .b(and_out[4]), .q(reg_out[4]));
    pipe U_PIPE_3 (.clk(clk), .rst(rst), .a(reg_out[4]), .b(and_out[3]), .q(reg_out[3]));
    pipe U_PIPE_2 (.clk(clk), .rst(rst), .a(reg_out[3]), .b(and_out[2]), .q(reg_out[2]));
    pipe U_PIPE_1 (.clk(clk), .rst(rst), .a(reg_out[2]), .b(and_out[1]), .q(reg_out[1]));
    pipe U_PIPE_0 (.clk(clk), .rst(rst), .a(reg_out[1]), .b(and_out[0]), .q(reg_out[0]));

    // 4. Serial Output (From LSB pipe)
    assign prod_ser = reg_out[0];

    // 5. Output Capture Shift Register (16-bit)
    shift_reg_out #(.WIDTH(16)) U_SHIFT_OUT (
        .clk(clk), .rst(rst), .ena(ena), .d(reg_out[0]), .q_reg(prod_s)
    );

    // 6. Counter (Counts ~2N+1 cycles)
    // 8 bits input + 8 bits pipe delay + 1 margin = 17 cycles
    bit_counter #(.MAX_COUNT(16)) U_COUNTER (
        .clk(clk), .rst(rst), .ena(ena), .max_tick(ready_s)
    );

    // 7. Final Output Latch
    reg [15:0] final_prod_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) final_prod_reg <= 0;
        else if (ready_s) final_prod_reg <= prod_s;
    end
    assign prod = final_prod_reg;

    // Output the internal ready signal as data_ready
    d_reg U_READY_FLAG (.clk(clk), .rst(rst), .d(ready_s), .q(data_ready));

endmodule


// =========================================================
// 3. SIGNED CONTROLLER WRAPPER (Top Level)
// =========================================================
module SPM (
    input wire clk,
    input wire rst,
    input wire start,         // Single pulse to start
    input wire signed [7:0] a,
    input wire signed [7:0] b,
    output reg signed [15:0] prod,
    output reg done,
    output reg sign_flag
);

    // -- State Definitions --
    localparam S_IDLE = 2'b00;
    localparam S_WORK = 2'b01;
    localparam S_DONE = 2'b10;
    
    reg [1:0] state;

    // -- Internal Signals for Core --
    reg core_load;
    reg core_ena;
    wire core_ready;
    wire [15:0] core_prod;
    
    // -- Data Regs --
    reg [7:0] abs_a, abs_b;
    reg stored_sign;

    // -- Instantiate Unsigned Core --
    sp_multiplier_8bit U_CORE (
        .clk(clk),
        .rst(rst),
        .ena(core_ena),
        .load(core_load),
        .a(abs_a),
        .b(abs_b),
        .data_ready(core_ready),
        .prod(core_prod),
        .prod_ser()
    );

    // -- FSM Logic --
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            core_load <= 0;
            core_ena <= 0;
            done <= 0;
            prod <= 0;
            sign_flag <= 0;
            abs_a <= 0;
            abs_b <= 0;
            stored_sign <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        // 1. Capture Sign
                        stored_sign <= a[7] ^ b[7];
                        
                        // 2. Capture Absolute Values
                        // Negate if MSB is 1 (Two's Complement)
                        abs_a <= (a[7]) ? (~a + 1) : a;
                        abs_b <= (b[7]) ? (~b + 1) : b;
                        
                        // 3. Trigger Core Load
                        core_load <= 1; 
                        core_ena <= 1;  // Enable core
                        state <= S_WORK;
                    end
                end

                S_WORK: begin
                    core_load <= 0; // De-assert load (it was a pulse)
                    core_ena <= 1;  // Keep Enable high
                    
                    if (core_ready) begin
                        // Core finished!
                        core_ena <= 0; // Stop core
                        
                        // Fix Sign
                        if (stored_sign)
                            prod <= (~core_prod + 1); // Negate result
                        else
                            prod <= core_prod;
                            
                        sign_flag <= stored_sign;
                        done <= 1;
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    // Wait state (optional one-cycle hold)
                    state <= S_IDLE;
                    done <= 0; 
                end
            endcase
        end
    end
endmodule
