`timescale 1ns / 1ps
module sync_fifo #(parameter DEPTH=8, DWIDTH=8)
(
        input               	rstn,               // Active low reset
                            	clk,                // Clock
                            	wr_en, 				// Write enable
                            	rd_en, 				// Read enable
        input      [DWIDTH-1:0] din, 				// Data written into FIFO
        output reg [DWIDTH-1:0] dout, 				// Data read from FIFO
        output              	empty, 				// FIFO is empty when high
                            	full 				// FIFO is full when high
);


initial dout =0;
  reg [$clog2(DEPTH)-1:0]   wptr;
  reg [$clog2(DEPTH)-1:0]   rptr;
  
  reg [$clog2(DEPTH):0]   ptr;

  reg [DWIDTH-1 : 0]    fifo[DEPTH-1:0];

  always @ (negedge clk) begin
    if (rstn) begin
      wptr <= 0;
      rptr <= 0;
      ptr<=0;
    end 
    else begin
      if (wr_en & !full) begin
        fifo[wptr] <= din;
        wptr <= wptr + 1;
        ptr<=ptr+1;
      end
      else if (rd_en & !empty) begin
              dout <= fifo[rptr];
              rptr <= rptr + 1;
              ptr <=ptr-1;
       end
    end
  end

  initial begin
    $monitor("[%0t] [FIFO] wr_en=%0b din=0x%0h rd_en=%0b dout=0x%0h empty=%0b full=%0b",
             $time, wr_en, din, rd_en, dout, empty, full);
  end


  assign full  = (ptr == DEPTH)?1'b1:1'b0;
  assign empty = (ptr == 0)?1'b1:1'b0;
endmodule

