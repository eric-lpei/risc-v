module CSR_RegFile(
	input 			clk,
   	input 			reset,
	input 	[11:0] 	csr_addr,
	input 	[31:0] 	csr_din,

	output 	[31:0] 	csr_dout,
	
	input 			wrt_en
);

reg [31:0] register_file [0:4095];
integer i;
assign	csr_dout = (reset == 1)? 32'd0:register_file[csr_addr];
always @(posedge clk)
    if (reset) begin
        for (i = 0; i < 4096; i = i + 1)
        	register_file[i] <= 0;
        end 
    else begin
	  if (wrt_en)
        	register_file[csr_addr] <= csr_din;
        end

endmodule
