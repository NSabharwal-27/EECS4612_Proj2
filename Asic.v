//---------------------------------------------------------
//  File:   Asic.v
//  Author: Abel Beyene
//  Date:   March 6, 2023
//
//  Description:
//
//  Top-level module for matrix-vector multiplier
//  
//  Interface:  
//  
//  Name                    I/O     Width     Description
//  -------------------------------------------------------
//  clk                     input   1         clock
//  rst                     input   1         reset
//  cmd_ready_o             output  1         control
//  cmd_valid_i             input   1         control
//  cmd_inst_funct_i        input   7         function code
//  cmd_inst_rs2_i          input   5         rs2 register
//  cmd_inst_rs1_i          input   5         rs1 register
//  cmd_inst_xd_i           input   1         valid rd
//  cmd_inst_xrs1_i         input   1         valid rs2
//  cmd_inst_xrs2_i         input   1         valid rs1
//  cmd_inst_rd_i           input   5         rd register
//  cmd_inst_opcode_i       input   7         opcode
//  cmd_rs1_i               input   64        rs1 data
//  mem_req_ready_o         input   128       control
//  mem_req_valid_i         input   1         control
//  mem_req_addr_i          output  32        memory address
//  mem_req_cmd_i           output  5         memory operation
//  mem_req_typ_i           output  3         operation size
//  mem_req_data_i          output  64        operation data
//  mem_resp_ready_i        input   128       control
//  mem_resp_valid_o        output  1         control
//  mem_resp_addr_o         output  32        memory address 
//  mem_resp_cmd_o          output  5         memory operation
//  mem_resp_typ_o          output  3         operation size
//  mem_resp_data_o         output  64        operation data
//---------------------------------------------------------

`include "AsicDefines.vh"

module Asic
(
  input         logic             clk,
  input         logic             reset,

  // PROC CMD Interface
                                
  output	logic             cmd_ready_o,
  input		logic       	    cmd_valid_i,
  input		logic [6:0]       cmd_inst_funct_i,
  input		logic [4:0]       cmd_inst_rs2_i,
  input		logic [4:0]       cmd_inst_rs1_i,
  input		logic        	    cmd_inst_xd_i,
  input		logic        	    cmd_inst_xs1_i,
  input		logic        	    cmd_inst_xs2_i,
  input		logic [4:0]       cmd_inst_rd_i,
  input		logic [6:0]       cmd_inst_opcode_i,
  input		logic [`XLEN-1:0] cmd_rs1_i,

  // PROC RESP Interface

  input		logic        	    resp_ready_i,
  output	logic        	    resp_valid_o,
  output	logic [4:0]       resp_rd_o,
  output	logic [`XLEN-1:0] resp_data_o,

  // MEM REQ Interface

  input  	logic       	    mem_req_ready_i,
  output 	logic       	    mem_req_valid_o,
  output 	logic [39:0]      mem_req_addr_o,
  output 	logic [4:0]	      mem_req_cmd_o,
  output 	logic [2:0]       mem_req_typ_o,
  output 	logic [`XLEN-1:0] mem_req_data_o,

  // MEM RESP Interface

  input 	logic        	    mem_resp_valid_i,
  input 	logic [39:0]      mem_resp_addr_i,
  input 	logic [4:0]       mem_resp_cmd_i,
  input 	logic [2:0]       mem_resp_typ_i,
  input 	logic [`XLEN-1:0] mem_resp_data_i
);
//cmd states
localparam cmd_idle     = 7'b000_0000;
localparam cmd_initiate = 7'b000_0001; //0x1
localparam cmd_size     = 7'b000_0010; //0x2
localparam cmd_addrW    = 7'b000_0100; //0x4
localparam cmd_addrX    = 7'b000_0110; //0x6
localparam cmd_addrR    = 7'b000_1000; //0x8


//load states
localparam load_idle    = 3'b000;
localparam load_w       = 3'b001;
localparam load_x       = 3'b010;
localparam load_R       = 3'b011;
localparam store_R      = 3'b100;

//cmd_initiate settings
localparam y_prime_8    = 7'b000_0000; //8-b wide
localparam z_8          = 7'b000_0010; //8-b wide

logic [6:0] settings = 7'b111_1111;
logic [6:0] state    = cmd_idle;
logic [2:0] funct    = 3'b111;

logic [15:0] m_size;    //gets the size of M
logic [15:0] n_size;    //gets the size of N

logic [31:0] addrW;     //holds the starting value of W
logic [31:0] addrX;     //holds the starting value of X
logic [31:0] addrR;     //holds the starting value of R

logic [63:0]      W;
logic [63:0]      x;
logic [63:0]      R;

//cmd_inf
always @(posedge clk) begin
  if(~reset) begin
    cmd_ready_o = 1;
  end
  case(state)
    default cmd_ready_o = 0;
    cmd_idle : begin
                    cmd_ready_o = 1;
                    if(cmd_valid_i && cmd_inst_funct_i == cmd_initiate) begin
                      settings = cmd_inst_opcode_i;
                      state = cmd_size;
                    end
    end
    cmd_size : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_size) begin
                  m_size = cmd_rs1_i[15:0];
                  n_size = cmd_rs1_i[31:16];                
                  state = cmd_addrW;
                end
    end
    cmd_addrW : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_addrW) begin
                  addrW = cmd_rs1_i;
                  state = cmd_addrX;
                end
    end
    cmd_addrX : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_addrX) begin
                  addrX = cmd_rs1_i;
                  state = cmd_addrR;
                end
    end 
    cmd_addrR : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_addrR) begin
                  addrR = cmd_rs1_i;
                  funct = load_idle;
                  state = cmd_idle;
                end
    end
  endcase
end


always @(posedge clk)begin
  if(~reset) begin
    mem_req_valid_o = 0;
  end
  case(funct)
    default mem_req_valid_o = 0;
    load_idle : begin
                mem_req_valid_o = 1;
                mem_req_cmd_o = 0;
              if(mem_req_ready_i && mem_req_valid_o) begin
                case(m_size)
                  16'b0000000001000000 : mem_req_typ_o = 3;
                  16'b0000000000100000 : mem_req_typ_o = 2;
                  16'b0000000000010000 : mem_req_typ_o = 1;
                  default mem_req_typ_o = 0;
                endcase
                //mem_req_typ_o = 0; 
                mem_req_addr_o = addrX; 
              end
              if(mem_resp_valid_i) begin
                mem_req_valid_o = 0;
                x = mem_resp_data_i;
                funct = load_w;
              end
    end
    load_w : begin
              mem_req_valid_o = 1;
              mem_req_cmd_o = 0;
              if(mem_req_ready_i && mem_req_valid_o) begin
                case(n_size)
                  16'b0000000001000000 : mem_req_typ_o = 3;
                  16'b0000000000100000 : mem_req_typ_o = 2;
                  16'b0000000000010000 : mem_req_typ_o = 1;
                  default mem_req_typ_o = 0;
                endcase
                //mem_req_typ_o = 0; //once again different sizes need to figure out how.
                mem_req_addr_o = addrW;
              end
              if(mem_resp_valid_i) begin
                mem_req_valid_o = 0;
                W = mem_resp_data_i;
                funct = load_R;
              end
    end
    load_R : begin
              R = W*x; 
              funct = store_R;
    end
    store_R : begin
              
    end
  endcase
end
endmodule
