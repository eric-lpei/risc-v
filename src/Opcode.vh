/**
 * List of RISC-V opcodes.
 * This file was completely rewritten from the file version that was used for MIPS. 
 * RISC-V uses far fewer opcodes than MIPS, but many more function codes.
 */

`ifndef OPCODE
`define OPCODE

// ***** Opcodes *****

// No operation (kill)
`define OPC_NOOP        7'b0000000//

// Special immediate instructions
`define OPC_LUI         7'b0110111//
`define OPC_AUIPC       7'b0010111//

// Jump instructions
`define OPC_JAL         7'b1101111//
`define OPC_JALR        7'b1100111//

// Branch instructions
`define OPC_BRANCH      7'b1100011//

// Load and store instructions
`define OPC_STORE       7'b0100011//
`define OPC_LOAD        7'b0000011//

// Arithmetic instructions
`define OPC_ARI_RTYPE   7'b0110011//
`define OPC_ARI_ITYPE   7'b0010011//

// Control status register
`define OPC_CSR         7'b1110011


// ***** Function codes *****

// Branch function codes
`define FNC_BEQ         3'b000
`define FNC_BNE         3'b001
`define FNC_BLT         3'b100
`define FNC_BGE         3'b101
`define FNC_BLTU        3'b110
`define FNC_BGEU        3'b111

// Load and store function codes
`define FNC_LB          3'b000
`define FNC_LH          3'b001
`define FNC_LW          3'b010
`define FNC_LBU         3'b100
`define FNC_LHU         3'b101
`define FNC_SB          3'b000
`define FNC_SH          3'b001
`define FNC_SW          3'b010

// Arithmetic R-type and I-type functions codes
`define FNC_ADD_SUB     3'b000
`define FNC_SLL         3'b001
`define FNC_SLT         3'b010
`define FNC_SLTU        3'b011
`define FNC_XOR         3'b100
`define FNC_OR          3'b110
`define FNC_AND         3'b111
`define FNC_SRL_SRA     3'b101

// Control status function codes
`define FNC_RW          3'b001
`define FNC_RWI         3'b101

// ADD and SUB use the same opcode + function code
// SRA and SRL also use the same opcode + function code
// For these operations, we also need to look at bit 30 of the instruction
`define FNC2_ADD        1'b0
`define FNC2_SUB        1'b1
`define FNC2_SRL        1'b0
`define FNC2_SRA        1'b1



`endif //OPCODE
