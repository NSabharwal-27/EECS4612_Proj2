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

// //cmd states
localparam cmd_idle_opcode     = 7'b000_0000;
localparam cmd_initiate_opcode = 7'b000_0001; //0x1
localparam cmd_size_opcode     = 7'b000_0010; //0x2
localparam cmd_addrW_opcode    = 7'b000_0100; //0x4
localparam cmd_addrX_opcode    = 7'b000_0110; //0x6
localparam cmd_addrR_opcode    = 7'b000_1000; //0x8

//load states
localparam request_X_opcode    = 7'b000_0011;
localparam reques_opcode       = 7'b000_0101;
localparam load_x_opcode       = 7'b000_0111;
localparam compute_opcode      = 7'b000_1001;
localparam store_R_opcode      = 7'b000_1011;
localparam resp_out_opcode     = 7'b100_1111;
localparam load_vector_opcode  = 7'b101_1010;


//cmd_initiate settings
localparam y_prime_8    = 7'b000_0000; //8-b wide
localparam z_8          = 7'b000_0010; //8-b wide

logic [6:0] settings = 7'b111_1111;

logic [15:0] m_size;    //gets the size of M
logic [15:0] n_size;    //gets the size of N
logic [15:0] a;
logic [15:0] k;
logic [7:0] subword;
logic [2:0]  k_prime;

logic [31:0] addrW;     //holds the starting value of W
logic [31:0] addrX;     //holds the starting value of X
logic [31:0] addrR;     //holds the starting value of R
logic       r_flag;
logic [7:0]   data;

logic [63:0]   W;
logic [63:0]   W_temp;
logic [63:0]   vector_x[0:`XLEN-1][0:0];

logic [6:0]      m_count;
logic [6:0]      n_count;
logic [6:0]            i;
logic [6:0]            j;
logic [6:0]       i_temp;

//setting the states
typedef enum logic [7:0] {cmd_idle,
                          cmd_size, 
                          cmd_addrW, 
                          cmd_addrX, 
                          cmd_addrR, 
                          request_X, 
                          load_vector, 
                          request_W, 
                          compute,
                          SWS,
                          ReLU, 
                          store_R, 
                          resp_out} state_t;

//State Transition: Current State, Next State
state_t state, state_n;

//Memory and Registers
always @(posedge clk) begin
    if (~reset)
        state <= cmd_idle; //set state to idle if we reset, otherwise
    else 
        state <= state_n; //set state to the next state
end

always @(posedge clk) begin
  if(~reset) begin
    n_count <= 0; //counting the columns
    i <= 0; //indexing the array at which we are storing
    i_temp <= 0; 
    addrX <= 8'b0; //incrementing the address
    m_count <= 0;
    k_prime <= 0;
    a <= 0;
    subword <= 0;
    k <= 0;
    j <= 0;
    W <= 0;
    data <= 0;
    r_flag <= 0;
  end
  else begin
    if (state == cmd_idle) begin
      a <= cmd_rs1_i[15:0];
      k <= cmd_rs1_i[31:16];
      k_prime <= cmd_rs1_i[18:16];
      settings <= cmd_inst_opcode_i;
    end
    if (state == cmd_size) begin
      m_size <= cmd_rs1_i[15:0];
      n_size <= cmd_rs1_i[31:16];
    end
    if (state == cmd_addrW) begin
      addrW <= cmd_rs1_i;
    end
    if (state == cmd_addrX) begin
      addrX <= cmd_rs1_i;
    end
    if (state == cmd_addrR) begin
      addrR <= cmd_rs1_i;
    end
    if (state == request_X) begin
      if(n_count <= n_size) 
        n_count <= n_count + 1; //counting the columns
      else
        n_count <= 0;
      if(n_count != 0) begin
        i <= i + 1; //indexing the array at which we are storing
        i_temp <= i_temp + 8; 
      end
      addrX <= addrX + 4'b1000;//incrementing the address
    end
    if(state == load_vector) begin 
      if(n_count > n_size)
        n_count <= 0;
      vector_x[i][0] <= {{57{mem_resp_data_i[7]}}, mem_resp_data_i[6:0]};
    end 
    if(state == compute) begin
      if(n_count <= n_size && m_count < m_size && mem_resp_valid_i) begin
        W <= W + {{57{mem_resp_data_i[7]}}, mem_resp_data_i[6:0]} * vector_x[j][0];
        n_count <= n_count + 1;
        j <= j + 1;
        addrW <= addrW + 8'b1000;
      end
      else if (m_count == m_size) begin
        m_count <= 0;
        W <= 0;
        j <= 0;
        n_count <= 0;
      end
      else if(n_count == n_size) begin
        n_count <= 0;
        j <= 0;
        W_temp <= W; 
      end
    end
    if(state == SWS) begin
        case (a)
            16'd0:  subword <= W_temp[8:0];
            16'd1:  subword <= W_temp[9:1];
            16'd2:  subword <= W_temp[10:2];
            16'd3:  subword <= W_temp[10:3];
            16'd4:  subword <= W_temp[11:4];
            16'd5:  subword <= W_temp[12:5];
            16'd6:  subword <= W_temp[13:6];
            16'd7:  subword <= W_temp[14:7];
            16'd8:  subword <= W_temp[15:8];
            16'd9:  subword <= W_temp[16:9];
            16'd10: subword <= W_temp[17:10];
            16'd11: subword <= W_temp[18:11];
            16'd12: subword <= W_temp[19:12];
            16'd13: subword <= W_temp[20:13];
            16'd14: subword <= W_temp[21:14];
            16'd15: subword <= W_temp[22:15];
            16'd16: subword <= W_temp[23:16];
            16'd17: subword <= W_temp[24:17];
            16'd18: subword <= W_temp[25:18];
            16'd19: subword <= W_temp[26:19];
            16'd20: subword <= W_temp[27:20];
            16'd21: subword <= W_temp[28:21];
            16'd22: subword <= W_temp[29:22];
            16'd23: subword <= W_temp[30:23];
            16'd24: subword <= W_temp[31:24];
        endcase
    end
    if(state == ReLU) begin
      if(subword[7] == 1'b1)
        subword <= 8'd0; 
    end
    if (state == store_R) begin
      if(mem_req_ready_i && mem_req_valid_o) begin
        r_flag <= 1;
      end
      if(mem_resp_valid_i && r_flag) begin
        r_flag <= 0;
          addrR <= addrR + 8'b1000;
          m_count <= m_count + 1;
          if(state_n == request_W) begin
            W <= 0;
            subword <= 0;
          end 
      end
    end 
  end
end

always @(*) begin
  case(state)
    default begin
        cmd_ready_o = 1;
        mem_req_valid_o = 0;
        resp_valid_o = 0;
        resp_data_o = 0;
        resp_rd_o = 0;
    end
    cmd_idle : begin
                    state_n = cmd_idle; 
                    if(cmd_valid_i && cmd_inst_funct_i == cmd_initiate_opcode) begin
                      state_n = cmd_size;
                    end      
    end
    cmd_size : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_size_opcode) begin
                  state_n = cmd_addrW;
                end
    end
    cmd_addrW : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_addrW_opcode) begin
                  state_n = cmd_addrX;
                end
    end
    cmd_addrX : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_addrX_opcode) begin
                  state_n = cmd_addrR;
                end
    end 
    cmd_addrR : begin
                if(cmd_valid_i && cmd_inst_funct_i == cmd_addrR_opcode) begin
                  state_n = request_X;
                end
    end
    request_X : begin
                mem_req_valid_o = 1;
                mem_req_cmd_o = 0;
                mem_req_typ_o = 0;
                mem_req_addr_o = addrX;
              if(mem_req_ready_i && mem_req_valid_o) begin
                state_n = load_vector;
              end
              case(k_prime)
                default: begin
                    mem_req_addr_o = addrX; 
                    mem_req_typ_o = 0;
                end

                3'd1 : begin
                    mem_req_addr_o = addrX + i_temp;
                    mem_req_typ_o = 1;
                end
                
                3'd2 : begin
                    mem_req_addr_o = addrX + i_temp;
                    mem_req_typ_o = 2;
                end

                3'd3 : begin
                    mem_req_addr_o = addrX + i_temp;
                    mem_req_typ_o = 4;
                end

                3'd4 : begin
                    mem_req_addr_o = addrX + i_temp;
                    mem_req_typ_o = 4;
                end
                3'd5 : begin
                    mem_req_addr_o = addrX + i_temp;
                    mem_req_typ_o = 5;
                end
                3'd6 : begin
                    mem_req_addr_o = addrX + i_temp;
                    mem_req_typ_o = 6;
                end
                3'd7 : begin
                    mem_req_addr_o = addrX + i_temp;
                    mem_req_typ_o = 7;  
                end      
            endcase
    end
    load_vector : begin
            mem_req_valid_o = 0;
            if (n_count <= n_size && mem_resp_valid_i) begin
                  state_n = request_X;
            end
            else if (n_count > n_size) begin
              state_n = request_W;
            end
    end
     request_W : begin
               mem_req_valid_o = 1;
               mem_req_cmd_o = 0;
               mem_req_typ_o = 0;
               mem_req_addr_o = addrW;
               if(mem_req_ready_i && mem_req_valid_o) begin
                state_n = compute;
               end
    end
    compute : begin
            if(n_count < n_size && m_count < m_size && mem_resp_valid_i) begin
                mem_req_valid_o = 0;
                state_n = request_W;
            end
            else if (m_count == m_size) begin
              mem_req_valid_o = 0;
              state_n = resp_out;
            end
            else if (n_count == n_size) begin
              mem_req_valid_o = 0;
              state_n = SWS;
            end
    end
    SWS : begin
            if(settings == y_prime_8)
              state_n = store_R;
            else if(settings == z_8)
              state_n = ReLU; 
    end 
    ReLU : begin
      state_n = store_R; 
    end
    store_R : begin
              mem_req_cmd_o = 1;
              mem_req_valid_o = 1;
              mem_req_addr_o = addrR;
              mem_req_typ_o = 8;
              if(mem_req_ready_i && mem_req_valid_o) begin
                 //mem_req_data_o = W;
                 mem_req_data_o = subword;
              end
              if(mem_resp_valid_i) begin
                mem_req_valid_o = 0;
                if (m_count < m_size) 
                  state_n = request_W;
                else if (m_count >= m_size)
                  state_n = resp_out;
              end
    end
    resp_out : begin
                resp_valid_o = 1;
                resp_data_o = 1;
                resp_rd_o = 1;
                if(resp_valid_o && resp_ready_i) begin
                  resp_data_o = 1;
                  resp_rd_o = 1;
                  state_n = cmd_idle;
                end
    end
  endcase
end
endmodule