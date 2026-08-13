`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.03.2026 12:22:33
// Design Name: 
// Module Name: apb_fifo_i2c_top
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

module apb_fifo_i2c_top (
    input           PCLK,
    input           PRESETn,
    input           PSELx,
    input           PWRITE,
    input           PENABLE,
    input  [31:0]   PADDR,
    input  [31:0]   PWDATA,
    output reg [31:0]   PRDATA,
    output reg          PREADY,
    output reg          PSLVERR,
    output wire          INT_RX_EMPTY,
    output wire          INT_RX_FULL,
    output wire          INT_TX_EMPTY,
    output wire          INT_TX_FULL,
    //input           i2c_clk,     // Connect as needed (can use PCLK)
    input           i2c_rst,
    //input  [6:0]    master_addr,
    input  [6:0]    slave_addr,
    input  [7:0]    slave_d_in,
    output [7:0]    slave_d_out,
    output reg sram_dn
);
wire tx_rd_dn,rx_wr_dn;
  reg i2c_start,i2c_stop,i2c_rdwr,tx_wr_dn,rx_rd_dn,i2c_reset;
  wire i2c_rst_in;
  wire [7:0] i2c_dout,i2c_din,rx_dout;
  reg [7:0] tx_din;
  wire rx_empty,rx_full,tx_empty,tx_full;
  reg sram_en,sram_we,sram_rd;
  reg [8:0] sram_addr;
  reg [31:0] sram_din;
  wire [31:0] sram_dout;
  initial sram_addr = 9'b000000000;
              
  assign i2c_rst_in = i2c_reset || i2c_rst;
  assign INT_RX_EMPTY = rx_empty;
  assign INT_RX_FULL = rx_full;
  assign INT_TX_EMPTY = tx_empty;
  assign INT_TX_FULL = rx_full;
  reg [6:0] master_addr;
  initial begin 
    i2c_start=0;
    i2c_stop=0;
    i2c_rdwr=0;
    tx_wr_dn=0;
    rx_rd_dn=0;
  end
  reg i2c_clk;
  initial i2c_clk = 0;
  reg div_counter;
  initial div_counter =0;
  wire FCLK;
  always @(posedge PCLK) begin
    if (div_counter==1)begin
      i2c_clk=~i2c_clk;
      div_counter=0;
    end else
      div_counter =div_counter+1;
    
  end
  //assign FCLK = (PADDR == 32'd4 || PADDR == 32'd16)?(i2c_clk):((PADDR == 32'd8 || PADDR == 32'd12)?PCLK:1'b0);
    assign FCLK = i2c_start?(i2c_clk):((rx_rd_dn || tx_wr_dn)?PCLK:1'b0);
    // APB control state
  always @(posedge PCLK or posedge PRESETn) begin
      rx_rd_dn       = 0;
      tx_wr_dn       =0;
    if (PRESETn==1)begin
    PRDATA=32'h00000000;
    PREADY=0;
    PSLVERR=0;
    i2c_reset = 1;
    i2c_start      = 0;
    i2c_stop       = 1;
    i2c_rdwr       = 0;
    rx_rd_dn       = 0;
    tx_wr_dn       =0;
    end
    else begin
      
        // Address 4: APB triggers I2C master READ
        if (PSELx && PENABLE && PWRITE && (PADDR == 32'd4)) begin
            i2c_start      = 1;
            i2c_stop       = 0;
            i2c_reset = 0;
            //i2c_rdwr       = 1;
            
           {master_addr,i2c_rdwr}=PWDATA[7:0];
           PREADY         = 1'b1;
          //assign FCLK = i2c_clk;
        end

        // Address 8: APB reads from RX FIFO
        else if (PSELx && PENABLE && !PWRITE && (PADDR == 32'd8)) begin
            i2c_start      = 0;
            i2c_stop       = 1;
            i2c_rdwr       = 1;
            PRDATA         = {24'd0, rx_dout};
            rx_rd_dn=1;
            PREADY         = 1'b1;
          //assign FCLK = PCLK;
        end

        // Address 12: APB writes to TX FIFO
        else if (PSELx && PENABLE && PWRITE && (PADDR == 32'd12)) begin
            i2c_start      = 0;
            i2c_stop       = 1;
            i2c_rdwr       = 1;
            tx_wr_dn       = 1;
            
            tx_din = PWDATA[7:0];
            PREADY         = 1'b1;
          //assign  FCLK = PCLK;
        end

        // Address 16: APB triggers I2C master WRITE
        else if (PSELx && PENABLE && PWRITE && (PADDR == 32'd16)) begin
            i2c_start      = 1;
            i2c_stop       = 0;
            i2c_reset = 0;
            //i2c_rdwr       = 0;
            PREADY         = 1'b1;
            tx_wr_dn       = 0;
            {master_addr,i2c_rdwr}=PWDATA[7:0];
            PREADY         = 1'b1;
          //assign FCLK = i2c_clk;
        end
        
        else if (PSELx && PENABLE && PWRITE && (PADDR == 32'h20)) begin
            sram_en = 1;
            sram_we = 1;
            sram_rd = 1;
            sram_addr = sram_addr+1'b1;
            sram_din = PWDATA;
            sram_dn = 1;
            end
            
      else begin
      i2c_reset = 1;
        i2c_start      = 0;
    i2c_stop       = 1;
    i2c_rdwr       = 0;
    PREADY         = 1'b0;
    end
    end
  end

    // RX FIFO: Store data received from I2C master
    sync_fifo #(.DEPTH(8), .DWIDTH(8)) rx_fifo (
        .rstn(PRESETn),
      .clk(FCLK),
      .wr_en(rx_wr_dn),
      .rd_en(rx_rd_dn),
        .din(i2c_dout),    // I2C data in
        .dout(rx_dout),    // APB can read
        .empty(rx_empty),
        .full(rx_full)
    );

    // TX FIFO: Store data to send through I2C master
    sync_fifo #(.DEPTH(8), .DWIDTH(8)) tx_fifo (
        .rstn(PRESETn),
      .clk(FCLK),
      .wr_en(tx_wr_dn),
      .rd_en(tx_rd_dn),
      .din(tx_din), // APB data in
        .dout(i2c_din),    // I2C master will send this
        .empty(tx_empty),
        .full(tx_full)
    );
  wire SCL;
  wire sda_master_out, sda_slave_out;
  wire sda_master_oe, sda_slave_oe;
  wire sda_in;
  wire sda_out_total;
  wire sda_oe_total;
  assign sda_out_total = sda_master_out & sda_slave_out;
  assign sda_oe_total  = sda_master_oe | sda_slave_oe;
  assign sda_in = (sda_oe_total) ? sda_out_total : 1'b1;


    // I2C master
    i2c_master i2c_master_u (
        .d_out(i2c_dout),
        .SCL(SCL),
      .wr_dn(rx_wr_dn),
      .rd_dn(tx_rd_dn),
      .SDA_OUT(sda_master_out),
      .en(sda_master_oe),
      .SDA(sda_in),
        .clk(i2c_clk),
        .rst(i2c_rst_in),
        .start(i2c_start),
        .stop(i2c_stop),
        .rd_wr(i2c_rdwr),
        .addr(master_addr),
        .d_in(i2c_din)
    );

    // I2C slave
    i2c_slave i2c_slave_u (
        .d_out(slave_d_out),
      .SDA_OUT(sda_slave_out),
      .en(sda_slave_oe),
      .SDA(sda_in),
        .SCL(SCL),
        .d_in(slave_d_in),
        .rst(i2c_rst),
        .stop(1'b0),
        .slave_add(slave_addr)
    );
    
    sram  #(.DATA_WIDTH(32),.ADDR_WIDTH(9)) sram_u
        (.clk(PCLK),
        .rst(PRESETn),
        .en(sram_en),
        .we(sram_we),
        .rd(sram_rd),
        .addr(sram_addr),
        .din(sram_din),
        .dout(sram_dout)
    );

endmodule
