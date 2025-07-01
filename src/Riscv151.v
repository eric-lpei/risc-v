`include "const.vh"

module Riscv151(
    input clk,
    input reset,

    // Memory system ports
    output [31:0] dcache_addr,
    output [31:0] icache_addr,
    output [3:0] dcache_we,
    output dcache_re,
    output icache_re,
    output [31:0] dcache_din,

    input [31:0] dcache_dout,
    input [31:0] icache_dout,
    input stall,

    output [31:0] csr

);

reg		[31:0]	pc_EX,pc_WB;
wire		[31:0]	ALU;
reg		[31:0]	ALU_WB;
wire		[31:0]	WB_data;
reg		[31:0]	inst_WB,inst_EX;
wire				branch;
wire				A_hazard_MUX_TO_MUX,B_hazard_MUX_TO_MUX;
wire				wrt_en,pc_sel,DMEM_sel,CSR_wrt_en,A_brancg_sel,B_brancg_sel;
wire		[1:0]		WB_sel,A_sel,B_sel,CSR_sel;
wire		[4:0]		wrt_addr;

assign	icache_re = 1'b1;
assign	dcache_re = 1'b1;

always @(*)
	if(reset)
		inst_EX = 32'd0;
	else	if(stall)
		inst_EX = inst_EX;
	else	
		inst_EX = icache_dout;

IF_stage	IF_stage(
  .clk		(clk),
  .reset		(reset),
  .ALU		(ALU),	
  .pc_sel		(pc_sel),	
  .pc_EX		(pc_EX),
  .stall		(stall),

  .icache_addr	(icache_addr)
);

///		reg_pc_IF->EX
always @(posedge clk)
	if(reset)
		pc_EX <= `PC_RESET-32'd4;
	else 
		pc_EX <= icache_addr;

EX_stage	EX_stage(
  .clk		(clk),
  .reset		(reset),
  .A_sel		(A_sel),
  .B_sel		(B_sel),
  .CSR_sel		(CSR_sel),
  .DMEM_sel		(DMEM_sel),
  .A_brancg_sel	(A_brancg_sel),
  .B_brancg_sel	(B_brancg_sel),
  .wrt_en		(wrt_en),
  .CSR_wrt_en	(CSR_wrt_en),
  .inst_EX		(inst_EX),
  .pc_EX		(pc_EX),
  .ALU_WB		(ALU_WB),
  .WB_data		(WB_data),
  .wrt_addr		(wrt_addr),
  .dataD		(WB_data),

  .dcache_we	(dcache_we),
  .branch		(branch),
  .csr		(csr),
  .Data_W		(dcache_din),
  .ALU		(ALU)
);

assign	dcache_addr = ALU;
///		reg_ALU_EX->WB
always @(posedge clk)
	if(reset)
		ALU_WB <= 0;
	else 
		ALU_WB <= ALU;
///		reg_instruction_EX->WB
always @(posedge clk)
	if(reset)
		inst_WB <= `INSTR_NOP;
	else 
		inst_WB <= inst_EX;
///		reg_pc_EX->WB
always @(posedge clk)
	if(reset)
		pc_WB <= `PC_RESET;
	else 
		pc_WB <= pc_EX;

WB_stage	WB_stage(
  .clk		(clk),
  .reset		(reset),
  .dcache_dout	(dcache_dout),
  .inst_WB		(inst_WB),
  .pc_WB		(pc_WB),
  .ALU_WB		(ALU_WB),
  .WB_sel		(WB_sel),

  .WB_data		(WB_data)	
);

control(
  .reset		(reset),
  .branch		(branch),	
  .A_hazard_MUX_TO_MUX	(A_hazard_MUX_TO_MUX),
  .B_hazard_MUX_TO_MUX	(B_hazard_MUX_TO_MUX),
  .inst_EX		(inst_EX),
  .inst_WB		(inst_WB),

  .A_brancg_sel	(A_brancg_sel),
  .B_brancg_sel	(B_brancg_sel),
  .DMEM_sel		(DMEM_sel),
  .CSR_sel		(CSR_sel),
  .CSR_wrt_en	(CSR_wrt_en),
  .WB_sel		(WB_sel),
  .wrt_en		(wrt_en),
  .A_sel		(A_sel),
  .B_sel		(B_sel),
  .wrt_addr		(wrt_addr),
  .dcache_re	(),
  .pc_sel		(pc_sel)	//mux_2
);
hazard	hazard(
  .reset			(reset),	
  .inst_EX			(inst_EX),
  .inst_WB			(inst_WB),
  .wrt_addr			(wrt_addr),

  .A_hazard_MUX_TO_MUX	(A_hazard_MUX_TO_MUX),
  .B_hazard_MUX_TO_MUX	(B_hazard_MUX_TO_MUX),
  .hazard_MEMORY_TO_MUX	()
);
endmodule
