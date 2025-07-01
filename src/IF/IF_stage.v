`include "const.vh"
module IF_stage(
  input 						clk,
  input 						reset,
  input		[`CPU_DATA_BITS-1:0]	ALU,	
  input						pc_sel,
  input		[`CPU_ADDR_BITS-1:0]	pc_EX,	
  input						stall,

  output  	reg	[`CPU_ADDR_BITS-1:0]  	icache_addr
);

wire	[`CPU_ADDR_BITS-1:0]	pc_fb,pc_plus4;
always @(*)
	if(reset)
		icache_addr = `PC_RESET;
	else if(stall == 1)
		icache_addr = icache_addr;
	else
		icache_addr = pc_fb;



adder	adder_4(
	. in	(pc_EX), 

  	. out	(pc_plus4)
);

mux_2input	mux_2(
	.in1		(pc_plus4),
   	.in2		(ALU),
	.sel		(pc_sel),
	
	.out		(pc_fb)
);
endmodule
