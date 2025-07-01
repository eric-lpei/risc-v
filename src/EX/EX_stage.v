`include "const.vh"
module EX_stage(
  input 						clk,
  input 						reset,
  input 		[1:0]				A_sel,
  input 		[1:0]				B_sel,
  input 		[1:0]				CSR_sel,
  input 						DMEM_sel,
  input 						A_brancg_sel,
  input 						B_brancg_sel,
  input 						wrt_en,
  input 						CSR_wrt_en,
  input		[`CPU_INST_BITS-1:0]	inst_EX,
  input		[`CPU_ADDR_BITS-1:0]	pc_EX,
  input		[`CPU_DATA_BITS-1:0]	ALU_WB,
  input		[`CPU_DATA_BITS-1:0]	WB_data,
  input		[4:0]				wrt_addr,
  input 		[31:0] 			dataD,

  output  		[3:0]			  	dcache_we,
  output  					  	branch,
  output  		[`CPU_DATA_BITS-1:0]  	csr,
  output  		[`CPU_DATA_BITS-1:0]  	Data_W,
  output  		[`CPU_DATA_BITS-1:0]  	ALU
);

wire	[31:0]	Reg_rs1,Reg_rs2,alu_A,alu_B,imm,Branch_A,Branch_B;
wire	[3:0]		ALUop;
wire		      add_rshift_type = inst_EX[30];
wire	[6:0]       opcode = inst_EX[6:0];
wire	[2:0]       funct = inst_EX[14:12];
wire	[4:0]       Rd_addA = inst_EX[19:15];
wire	[4:0]       Rd_addB = inst_EX[24:20];
wire	[31:0]      csr_din,Data_W_wordle;
wire	[11:0]      csr_addr = `CSR_TOHOST;

RegFile	RegFile_inst(
	.clk		(clk),
   	.reset	(reset),
	.rd_addA	(Rd_addA),
	.rd_addB	(Rd_addB),

	.dataA	(Reg_rs1),
	.dataB	(Reg_rs2),

	.wrt_en	(wrt_en),
	.wrt_addr	(wrt_addr),
	.dataD	(dataD)
);
mux_2input	mux_A_Branch(
	.in1		(Reg_rs1),
   	.in2		(WB_data),
	.sel		(A_brancg_sel),
	
	.out		(Branch_A)
);
mux_2input	mux_B_Branch(
	.in1		(Reg_rs2),
   	.in2		(WB_data),
	.sel		(B_brancg_sel),
	
	.out		(Branch_B)
);
Branch_comp	Branch_comp_inst(
	.opcode	(opcode),
  	.funct	(funct),
	.dataA	(Branch_A),
	.dataB	(Branch_B),

	.branch	(branch)
);
mux_4input	mux_A(
	.in1	(Reg_rs1),
   	.in2	(pc_EX),
	.in3	(WB_data),
	.in4	(ALU_WB),	
	.sel	(A_sel),
	
	.out	(alu_A)
);
mux_3input	mux_B(
	.in1	(Reg_rs2),
   	.in2	(imm),
	.in3	(ALU_WB),
	.sel	(B_sel),
	
	.out	(alu_B)
);
ALUdec	ALUdec_inst(
  .opcode			(opcode),
  .funct			(funct),
  .add_rshift_type	(add_rshift_type),
  .ALUop			(ALUop)
);

ALU	ALU_inst(
    .A	(alu_A),
    .B	(alu_B),
    .ALUop	(ALUop),

    .Out	(ALU)
);

immGen	immGen_inst(
	. inst_EX	(inst_EX),

	. imm			(imm)
);

mux_3input	CSR_MUX(
	.in1	(Reg_rs1),
   	.in2	(imm),
   	.in3	(WB_data),
	.sel	(CSR_sel),
	
	.out	(csr_din)
);

CSR_RegFile		CSR(
	.clk		(clk),
   	.reset	(reset),
	.csr_addr	(csr_addr),
	.csr_din	(csr_din),

	.csr_dout	(csr),
	
	.wrt_en	(CSR_wrt_en)
);

mux_2input	mux_DMEM(
	.in1		(Reg_rs2),
   	.in2		(WB_data),
	.sel		(DMEM_sel),
	
	.out		(Data_W_wordle)
);
DMEM_write_control	DMEM_write_control(
  .ALU		(ALU),
  .Data_W_wordle	(Data_W_wordle),
  .opcode		(opcode),
  .funct		(funct),

  .dcache_we	(dcache_we),
  .Data_W		(Data_W)
);
endmodule
