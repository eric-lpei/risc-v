// Module: ALUdecoder
// Desc:   Sets the ALU operation
// Inputs: opcode: the top 6 bits of the instruction
//         funct: the funct, in the case of r-type instructions
//         add_rshift_type: selects whether an ADD vs SUB, or an SRA vs SRL
// Outputs: ALUop: Selects the ALU's operation
//

`include "Opcode.vh"
`include "ALUop.vh"

module ALUdec(
  input [6:0]       opcode,
  input [2:0]       funct,
  input             add_rshift_type,
  output reg [3:0]  ALUop
);

always @(*)
	if(opcode == `OPC_ARI_RTYPE)			//R-tpye 
		if(!add_rshift_type)		
			case (funct)
				`FNC_ADD_SUB: ALUop = `ALU_ADD;
				`FNC_SLL: ALUop = `ALU_SLL;
				`FNC_SLT: ALUop = `ALU_SLT;
				`FNC_SLTU: ALUop = `ALU_SLTU;
				`FNC_XOR: ALUop = `ALU_XOR;
				`FNC_SRL_SRA: ALUop = `ALU_SRL;
				`FNC_OR: ALUop = `ALU_OR;
				`FNC_AND: ALUop = `ALU_AND;
			endcase
		else 						//sub-SRA
			case (funct)
				3'b000: ALUop = `ALU_SUB;
				3'b101: ALUop = `ALU_SRA;
			endcase
	else if(opcode == `OPC_ARI_ITYPE)		 	//I-type		
			case (funct)
				`FNC_ADD_SUB: ALUop = `ALU_ADD;
				`FNC_SLL: ALUop = `ALU_SLL;
				`FNC_SLT: ALUop = `ALU_SLT;
				`FNC_SLTU: ALUop = `ALU_SLTU;
				`FNC_XOR: ALUop = `ALU_XOR;
				`FNC_SRL_SRA: begin
				  if(add_rshift_type)
					ALUop = `ALU_SRA;
				  else
					ALUop = `ALU_SRL;
				end
				`FNC_OR: ALUop = `ALU_OR;
				`FNC_AND: ALUop = `ALU_AND;
			endcase
	else if(opcode == `OPC_LOAD)
		ALUop = `ALU_ADD;
	else if(opcode == `OPC_STORE)
		ALUop = `ALU_ADD;
	else if(opcode == `OPC_BRANCH)
		ALUop = `ALU_ADD;
	else if(opcode == `OPC_JALR)
		ALUop = `ALU_JALR;
	else if(opcode == `OPC_JAL)
		ALUop = `ALU_ADD;
	else if(opcode == `OPC_AUIPC)
		ALUop = `ALU_ADD;
	else if(opcode == `OPC_LUI)
		ALUop = `ALU_COPY_B;
	else if(opcode == `OPC_NOOP)
		ALUop = `ALU_XXX;
	else if(opcode == `OPC_CSR)
		if(funct ==`FNC_RWI)
			ALUop = `ALU_COPY_B;
		else if(funct ==`FNC_RW)
			ALUop = `ALU_COPY_A;

endmodule
