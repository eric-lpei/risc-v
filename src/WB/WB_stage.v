`include "const.vh"
module WB_stage(
  input 						clk,
  input 						reset,
  input		[`CPU_DATA_BITS-1:0]	dcache_dout,
  input		[`CPU_INST_BITS-1:0]	inst_WB,
  input		[`CPU_ADDR_BITS-1:0]	pc_WB,
  input		[`CPU_DATA_BITS-1:0]	ALU_WB,
  input 		[1:0]				WB_sel,

  output		[`CPU_DATA_BITS-1:0]	WB_data
);

wire	[6:0]       opcode = inst_WB[6:0];
wire	[2:0]       funct = inst_WB[14:12];
wire	[31:0]	Mdata,pc_plus4;

adder	adder_4(
	. in	(pc_WB), 

  	. out	(pc_plus4)
);

LDX	LDX(
  .funct		(funct),
  .opcode		(opcode),
  .din		(dcache_dout),
  .ALU_WB		(ALU_WB),

  .dout		(Mdata)
);

mux_3input	mux3(
	.in1	(Mdata),
   	.in2	(ALU_WB),
	.in3	(pc_plus4),
	.sel	(WB_sel),
	
	.out	(WB_data)
);
endmodule
