
module RegFile(
	input 			clk,
   	input 			reset,
	input 	[4:0] 	rd_addA,
	input 	[4:0] 	rd_addB,

	output 	[31:0] 	dataA,
	output 	[31:0] 	dataB,
	
	input 			wrt_en,
	input 	[4:0] 	wrt_addr,
	input 	[31:0] 	dataD
);

reg [31:0] register_file [0:31];
assign dataA = register_file[rd_addA];
assign dataB = register_file[rd_addB];
integer i;
always @(posedge clk)
    if (reset) begin
        for (i = 0; i < 32; i = i + 1)
        register_file[i] <= 0;
        end 
    else begin
	  if (wrt_en)
		if(wrt_addr == 5'd0)
			register_file[wrt_addr] <= 32'd0;
		else
        		register_file[wrt_addr] <= dataD;
        end

endmodule
