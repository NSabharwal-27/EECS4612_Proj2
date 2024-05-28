# Matrix-Vector Multiplier

## Description

This Verilog module (`Asic.v`) implements a matrix-vector multiplier. It defines the top-level module for the multiplier and specifies its input and output ports along with their descriptions. The module is designed to perform matrix-vector multiplication using specified control signals and memory interfaces.

## Interface

### Inputs

- `clk`: Clock input
- `reset`: Reset input
- `cmd_valid_i`: Control signal indicating the validity of the command
- `cmd_inst_funct_i`: Function code for the command instruction
- `cmd_inst_rs2_i`: RS2 register for the command instruction
- `cmd_inst_rs1_i`: RS1 register for the command instruction
- `cmd_inst_xd_i`: Valid RD for the command instruction
- `cmd_inst_xrs1_i`: Valid RS1 for the command instruction
- `cmd_inst_xrs2_i`: Valid RS2 for the command instruction
- `cmd_inst_rd_i`: RD register for the command instruction
- `cmd_inst_opcode_i`: Opcode for the command instruction
- `cmd_rs1_i`: RS1 data for the command
- `mem_req_ready_i`: Memory request ready signal
- `mem_resp_valid_i`: Memory response valid signal
- `mem_resp_addr_i`: Memory response address
- `mem_resp_cmd_i`: Memory response command
- `mem_resp_typ_i`: Memory response operation size
- `mem_resp_data_i`: Memory response data

### Outputs

- `cmd_ready_o`: Control signal indicating command readiness
- `resp_valid_o`: Control signal indicating response validity
- `resp_rd_o`: Response RD
- `resp_data_o`: Response data
- `mem_req_valid_o`: Memory request validity
- `mem_req_addr_o`: Memory request address
- `mem_req_cmd_o`: Memory request command
- `mem_req_typ_o`: Memory request operation size
- `mem_req_data_o`: Memory request data

## Description

The `Asic.v` module implements a matrix-vector multiplier. It performs matrix-vector multiplication using specified control signals and memory interfaces. Here's a breakdown of what the ASIC does:

1. **Initialization and Command Handling**:
   - The module receives command instructions (`cmd_valid_i`, `cmd_inst_funct_i`, etc.) to initiate matrix-vector multiplication.
   - It handles various command instructions such as initializing sizes, setting addresses, and triggering computation.

2. **Matrix and Vector Loading**:
   - Upon receiving commands, the module loads matrix elements and vector elements from memory (`mem_resp_valid_i`, `mem_resp_data_i`) using memory request signals (`mem_req_valid_o`, `mem_req_addr_o`, etc.).
   - It organizes and stores the loaded vector elements into memory.

3. **Computation**:
   - The module computes the matrix-vector multiplication based on the loaded matrix and vector elements.
   - It performs element-wise multiplication and accumulation to generate the result.

4. **Optional Operations**:
   - Optionally, it supports additional operations like applying ReLU activation function (`ReLU`) and storing results back to memory (`store_R`).

5. **Response Generation**:
   - Once the computation is complete, the module generates response signals (`resp_valid_o`, `resp_rd_o`, `resp_data_o`) to indicate the availability of results.

6. **State Management**:
   - The module maintains internal states (`state`) to manage the computation process, transitioning between different stages of operation based on the received commands and completion of tasks.

Overall, the ASIC facilitates efficient matrix-vector multiplication by handling command instructions, coordinating memory access, performing computations, and generating output responses.


## Author

- **Nikhil Sabharwal**

## Code template (lines 1 - 85) writen by:

- **Abel Beyene**

## Date

- March 6, 2023

