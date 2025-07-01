`include "Opcode.vh"
`include "ALUop.vh"

module Branch_comp(
	input 	[6:0]       opcode,
  	input 	[2:0]       funct,
	input 	[31:0] 	dataA,
	input 	[31:0] 	dataB,

	output reg	 		branch
);
    
always @(*) begin
	if (opcode == `OPC_BRANCH) begin
		case (funct)
            `FNC_BEQ: branch = (dataA == dataB);
            `FNC_BNE: branch = (dataA != dataB);
            `FNC_BLT: branch = ($signed(dataA) < $signed(dataB));
            `FNC_BGE: branch = ($signed(dataA) >= $signed(dataB));
            `FNC_BLTU: branch = (dataA < dataB);
            `FNC_BGEU: branch = (dataA >= dataB);
            default: branch = 1'b0;
            endcase
	end 
	else if (opcode == `OPC_JALR || opcode == `OPC_JAL) begin
            branch = 1'b1;
      end 
	else begin
            branch = 1'b0;
       end
end


endmodule
