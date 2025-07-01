`include "Opcode.vh"

module immGen(
	input 	[`CPU_INST_BITS-1:0] inst_EX,

	output reg 	[`CPU_INST_BITS-1:0] imm
);
    
    
wire 	[6:0] 	opcode = inst_EX[6:0];
wire	[2:0]       funct = inst_EX[14:12];
always @(*)
case (opcode) 
	`OPC_ARI_ITYPE: begin			//I-type
			if(funct == `FNC_SLL || funct == `FNC_SRL_SRA)
				imm = {{27{1'b0}},inst_EX[24:20]};
			else
				imm = {{20{inst_EX[31]}},inst_EX[31:20]};
		end
		`OPC_LOAD: 		imm = {{20{inst_EX[31]}},inst_EX[31:20]};
		`OPC_STORE:		imm = {{20{inst_EX[31]}},inst_EX[31:25],inst_EX[11:7]}; 
		`OPC_BRANCH:	imm = {{19{inst_EX[31]}},inst_EX[31],inst_EX[7],inst_EX[30:25],inst_EX[11:8],1'b0};
		`OPC_JALR:		imm = {{20{inst_EX[31]}},inst_EX[31:20]};
		`OPC_JAL:		imm = {{11{inst_EX[31]}}, inst_EX[31], inst_EX[19:12], inst_EX[20], inst_EX[30:21], 1'b0};
		`OPC_AUIPC:		imm = inst_EX[31:12] << 12;
		`OPC_LUI:		imm = inst_EX[31:12] << 12;
		`OPC_CSR:		imm = {{27{1'b0}},inst_EX[19:15]};
		default:		imm = 32'd0;
	endcase
		
endmodule
