`timescale 1ns / 1ps
module register_file (
    input  wire        clk,
    input  wire        reg_write,   // Control signal from WB stage
    input  wire [4:0]  rs1_addr,    // instr[19:15]
    input  wire [4:0]  rs2_addr,    // instr[24:20]
    input  wire [4:0]  rd_addr,     // instr[11:7] from WB stage
    input  wire [31:0] write_data,  // Data from WB stage
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] rf [31:0];

    // Initialize x0 to 0 (optional but helpful for simulation)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) rf[i] = 32'b0;
    end

    // Asynchronous Read: Data is available immediately
    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : rf[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : rf[rs2_addr];

    // Synchronous Write: Updates on the clock edge
    always @(posedge clk) begin
        if (reg_write && rd_addr != 5'b0) begin
            rf[rd_addr] <= write_data;
        end
    end
endmodule
