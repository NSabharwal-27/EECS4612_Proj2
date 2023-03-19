//====================================
// ASIC.sv
//====================================
// This circuit does...

module cmd_inf (
  input     logic     clk,
  input     logic     reset,
  input     logic [4:0]    cmd_rs1_i,
  input     logic [6:0]    cmd_inst_funct_i,
  input     logic [6:0]    cmd_inst_opcode_i,
);
  //cmd def'n
  localparam CMD_initiate = 7'b000_0001; //0x1
  localparam CMD_size     = 7'b000_0010; //0x2
  localparam CMD_addrW    = 7'b000_0100; //0x4
  localparam CMD_addrX    = 7'b000_0110; //0x6
  localparam CMD_addrR    = 7'b000_1000; //0x8
  

endmodule