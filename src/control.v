module control(
  input 					reset,
  input 					branch,	
  input 					A_hazard_MUX_TO_MUX,
  input 					B_hazard_MUX_TO_MUX,
  input	[`CPU_INST_BITS-1:0]	inst_EX,
  input	[`CPU_INST_BITS-1:0]	inst_WB,

  output 	reg				DMEM_sel,
  output 	reg				A_brancg_sel,
  output 	reg				B_brancg_sel,
  output 	reg	[1:0]			CSR_sel,
  output 	reg				CSR_wrt_en,
  output 	reg	[1:0]			WB_sel,
  output 	reg				wrt_en,
  output 	reg	[1:0]			A_sel,
  output 	reg	[1:0]			B_sel,
  output 	reg	[4:0]			wrt_addr,
  output 	reg				dcache_re,
  output	reg				pc_sel	//mux_2
);

wire	[6:0]       opcode_EX = inst_EX[6:0];
wire	[2:0]       funct_EX = inst_EX[14:12];
wire	[6:0]       opcode_WB = inst_WB[6:0];

always @(*) begin
	if(reset) begin
		pc_sel = 1'd0;
		DMEM_sel = 1'd0;
            A_sel = 2'd0;
            B_sel = 2'd0;
            CSR_sel = 2'd0;
            CSR_wrt_en = 1'd0;
		dcache_re = 1'd0;
		A_brancg_sel = 1'd0;
		B_brancg_sel = 1'd0;
	end
	else
		case (opcode_EX)
                `OPC_ARI_RTYPE: begin
			dcache_re = 1'b0;
                  pc_sel = (branch == 1'd1) ? 1'd1 : 1'd0;
			case (A_hazard_MUX_TO_MUX)
					1'b1: A_sel = 2'd2;	//Data_WB
					1'b0: A_sel = 2'd0;	//reg(rs1)
			endcase
			case (B_hazard_MUX_TO_MUX)
					1'b1: B_sel = 2'd2;	//Data_WB
					1'b0: B_sel = 2'd0;	//reg(rs2)
			endcase
                  CSR_sel = 2'b0;  	//*
                  CSR_wrt_en = 1'b0; 	//donot write
                end
                `OPC_ARI_ITYPE: begin
			dcache_re = 1'b0;
                  pc_sel = (branch == 1'd1) ? 1'd1 : 1'd0;
                  case (A_hazard_MUX_TO_MUX)
					1'b1: A_sel = 2'd2;	//Data_WB
					1'b0: A_sel = 2'd0;	//reg(rs1)
			endcase
                  B_sel = 2'd1;  	//imm
                  CSR_sel = 2'b0;  	//*
                  CSR_wrt_en = 1'b0; 	//donot write
                end
                `OPC_LOAD: begin
			dcache_re = 1'b1;	//read memory
                  pc_sel = (branch == 1'b1) ? 1'd1 : 1'd0;
                  case (A_hazard_MUX_TO_MUX)
					1'b1: A_sel = 2'd2;	//Data_WB
					1'b0: A_sel = 2'd0;	//reg(rs1)
			endcase
                  B_sel = 2'd1;	//imm
                  CSR_sel = 2'b0; 	//*
                  CSR_wrt_en = 1'b0; 	//donot write
                end
                `OPC_CSR:begin
			dcache_re = 1'b0;	//*
                  pc_sel = (branch == 1'b1) ?  1'd1 : 1'd0;
                  A_sel = 2'd0;	//*
                  B_sel = 2'd0;	//*
			if(funct_EX ==`FNC_RWI)
				CSR_sel = 2'd1;	//imm
			else if(funct_EX ==`FNC_RW)
				case (A_hazard_MUX_TO_MUX)
					1'b1: CSR_sel = 2'd2;	//Data_WB
					1'b0: CSR_sel = 2'd0;	//reg(rs1)
				endcase
                  CSR_wrt_en = 1'b1;
                end
                `OPC_STORE:begin
			dcache_re = 1'b0;
                  pc_sel = (branch == 1'b1) ?  1'd1 : 1'd0;
                  case (A_hazard_MUX_TO_MUX)
					1'b1: A_sel = 2'd2;	//Data_WB
					1'b0: A_sel = 2'd0;	//reg(rs1)
			endcase
                  B_sel = 2'd1;	//imm
			case (B_hazard_MUX_TO_MUX)
					1'b1: DMEM_sel = 1'd1;	//Data_WB
					1'b0: DMEM_sel = 1'd0;	//reg(rs2)
			endcase
                  CSR_sel = 2'b0; 	//*
                  CSR_wrt_en = 1'b0; 	//donot write
			end
                `OPC_LUI:begin
			dcache_re = 1'b0;	//*
                  pc_sel = (branch == 1'b1) ?  1'd1 : 1'd0;
                  A_sel = 2'd0;	//*
                  B_sel = 2'd1;	//imm
                  CSR_sel = 2'b0; //*
                  CSR_wrt_en = 1'b0; 	//donot write
                end
                `OPC_AUIPC:begin
			dcache_re = 1'b0;	//*
                  pc_sel = (branch == 1'b1) ?  1'd1 : 1'd0;
                  A_sel = 2'd1;	//PC
                  B_sel = 2'd1;	//imm
                  CSR_sel = 2'b0; //*
                  CSR_wrt_en = 1'b0; 	//donot write
                end
                `OPC_JALR:begin
			dcache_re = 1'b0;	//*
                  pc_sel = 1'd1;
                  case (A_hazard_MUX_TO_MUX)
					1'b1: A_sel = 2'd2;	//Data_WB
					1'b0: A_sel = 2'd0;	//reg(rs1)
			endcase
                  B_sel = 2'd1;	//imm
                  CSR_sel = 2'b0; //*
                  CSR_wrt_en = 1'b0; 	//donot write
                end
                `OPC_JAL:begin
			dcache_re = 1'b0;	//*
                  pc_sel = 1'd1;
                  A_sel = 2'd1;	//PC
                  B_sel = 2'd1;	//imm
                  CSR_sel = 2'b0; //*
                  CSR_wrt_en = 1'b0; 	//donot write
                end
                `OPC_BRANCH:begin
			dcache_re = 1'b0;	//*
                  pc_sel = (branch == 1'b1) ?  1'd1 : 1'd0;
                  A_sel = 2'd1;	//PC
                  B_sel = 2'd1;	//imm
                  CSR_sel = 2'b0; //*
                  CSR_wrt_en = 1'b0; 	//donot write
			case (A_hazard_MUX_TO_MUX)
					1'b1: A_brancg_sel = 1'd1;	//Data_WB
					1'b0: A_brancg_sel = 1'd0;	//reg(rs1)
			endcase
			case (B_hazard_MUX_TO_MUX)
					1'b1: B_brancg_sel = 1'd1;	//Data_WB
					1'b0: B_brancg_sel = 1'd0;	//reg(rs2)
			endcase
                end
                default:begin
			dcache_re = 1'b0;	
                  pc_sel = 1'd0;
                  A_sel = 2'd0;
                  B_sel = 2'b0;
                  CSR_sel = 2'b0;
                  CSR_wrt_en = 1'b0;
			B_brancg_sel = 1'd0;
			A_brancg_sel = 1'd0;
			DMEM_sel = 1'd0;
                end
            endcase
end
always @(*) begin
	if(reset) begin
		WB_sel = 2'd0;
		wrt_addr = 5'd0;
		wrt_en = 1'd0;
	end
	else
		case (opcode_WB)
                `OPC_ARI_RTYPE: 	begin
				WB_sel = 2'd1;
				wrt_en = 1'b1;
				wrt_addr=inst_WB[11:7];
			end
                `OPC_ARI_ITYPE: 	begin	
			WB_sel = 2'd1;
	            wrt_en = 1'b1;
			wrt_addr=inst_WB[11:7];
			end
                `OPC_LOAD: 		begin		
			WB_sel = 2'd0;
                  wrt_en = 1'b1;
			wrt_addr=inst_WB[11:7];
			end
                `OPC_CSR:		begin
			WB_sel = 2'd0;	//*
                  wrt_en = 1'b0;
			wrt_addr=5'd0;	//*
			end
                `OPC_STORE:		begin
			WB_sel = 2'd0;	//*
                  wrt_en = 1'b0;
			wrt_addr=5'd0;	//*
			end
                `OPC_LUI:		begin	
			WB_sel = 2'd1;
                  wrt_en = 1'b1;
			wrt_addr=inst_WB[11:7];
			end
                `OPC_AUIPC:		begin	
			WB_sel = 2'd1;
                  wrt_en = 1'b1;
			wrt_addr=inst_WB[11:7];
			end
                `OPC_JALR:		begin	
			WB_sel = 2'd2;
                  wrt_en = 1'b1;
			wrt_addr=inst_WB[11:7];
			end
                `OPC_JAL:		begin	
			WB_sel = 2'd2;
                  wrt_en = 1'b1;
			wrt_addr=inst_WB[11:7];
			end
                `OPC_BRANCH:		begin	
			WB_sel = 2'd0;	//*
                  wrt_en = 1'b0;
			wrt_addr=5'd0;	//*
			end
                default:		begin	
			WB_sel = 2'd0;
                  wrt_en = 1'b0;
			wrt_addr=5'd0;	//*
			end
            endcase
end

endmodule
