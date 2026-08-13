`timescale 1ns / 1ps
module i2c_slave(
  output reg[7:0] d_out,
  output wire SDA_OUT,
  output reg en,
  input SDA,
  input SCL,
  input [7:0]d_in,
  input rst,stop,
  input [6:0]slave_add);
  
  parameter IDEAL=0;
  parameter START=1;
  parameter RD_ADDR=2;
  parameter RD_ADDR_ACK=3;
  parameter WR_DATA=4;
  parameter WR_DATA_ACK=5;
  parameter RD_DATA=6;
  parameter RD_DATA_ACK_1=7;
  parameter RD_DATA_ACK_0=8;
  
  reg [3:0] STATE;
  reg [7:0] Tx_reg;
  reg [7:0] Rx_reg;
  reg [3:0] counter_rd;
  reg [3:0] counter_wr;
  reg ack;
  
  reg sda,st,sp;
  assign SDA_OUT=(en==1)?sda:1'b1;
  initial begin d_out = 8'b00000000;st=0;sp=1;ack =0;en=0;end
  
  wire stop_rst;
  assign stop_rst = rst|st;
  always@(posedge SDA or posedge stop_rst)begin
    if (stop_rst ==1||st==1) sp = 0;
    else begin
    if (SCL==1 || rst==1) sp=1;
    else sp = 0;
    end
  end
  reg st_rst;
  wire start_rst;
  assign start_rst = rst | st_rst;
  always @(negedge SDA or posedge start_rst) begin
    if (start_rst) st = 0;
    else begin
      if (SCL==1) begin st = 1;end
    else st = 0;
    end
  end
  always @(posedge SCL) begin
    if (rst) st_rst = 0;
    else st_rst = st;
  end
  always@(negedge SCL or posedge rst)begin
        if(rst)begin
      		//en=0; 
          STATE=IDEAL;
    	end
    else if (st) begin 
      STATE = RD_ADDR;
      counter_rd = 0;
    end
    else if (sp) STATE = IDEAL;
    	else begin
      		case(STATE)
              //IDEAL: begin
                //en=0;
              	//if (SDA==0) STATE = START;
              	//else STATE = IDEAL;
              //end
              //START:begin
                //en=0;
                //counter = 0;
                //STATE = RD_ADDR;
              //end
              RD_ADDR:begin
                //en=0;
                //Rx_reg[counter]=SDA;
                //counter=counter+1;
                if(counter_rd==4'b0111)begin
                  if (Rx_reg[7:1]==slave_add) begin
                  STATE=RD_ADDR_ACK;
                    en=1;
                    sda=0;
                  end
                  else begin STATE=IDEAL; en = 0; end
                end
          		else begin STATE=RD_ADDR;counter_rd=counter_rd+1; end
              end
              RD_ADDR_ACK:begin
                //en=1;
                if (Rx_reg[0]==1'b1) begin
                  STATE = WR_DATA;
                  en=1;
                  //counter = 0;
                  sda=Tx_reg[counter_wr];
                end
                else if(Rx_reg[0]==1'b0) begin
                  STATE = RD_DATA;
                  en=0;
                  counter_rd=0;
                  //Rx_reg=8'b00000000;
                end
              end
              WR_DATA:begin
                //en = 1;
                //counter=counter+1;
                if(counter_wr==4'b1000)begin
                  STATE=WR_DATA_ACK;
                  en=0;
                end
          		else begin
                  en = 1;
                  STATE=WR_DATA;
                  sda=Tx_reg[counter_wr];
                end
              end
              WR_DATA_ACK:begin
                en=0;
                if (ack ==1'b1) STATE=IDEAL;
                else begin
                  STATE = WR_DATA;
                  //Tx_reg=d_in;
                  //counter=0;
                  en=1;
                  sda=Tx_reg[counter_wr];
                end
              end
              RD_DATA:begin
                //en=0;
          		//counter=counter+1;
                if(counter_rd==8'b0111)begin
                  //d_out=Rx_reg;
                  if(stop)begin
                    STATE=RD_DATA_ACK_1;
                    en=1;
                    sda=1;
                  end
            		else begin
                      STATE=RD_DATA_ACK_0;
                      en=1;
                      sda=0;
                    end
          		end
          		else begin
            		STATE=RD_DATA;
                  counter_rd = counter_rd+1;
                end
              end
              RD_DATA_ACK_1:begin
          		STATE = IDEAL;
                en=0;
        	  end
        
        	  RD_DATA_ACK_0:begin
          		STATE = RD_DATA;
                en=0;
                counter_rd = 0;
                //Rx_reg=8'b00000000;
              end
              
              
              default: STATE=IDEAL;
            endcase
        end
  end
  always@(posedge SCL)begin
    case(STATE)
        IDEAL: begin
          //en = 0;
          Rx_reg=8'b00000000;
        end
        START: begin
          //en=0;
          Rx_reg=8'b00000000;
        end
        
        RD_ADDR:begin
          //en=0;
          //counter=counter+1;
          Rx_reg[counter_rd]=SDA;
        end
        
        RD_ADDR_ACK:begin
          //en=1;
          //sda = 0;
          //Tx_reg = d_in;
          if (Rx_reg[0]==1'b1) begin
                  //STATE = WR_DATA;
                  //en=1;
                  counter_wr = 0;
                  Tx_reg = d_in;
                  //sda=Tx_reg[counter];
                end
                else if(Rx_reg[0]==1'b0) begin
                  //STATE = RD_DATA;
                  //en=0;
                  //counter=0;
                  Rx_reg=8'b00000000;
                end
        end
        
        WR_DATA:begin 
          //en=1;
          counter_wr = counter_wr+1;
        end
        
        WR_DATA_ACK:begin
          //en=0;
          if (!SDA) begin Tx_reg=d_in;counter_wr=0;ack = SDA; end
          else ack = SDA;
        end
        
        RD_DATA:begin
          //en=0;
          Rx_reg[counter_rd]=SDA;
        end
        
        RD_DATA_ACK_1:begin
          //en=1;
          //sda=1;
          //STATE=IDEAL;
          d_out=Rx_reg;
        end
        
        RD_DATA_ACK_0:begin
          //en=1;
          //sda=0;
          d_out=Rx_reg;
          //counter_rd = 0;
          Rx_reg=8'b00000000;
        end

        default: begin 
          Rx_reg = 8'b00000000;
          Tx_reg = 8'b00000000;
          d_out = 8'b00000000;
        end
    endcase
  end
endmodule
