// Module: ALU.v
// Desc:   32-bit ALU for the RISC-V Processor
// Inputs: 
//    A: 32-bit value
//    B: 32-bit value
//    ALUop: Selects the ALU's operation 
// 						
// Outputs:
//    Out: The chosen function mapped to A and B.

`include "Opcode.vh"
`include "ALUop.vh"

module ALU(
    input [31:0] A,B,
    input [3:0] ALUop,

    output reg [31:0] Out
);

always @(*)
case (ALUop) 
	`ALU_ADD: begin
		Out = A + B;
	end
	`ALU_SUB: begin
		Out = A - B;
	end
	`ALU_AND: begin
		Out = A & B;
	end
	`ALU_OR: begin
		Out = A | B;
	end
	`ALU_XOR: begin
		Out = A^B;
	end
	`ALU_SLT: begin
		Out =($signed(A) < $signed(B))? 32'd1:32'd0;
	end
//	`ALU_SLT: begin
//		if(A[31] == 0 && B[31] == 0)
//			if(A[30:0] < B[30:0])
//				Out = 32'd1;
//			else
//				Out = 32'd0;
//		else if(A[31] == 1 && B[31] == 1)
//			if(A[30:0] < B[30:0])
//				Out = 32'd0;
//			else
//				Out = 32'd1;
//		else if(A[31]==0)
//			Out = 32'd0;
//		else
//			Out = 32'd1;
//	end
	`ALU_SLTU: begin
		if(A < B)
			Out = 1;
		else
			Out = 0;			
	end
	`ALU_SLL: begin
		Out = A << B[4:0];
	end
	`ALU_SRA: begin
		Out = $signed(A) >>>B[4:0];
	end
	`ALU_SRL: begin
		Out = A >> B[4:0];
	end
	`ALU_COPY_B: begin
		Out = B;
	end
	`ALU_COPY_A: begin
		Out = A;
	end
	`ALU_JALR: begin
		Out = (A + B) & 32'hffff_fffe;
	end
	`ALU_XXX: begin
		Out = 0;
	end
endcase

endmodule
