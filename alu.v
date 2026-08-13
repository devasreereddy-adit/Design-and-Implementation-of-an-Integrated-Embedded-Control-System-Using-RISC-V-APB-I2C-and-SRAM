`timescale 1ns / 1ps
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    // Zero flag is useful for branch instructions (a - b == 0)
    assign zero = (result == 32'b0);
    initial result = 32'h00000_0000;
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a & b;       // AND
            4'b0001: result = a | b;       // OR
            4'b0010: result = a + b;       // ADD
            4'b0110: result = a - b;       // SUB
            4'b1100: result = ~(a | b);    // NOR
            4'b0111: result = (a < b) ? {1'b1,15'b000000000000000,a[7:0],b[7:0]} : {1'b0,15'b000000000000000,a[7:0],b[7:0]}; // SLT (Set Less Than)
            default: result = 32'b0;
        endcase
    end
endmodule