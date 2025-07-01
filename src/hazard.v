module hazard(
  input 					reset,	
  input	[`CPU_INST_BITS-1:0]	inst_EX,
  input	[`CPU_INST_BITS-1:0]	inst_WB,
  input	[4:0]				wrt_addr,

  output 	reg				A_hazard_MUX_TO_MUX,
  output 	reg				B_hazard_MUX_TO_MUX,
  output	reg				hazard_MEMORY_TO_MUX	
);

wire	[6:0]       opcode_EX = inst_EX[6:0];
wire	[2:0]       funct_EX = inst_EX[14:12];
wire	[6:0]       opcode_WB = inst_WB[6:0];

wire	[4:0]       Rd_addA = inst_EX[19:15];
wire	[4:0]       Rd_addB = inst_EX[24:20];


always @(*) begin
	if(reset) begin
		A_hazard_MUX_TO_MUX = 1'd0;
		B_hazard_MUX_TO_MUX = 1'd0;
		hazard_MEMORY_TO_MUX = 1'd0;
	end
	else  if(wrt_addr != 5'd0)
		case (opcode_EX)
                `OPC_ARI_RTYPE: 	begin
				hazard_MEMORY_TO_MUX = 1'd0;
				if(Rd_addA == wrt_addr) begin
					if(Rd_addA == Rd_addB) begin
						A_hazard_MUX_TO_MUX = 1'd1;
						B_hazard_MUX_TO_MUX = 1'd1;
					end
					else begin
						A_hazard_MUX_TO_MUX = 1'd1;
						B_hazard_MUX_TO_MUX = 1'd0;
					end
				end
				else if(Rd_addB == wrt_addr) begin
					A_hazard_MUX_TO_MUX = 1'd0;
					B_hazard_MUX_TO_MUX = 1'd1;
				end
				else begin
					A_hazard_MUX_TO_MUX = 1'd0;
					B_hazard_MUX_TO_MUX = 1'd0;
				end
					
			end
                `OPC_ARI_ITYPE: 	begin	
			B_hazard_MUX_TO_MUX = 1'd0;
			if(Rd_addA == wrt_addr) begin
				A_hazard_MUX_TO_MUX = 1'd1;
			end
			else
				A_hazard_MUX_TO_MUX = 1'd0;
			end
                `OPC_LOAD: 		begin		
			B_hazard_MUX_TO_MUX = 1'd0;
			if(Rd_addA == wrt_addr) begin
				A_hazard_MUX_TO_MUX = 1'd1;
			end
			else
				A_hazard_MUX_TO_MUX = 1'd0;
			end
                `OPC_CSR:		begin
			B_hazard_MUX_TO_MUX = 1'd0;
			if(funct_EX == `FNC_RW)
				if(Rd_addA == wrt_addr)
					A_hazard_MUX_TO_MUX = 1'd1;
				else
					A_hazard_MUX_TO_MUX = 1'd0;
			else
				A_hazard_MUX_TO_MUX = 1'd0;
			end
                `OPC_STORE:		begin
			if(Rd_addA == wrt_addr) begin
				if(Rd_addA == Rd_addB) begin
					A_hazard_MUX_TO_MUX = 1'd1;
					B_hazard_MUX_TO_MUX = 1'd1;
				end
				else begin
					A_hazard_MUX_TO_MUX = 1'd1;
					B_hazard_MUX_TO_MUX = 1'd0;
				end
			end
			else if(Rd_addB == wrt_addr) begin
				A_hazard_MUX_TO_MUX = 1'd0;
				B_hazard_MUX_TO_MUX = 1'd1;
			end
			else begin
				A_hazard_MUX_TO_MUX = 1'd0;
				B_hazard_MUX_TO_MUX = 1'd0;
			end
			end
                `OPC_LUI:		begin	
			A_hazard_MUX_TO_MUX = 1'd0;
			B_hazard_MUX_TO_MUX = 1'd0;
			end
                `OPC_AUIPC:		begin	
			A_hazard_MUX_TO_MUX = 1'd0;
			B_hazard_MUX_TO_MUX = 1'd0;
			end
                `OPC_JALR:		begin	
			B_hazard_MUX_TO_MUX = 1'd0;
			if(Rd_addA == wrt_addr) begin
				A_hazard_MUX_TO_MUX = 1'd1;
			end
			else
				A_hazard_MUX_TO_MUX = 1'd0;
			end
                `OPC_JAL:		begin	
			A_hazard_MUX_TO_MUX = 1'd0;
			B_hazard_MUX_TO_MUX = 1'd0;
			end
                `OPC_BRANCH:		begin	
			if(Rd_addA == wrt_addr) begin
				if(Rd_addA == Rd_addB) begin
					A_hazard_MUX_TO_MUX = 1'd1;
					B_hazard_MUX_TO_MUX = 1'd1;
				end
				else begin
					A_hazard_MUX_TO_MUX = 1'd1;
					B_hazard_MUX_TO_MUX = 1'd0;
				end
			end
			else if(Rd_addB == wrt_addr) begin
				A_hazard_MUX_TO_MUX = 1'd0;
				B_hazard_MUX_TO_MUX = 1'd1;
			end
			else begin
				A_hazard_MUX_TO_MUX = 1'd0;
				B_hazard_MUX_TO_MUX = 1'd0;
			end
			end
                default:		begin	
			A_hazard_MUX_TO_MUX = 1'd0;
			B_hazard_MUX_TO_MUX = 1'd0;
			end
            endcase
	else begin
		A_hazard_MUX_TO_MUX = 1'd0;
		B_hazard_MUX_TO_MUX = 1'd0;
		hazard_MEMORY_TO_MUX = 1'd0;
	end
end


endmodule
