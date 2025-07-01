`include "Opcode.vh"
`include "ALUop.vh"
`include "const.vh"
module DMEM_write_control(
  input  		[`CPU_DATA_BITS-1:0]  	ALU,
  input  		[`CPU_DATA_BITS-1:0]  	Data_W_wordle,
  input 		[6:0]       		opcode,
  input 		[2:0] 			funct,

  output 	reg	[3:0]				dcache_we,
  output reg 	[`CPU_DATA_BITS-1:0] 	Data_W
);
    
wire [1:0] byte_sel = ALU[1:0];    

always@(*) begin
	if(opcode == `OPC_STORE)
	case(funct)
		`FNC_SB:begin
                	case (byte_sel)
                      2'b00: begin
				dcache_we = 4'b0001;
				Data_W = {{24{1'b0}}, Data_W_wordle[7:0]};
				end
                      2'b01: begin
				dcache_we = 4'b0010;
				Data_W = {{16{1'b0}}, Data_W_wordle[7:0], {8{1'b0}}};
				end
                      2'b10: begin
				dcache_we = 4'b0100;
				Data_W = {{8{1'b0}}, Data_W_wordle[7:0], {16{1'b0}}};
				end
                      2'b11: begin
				dcache_we = 4'b1000;
				Data_W = {Data_W_wordle[7:0], {24{1'b0}}};
				end
                      default: begin
				dcache_we = 4'b0000;
				Data_W = 32'b0; 
				end
                	endcase
          	end
		`FNC_SH: begin
			case (byte_sel)
                      2'b00: begin
				dcache_we = 4'b0011;
				Data_W = {{16{1'b0}}, Data_W_wordle[15:0]};
				end
                      2'b01: begin
				dcache_we = 4'b0011;
				Data_W = {{16{1'b0}}, Data_W_wordle[15:0]};
				end
                      2'b10: begin
				dcache_we = 4'b1100;
				Data_W = {Data_W_wordle[15:0], {16{1'b0}}};
				end
                      2'b11: begin
				dcache_we = 4'b1100;
				Data_W = {Data_W_wordle[15:0], {16{1'b0}}};
				end
                      default: begin
				dcache_we = 4'b0000;
				Data_W = 32'b0;
				end
			endcase
		end  
          	`FNC_SW: begin
			dcache_we = 4'b1111;
			Data_W = Data_W_wordle;
			end
           default: begin
			dcache_we = 4'b0000;
			Data_W = 32'b0;
			end
       endcase
	else begin
		dcache_we = 4'b0000;
		Data_W = 32'b0;
	end
end
		
endmodule
