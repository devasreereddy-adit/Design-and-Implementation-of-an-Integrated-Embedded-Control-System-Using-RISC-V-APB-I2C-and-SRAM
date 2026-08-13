`timescale 1ns / 1ps
module sram #(

    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 9)
    (
    input wire clk,
    input wire rst,
    input wire en,
    input wire we,
    input wire rd,
    input wire [ADDR_WIDTH - 1:0] addr,
    input wire [DATA_WIDTH - 1:0] din,
    output reg [DATA_WIDTH - 1:0] dout
);
    
    reg [DATA_WIDTH - 1:0] mem [0:(1<<ADDR_WIDTH)-1];
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 32'h00000000;
        end
        else begin
            if (en & we) begin
                mem[addr] <= din;
            end
            else if (en & rd) begin 
                dout <= mem[addr];
            end
            else dout <= 32'h00000000;
        end   
    end
endmodule
