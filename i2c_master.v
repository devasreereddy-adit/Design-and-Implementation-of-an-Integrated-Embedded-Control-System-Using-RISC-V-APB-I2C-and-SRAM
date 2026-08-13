`timescale 1ns / 1ps
module i2c_master( output reg [7:0] d_out,
                  output wire SCL,
                  output reg wr_dn,rd_dn,
                  output wire SDA_OUT,
                  output wire en,
                  input  SDA,
                  input clk,rst,start,stop,rd_wr,
                  input [6:0] addr,
                  input [7:0] d_in );
  
  parameter IDEAL=0;
  parameter START=1;
  parameter WR_ADDR=2;
  parameter WR_ADDR_ACK=3;
  parameter WR_DATA=4;
  parameter WR_DATA_ACK=5;
  parameter RD_DATA=6;
  parameter RD_DATA_ACK_1=7;
  parameter RD_DATA_ACK_0=8;
  parameter STOP=9;
  
  reg [4:0] STATE;
  reg [7:0] Tx_reg;
  reg [7:0] Rx_reg;
  reg scl_en,en1,en2;
  reg [3:0] counter;
  
  reg [1:0] div_counter;
  
  reg sda;
  wire scl;
  initial div_counter = 0;
  initial rd_dn = 0;
  initial wr_dn = 0;
  initial d_out = 8'b00000000;
  assign en = en1 || en2;
  assign SDA_OUT=(en==1)?sda:1'b1;
  assign SCL=(scl_en==0)?1'b1:scl;
  
  always @(posedge scl or posedge rst)begin
    
    if(rst)begin
      en1=0; STATE=IDEAL;
      rd_dn = 0;
      wr_dn = 0;
    end
    else begin
      case(STATE)
        IDEAL: begin
          en1=0;
          rd_dn=0;
          wr_dn=0;
          if(start) begin
            en1=0;
            //sda = 0;
            STATE=START;
            Tx_reg={addr,rd_wr};
          end
          else STATE = IDEAL;
        end
        START: begin
          en1=1;
          counter=0;
          STATE = WR_ADDR;
        end
        
        WR_ADDR:begin
          en1=0;
          counter=counter+1;
          if(counter==4'b1000)begin 
            STATE=WR_ADDR_ACK;
            if(Tx_reg[0]==0) rd_dn=1;
            else rd_dn=0;
          end
          else STATE=WR_ADDR;
        end
        
        WR_ADDR_ACK:begin
          rd_dn=0;
          //en=0;
          if(SDA==0 ) begin
            if(Tx_reg[0]==0) begin
              STATE=WR_DATA;
              Tx_reg=d_in;
              counter=0;
            end
            else begin
              //en=0;
              STATE = RD_DATA;
              counter=0;
              Rx_reg=8'b00000000;
            end
          end
          else STATE=STOP;
        end
        
        WR_DATA:begin
          //en=1;
          counter=counter+1;
          rd_dn=0;
          if(counter==4'b1000)STATE=WR_DATA_ACK;
          else STATE=WR_DATA;
        end
        
        WR_DATA_ACK:begin
          //en=0;
          if(!SDA ) begin
            if(stop) begin
              STATE=STOP;
            end
            else begin
              STATE=WR_DATA;
              Tx_reg=d_in;
              rd_dn=1;
              counter=0;
            end
          end
          else STATE=STOP;
        end
        RD_DATA:begin
          //en=0;
          Rx_reg[counter]=SDA;
          counter=counter+1;
          if(counter==8'b1000)begin
            d_out=Rx_reg;
            wr_dn=1;
            if(stop)STATE=RD_DATA_ACK_1;
            else STATE=RD_DATA_ACK_0;
          end
          else
            STATE=RD_DATA;
        end
        
        RD_DATA_ACK_1:begin
          //en=1;
          STATE = STOP;
          wr_dn=0;
        end
        
        RD_DATA_ACK_0:begin
          //en=1;
          STATE = RD_DATA;
          counter = 0;
          wr_dn=0;
        end
        
        STOP:begin
          STATE=IDEAL;
          //en=1;
          //sda=1;
        end
        default: STATE=IDEAL;
      endcase
    end

    
    
  end
/*  always @(posedge clk) begin
    if (div_counter==3)begin
      scl=~scl;
      div_counter=0;
    end else
      div_counter+=1;
    
  end*/
  assign scl=clk;
  
  always @(negedge scl) begin
      case(STATE)
        IDEAL: begin
          en2 = 0;
          scl_en = 0;
        end
        START: begin
          en2=0;
          sda=0;
          //Tx_reg={addr,rd_wr};
          scl_en = 0;
        end
        
        WR_ADDR:begin
          en2=1;
          sda=Tx_reg[counter];
          scl_en = 1;
        end
        
        WR_ADDR_ACK:begin
          en2=0;
          scl_en = 1;
        end
        
        WR_DATA:begin 
          en2=1;
          sda=Tx_reg[counter];
          scl_en = 1;
        end
        
        WR_DATA_ACK:begin
          scl_en = 1;
          en2=0;
        end
        
        RD_DATA:begin
          en2=0;
          scl_en = 1;
        end
        
        RD_DATA_ACK_1:begin
          en2=1;
          sda=1;
        end
        
        RD_DATA_ACK_0:begin
          en2=1;
          sda=0;
        end
        STOP:begin
          en2=1;
          sda=0;
          scl_en = 1;
        end
        default: begin
          en2 = 0;
          scl_en = 0;
        end
    endcase
  end
endmodule

