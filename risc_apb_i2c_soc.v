`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.03.2026 12:57:14
// Design Name: 
// Module Name: risc_apb_i2c_soc
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


module riscv_apb_i2c_soc (
    input  wire        clk,
    input  wire        reset,
    
    // I2C Physical Interface (Simplified)
    input  wire [6:0]  slave_addr,
    input  wire [7:0]  slave_d_in,
    output wire [7:0]  slave_d_out,
    output wire        int_rx_empty,
    output wire        int_rx_full,
    output wire        alert
);

    // --- Internal Interconnect Wires ---
    
    // Fetch Stage
    wire [31:0] pc_f, pc_plus4_f, inst_f;
    wire [31:0] pc_target_e; // From Execute
    wire        pc_sel_e;    // From Execute (Branch/Jump logic)

    // IF/ID Register
    wire [31:0] instr_d, pc_d, pc_plus4_d;

    // Decode Stage
    wire [31:0] rd1_d, rd2_d, imm_d, inst_d_unused;
    wire [3:0]  alu_ctrl_d;
    wire [4:0]  rs1_d, rs2_d, rd_d;
    wire        reg_wr_d, mem_wr_d, alu_src_d, mem_to_reg_d, branch_d, jump_d, ld_st_d;
    wire reg_wirte_mode_d;

    // ID/EX Register
    wire [31:0] pc_e, rd1_e, rd2_e, imm_e;
    wire [4:0]  rs1_e, rs2_e, rd_e;
    wire [3:0]  alu_ctrl_e;
    wire        reg_wr_e, mem_wr_e, alu_src_e, mem_to_reg_e, branch_e, jump_e, ld_st_e;
    wire reg_write_mode_out_e;

    // Execute Stage
    wire [31:0] alu_res_e;
    wire        zero_e;

    // EX/MEM Register
    wire [31:0] alu_res_m, write_data_m;
    wire [4:0]  rd_m;
    wire        reg_wr_m, mem_wr_m, mem_to_reg_m, ld_st_m;
    wire reg_write_mode_out_wb;

    // Memory Stage & APB Interface
    wire [31:0] read_data_m;
    wire        stall_m;
    wire        pready_s, pslverr_s;
    wire [31:0] prdata_s;
    wire reg_wr_m_out; wire mem_to_reg_m_out;
    wire mem_wr_m_out; wire [31:0]alu_res_m_out;wire [31:0]write_data_m_out;
    wire [4:0]rd_m_out; wire ld_st_m_out;
    wire sram_dn_m;
    
    //Memory/Writeback stage
    
    // Writeback Stage
    wire [31:0] alu_res_wb, read_data_wb, result_wb;
    wire [4:0]  rd_wb;
    wire        reg_wr_wb, mem_to_reg_wb;
    wire reg_wr_en_final;
    wire [4:0] rd_addr_final;
    wire reg_write_mode_wb_final;

    // -------------------------------------------------------------------------
    // 1. FETCH STAGE
    // -------------------------------------------------------------------------
    fetch_stage F_UNIT (
        .clk(clk), .reset(reset), .stall_f(stall_m), // Stall if APB is busy
        .PCSel(pc_sel_e), .PCTarget(pc_target_e),
        .PC(pc_f), .PCPlus4(pc_plus4_f), .inst_f(inst_f)
    );

    if_id_reg F_D_REG (
        .clk(clk), .reset(reset), .stall_d(stall_m), .en(1'b1), .clear(pc_sel_e),
        .instr_in(inst_f), .pc_in(pc_f), .pc_plus4_in(pc_plus4_f),
        .instr_out(instr_d), .pc_out(pc_d), .pc_plus4_out(pc_plus4_d)
    );

    // -------------------------------------------------------------------------
    // 2. DECODE STAGE
    // -------------------------------------------------------------------------
    decode_stage D_UNIT (
        .clk(clk), .instr(instr_d), .wd_wb(result_wb), .rd_wb(rd_addr_final), .reg_write_wb(reg_wr_en_final),
        .rd1(rd1_d), .rd2(rd2_d), .imm(imm_d), .alu_control_out(alu_ctrl_d), .inst(inst_d_unused),
        .rs1(rs1_d), .rs2(rs2_d), .rd(rd_d), .reg_write(reg_wr_d), .mem_write(mem_wr_d),
        .alu_src(alu_src_d), .mem_to_reg(mem_to_reg_d), .branch(branch_d), .jump(jump_d), .ld_st(ld_st_d),.reg_wirte_mode(reg_wirte_mode_d)
    );

    id_ex_reg D_E_REG (
        .clk(clk), .reset(reset), .stall_e(stall_m), .flush(pc_sel_e),
        .pc_in(pc_d), .rd1_in(rd1_d), .rd2_in(rd2_d), .imm_in(imm_d), .rs1_in(rs1_d), .rs2_in(rs2_d), .rd_in(rd_d),
        .alu_control_in(alu_ctrl_d), .reg_write_in(reg_wr_d), .mem_write_in(mem_wr_d), .alu_src_in(alu_src_d),
        .mem_to_reg_in(mem_to_reg_d), .branch_in(branch_d), .jump_in(jump_d), .ld_st_in(ld_st_d),.reg_write_mode_in(reg_wirte_mode_d),
        .pc_out(pc_e), .rd1_out(rd1_e), .rd2_out(rd2_e), .imm_out(imm_e), .rs1_out(rs1_e), .rs2_out(rs2_e), .rd_out(rd_e),
        .alu_control_out(alu_ctrl_e), .reg_write_out(reg_wr_e), .mem_write_out(mem_wr_e), .alu_src_out(alu_src_e),
        .mem_to_reg_out(mem_to_reg_e), .branch_out(branch_e), .jump_out(jump_e), .ld_st_out(ld_st_e),.reg_write_mode_out(reg_write_mode_out_e)
    );

    // -------------------------------------------------------------------------
    // 3. EXECUTE STAGE
    // -------------------------------------------------------------------------
    execute_stage E_UNIT (
        .pc_ex(pc_e), .rd1_ex(rd1_e), .rd2_ex(rd2_e), .imm_ex(imm_e),
        .alu_control_ex(alu_ctrl_e), .alu_src_ex(alu_src_e),
        .alu_result(alu_res_e), .pc_target(pc_target_e), .zero_flag(zero_e)
    );

    assign pc_sel_e = (branch_e & zero_e) | jump_e;

    ex_mem_reg E_M_REG (
        .clk(clk), .reset(reset), .stall_m(stall_m),
        .reg_write_in(reg_wr_e), .mem_to_reg_in(mem_to_reg_e), .mem_write_in(mem_wr_e), .ld_st_in(ld_st_e),
        .alu_result_in(alu_res_e), .rd2_ex_in(rd2_e), .rd_in(rd_e),.reg_write_mode_in(reg_write_mode_out_e),
        .reg_write_out(reg_wr_m), .mem_to_reg_out(mem_to_reg_m), .mem_write_out(mem_wr_m), .ld_st_out(ld_st_m),
        .alu_result_out(alu_res_m), .write_data_out(write_data_m), .rd_out(rd_m),.reg_write_mode_out(reg_write_mode_out_wb)
    );

    // -------------------------------------------------------------------------
    // 4. MEMORY STAGE & APB BRIDGE LOGIC
    // -------------------------------------------------------------------------
    
    // APB Bridge FSM (To handle PENABLE)
    reg apb_enable;
    always @(posedge clk or posedge reset) begin
        if (reset) apb_enable <= 1'b0;
        else if ((mem_wr_m || mem_to_reg_m) && !apb_enable) apb_enable <= 1'b1;
        else if (pready_s) apb_enable <= 1'b0;
        else begin apb_enable <= 1'b0; end
    end

    memory_stage M_UNIT (
        .reg_write_out(reg_wr_m), .mem_to_reg_out(mem_to_reg_m), .mem_write_out(mem_wr_m),
        .alu_result_out(alu_res_m), .write_data_out(write_data_m), .rd_out(rd_m),
        .ld_st_out(ld_st_m), .PREADY(pready_s),.sram_dn(sram_dn_m),.int_rx_full(int_rx_full),
        // APB Outputs generated from Mem inputs
        .stall(stall_m), .reg_write_out_m(reg_wr_m_out), .mem_to_reg_out_m(mem_to_reg_m_out),
        .mem_write_out_m(mem_wr_m_out), .alu_result_out_m(alu_res_m_out), .write_data_out_m(write_data_m_out),
        .rd_out_m(rd_m_out), .ld_st_out_m(ld_st_m_out)
    );
    assign alert = (alu_res_m==32'h20&& mem_wr_m)?write_data_m[31]:1'bz;
    // -------------------------------------------------------------------------
    // 5. APB I2C PERIPHERAL
    // -------------------------------------------------------------------------
    apb_fifo_i2c_top I2C_PERIPHERAL (
        .PCLK(clk), .PRESETn(reset),
        .PSELx((mem_wr_m || mem_to_reg_m)&&(reg_write_mode_out_wb)), // Select if either Store or Load
        .PWRITE(mem_wr_m),
        //.PENABLE(apb_enable),
        .PENABLE((mem_wr_m || mem_to_reg_m)&&(reg_write_mode_out_wb)),
        .PADDR(alu_res_m),
        .PWDATA(write_data_m),
        .PRDATA(prdata_s),
        .PREADY(pready_s),
        .PSLVERR(pslverr_s),
        .INT_RX_EMPTY(int_rx_empty), .INT_RX_FULL(int_rx_full),
        .i2c_rst(reset), .slave_addr(slave_addr),
        .slave_d_in(slave_d_in), .slave_d_out(slave_d_out),
        .sram_dn(sram_dn_m)
    );

    // -------------------------------------------------------------------------
    // 6. WRITEBACK STAGE
    // -------------------------------------------------------------------------
    mem_wb_reg M_W_REG (
        .clk(clk), .rst(reset),
        .reg_write_out_m(reg_wr_m_out), .mem_to_reg_out_m(mem_to_reg_m_out),
        .alu_result_out_m(alu_res_m_out), .read_data_m(prdata_s), .rd_out_m(rd_m_out),.reg_write_mode_m(reg_write_mode_out_wb),
        .reg_write_wb(reg_wr_wb), .mem_to_reg_wb(mem_to_reg_wb),
        .alu_result_wb(alu_res_wb), .read_data_wb(read_data_wb), .rd_wb(rd_wb), .reg_write_mode_wb(reg_write_mode_wb_final)
    );
    
    

    writeback_stage W_UNIT (
        .reg_write_wb(reg_wr_wb), .mem_to_reg_wb(mem_to_reg_wb),
        .alu_result_wb(alu_res_wb), 
        //.read_data_wb(read_data_wb),
        .read_data_wb(prdata_s), 
        .rd_wb(rd_wb),.reg_write_mode_wb(reg_write_mode_wb_final),
        .result_wb(result_wb), .reg_write_en(reg_wr_en_final), .rd_addr(rd_addr_final)
    );

endmodule

