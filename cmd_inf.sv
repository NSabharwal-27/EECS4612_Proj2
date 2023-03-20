//====================================
// cmd_inf.sv
//====================================
// This circuit does...

module cmd_inf (
  input     logic     clk,
  input     logic     reset,

  // PROC ASIC communication
  input     logic [4:0]    cmd_inst_rs1_i,
  input     logic [6:0]    cmd_inst_funct_i,
  input     logic [6:0]    cmd_inst_opcode_i,
  input     logic [63:0]   cmd_rs1_i;

  // val/rdy protocol signals
  input      logic          cmd_valid_i,
  output     logic          cmd_ready_o,
);
  //cmd def'n
  localparam cmd_initiate = 7'b000_0001; //0x1
  localparam cmd_size     = 7'b000_0010; //0x2
  localparam cmd_addrW    = 7'b000_0100; //0x4
  localparam cmd_addrX    = 7'b000_0110; //0x6
  localparam cmd_addrR    = 7'b000_1000; //0x8

  //cmd_initiate settings
  localparam y_prime_8      = 7'b000_0000; //8-b wide
  localparam z_8            = 7'b000_0010; //8-b wide
  localparam phi_8          = 7'b000_0100; //8-b wide

  localparam y_prime_16     = 7'b000_0001; //16-b wide
  localparma z_16           = 7'b000_0011; //16-b wide
  localparam phi_16         = 7'b000_0101; //16-b wide

  logic [6:0] cmd_instr     = 7'b111_1111; //cmd.* instruction to be saved somewhere.
  logic [6:0] output_size   = 7'b111_1111; //output size 
  
  logic [15:0] m_size;
  logic [15:0] n_size;
  logic [31:0] addrW;     //holds the starting value of W
  logic [31:0] addrX;     //holds the starting value of X
  logic [31:0] addrR;     //holds the starting value of R


  /* if cmd_valid_i is ready, read 
  * in the port cmd_inst_funt_i and save 
  * in the cmd_instr reg
  * and update val/rdy protocol
  */
  always @(posedge clk) begin
    if(cmd_valid_i){
      cmd_instr <= cmd_inst_funct_i;
      cmd_ready_o <= 1;
    }
  end

 /*
 * if cmd.* sent is cmd.size
 * read in size of M and N 
 * from cmd_rs1_i port.
 */
 if(cmd_instr == cmd_size){
  m_size = cmd_rs1_i[15:0];
  n_size = cmd_rs1_i[31:16];

  logic [m_size - 1:0] M; // rows of W
  logic [n_size - 1:0] N; // columns of W
 }
 else if(cmd_instr == cmd_addrW){
  addrW = cmd_rs1_i;
 }
 else if(cmd_instr == cmd_addrX){
  addrX = cmd_rs1_i;
 }
 else if(cmd_instr == cmd_addrR){
  addrR = cmd_rs1_i;
 }

endmodule