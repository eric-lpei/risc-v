`include "Opcode.vh"
`include "ALUop.vh"
`include "const.vh"
module LDX(
  input 	[2:0] 			funct,
  input 	[6:0]       		opcode,
  input 	[31:0] 			din,
  input	[`CPU_DATA_BITS-1:0]	ALU_WB,

  output reg 	[31:0] 		dout
);

wire [1:0] byte_sel = ALU_WB[1:0];;

always@(*) begin
	case(funct)
		`FNC_LB:begin
                	case (byte_sel)
                      2'b00: dout = { {24{din[7]}}, din[7:0]};
                      2'b01: dout = { {24{din[15]}}, din[15:8]};
                      2'b10: dout = { {24{din[23]}}, din[23:16]};
                      2'b11: dout = { {24{din[31]}}, din[31:24]};
                      default: dout = 32'b0;
                	endcase
          	end
		`FNC_LH: begin
			case (byte_sel)
                      2'b00: dout = { {16{din[15]}}, din[15:0] };
                      2'b01: dout = { {16{din[15]}}, din[15:0] };
                      2'b10: dout = { {16{din[31]}}, din[31:16] };
                      2'b11: dout = { {16{din[31]}}, din[31:16] };
                      default: dout = 32'b0;
			endcase
		end  
          	`FNC_LW: dout = din;
          	`FNC_LBU: begin
			case (byte_sel)
                      2'b00: dout = { {24{1'b0}}, din[7:0] };
                      2'b01: dout = { {24{1'b0}}, din[15:8] };
                      2'b10: dout = { {24{1'b0}}, din[23:16] };
                      2'b11: dout = { {24{1'b0}}, din[31:24] };
                      default: dout = 32'b0;
			endcase
		end
           	`FNC_LHU: begin
			case (byte_sel)
                      2'b00: dout = { {16{1'b0}}, din[15:0] };
                      2'b01: dout = { {16{1'b0}}, din[15:0] };
                      2'b10: dout = { {16{1'b0}}, din[31:16] };
                      2'b11: dout = { {16{1'b0}}, din[31:16] };
                      default: dout = 32'b0;
			endcase
		end
           default: dout = 32'd0;
       endcase
end

endmodule
