module mux_2input(
	input 	[31:0]	in1,
   	input 	[31:0]	in2,
	input 		 	sel,
	
	output 	[31:0] 	out
);
assign out= (sel == 1'd0) ? in1 : in2;

endmodule

module mux_3input(
	input 	[31:0]	in1,
   	input 	[31:0]	in2,
	input 	[31:0]	in3,
	input 	[1:0]	 	sel,
	
	output 	[31:0] 	out
);

assign out = (sel == 2'd0) ? in1 :
             (sel == 2'd1) ? in2 : in3;
endmodule

module mux_4input(
	input 	[31:0]	in1,
   	input 	[31:0]	in2,
	input 	[31:0]	in3,
	input 	[31:0]	in4,
	input 	[1:0]	 	sel,
	
	output 	[31:0] 	out
);

assign out = (sel == 2'd0) ? in1 :
             (sel == 2'd1) ? in2 :
             (sel == 2'd2) ? in3 : in4;
endmodule 

module mux_5input(
	input 	[31:0]	in1,
   	input 	[31:0]	in2,
	input 	[31:0]	in3,
	input 	[31:0]	in4,
	input 	[31:0]	in5,
	input 	[1:0]	 	sel,
	
	output 	[31:0] 	out
);

assign out = (sel == 2'd0) ? in1 :
             (sel == 2'd1) ? in2 :
             (sel == 2'd2) ? in3 :
             (sel == 2'd3) ? in4 : in5;
endmodule 
