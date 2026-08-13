`timescale 1ns / 1ps
module memory_stage(
    input wire        reg_write_out,
    input wire        mem_to_reg_out,
    input wire         mem_write_out,
    input wire  [31:0] alu_result_out,
    input wire  [31:0] write_data_out,
    input wire  [4:0]  rd_out,
    input wire         ld_st_out,
    input wire         PREADY,
    input wire         sram_dn,
    //input wire [31:0] PADDR, PWDATA,
    //input wire PSELx , PWRITE , PENABLE,
    input wire int_rx_full,
    
    output reg       stall,
    output wire        reg_write_out_m,
    output wire        mem_to_reg_out_m,
    output wire         mem_write_out_m,
    output wire         [31:0] alu_result_out_m,
    output wire  [31:0] write_data_out_m,
    output wire  [4:0]  rd_out_m,
    output wire        ld_st_out_m

    );
    
    assign mem_write_out_m = mem_write_out;
    assign reg_write_out_m = reg_write_out;
    assign mem_to_reg_out_m = mem_to_reg_out;
    assign alu_result_out_m = alu_result_out;
    assign write_data_out_m = write_data_out;
    assign rd_out_m = rd_out;
    assign ld_st_out_m = ld_st_out;
    
    always @(*)begin
        if (alu_result_out == 5'h4 && mem_write_out)  begin 
            if (!int_rx_full)stall = 1'b1;
        else stall = 1'b0;end
        else if (alu_result_out == 32'h20 && mem_write_out) begin
            if (!sram_dn) stall = 1'b1;
            else stall = 1'b0;end
        else stall = 1'b0;
    end
        
endmodule
