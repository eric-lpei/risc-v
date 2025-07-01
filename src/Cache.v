`include "util.vh"
`include "const.vh"

module cache #
(
  parameter LINES = 64,
  parameter CPU_WIDTH = `CPU_INST_BITS,
  parameter WORD_ADDR_BITS = `CPU_ADDR_BITS-`ceilLog2(`CPU_INST_BITS/8)//30
)
(
  input clk,
  input reset,

  input                       cpu_req_valid,
  output reg                  cpu_req_ready,
  input [WORD_ADDR_BITS-1:0]  cpu_req_addr,//30
  input [CPU_WIDTH-1:0]       cpu_req_data,
  input [3:0]                 cpu_req_write,

  output reg                  cpu_resp_valid,
  output reg[CPU_WIDTH-1:0]   cpu_resp_data,

  output reg                     mem_req_valid,
  input                       mem_req_ready,
  output reg[WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr,//[29:2]
  output reg                          mem_req_rw,
  output reg                          mem_req_data_valid,
  input                            mem_req_data_ready,
  output reg[`MEM_DATA_BITS-1:0]      mem_req_data_bits,
  // byte level masking
  output reg[(`MEM_DATA_BITS/8)-1:0]  mem_req_data_mask,//[15:0]

  input                       mem_resp_valid,
  input [`MEM_DATA_BITS-1:0]  mem_resp_data
);

parameter WAY = 1;

//wire	[4-1:0]	cpu_addr_offset = cpu_req_addr[3:0];	//word choice
wire	[2:0]		cpu_addr_index = cpu_req_addr[6:4];
wire	[22:0]	cpu_addr_tag = cpu_req_addr[29:7];		//23bits


wire	[31:0]	sram_tag;
wire	[23-1:0]	tag = sram_tag[23-1:0];
reg			valid = sram_tag[23];
reg			hit,miss,cache_tag_WEB1,cache_data_WB1,cache_data_WB2;
reg	[7-1:0]	cache_data_addr1,cache_data_addr2;
reg	[31:0]	cache_read_data1,cache_write_tag1,cache_write_tag2;
reg	[31:0]	cache_write_data1,cache_write_data2;
reg	[2:0]		cycle_count;
reg			cycle_count_4words;
// Define state bits
parameter IDLE = 2'b00;
parameter COMPARE = 2'b01;
parameter MISS_STAGE = 2'b10;

reg [1:0] state;
reg [1:0] nextstate;



//first
always @(posedge clk) begin
	if(reset)
		state <= IDLE;
	else
		state <= nextstate;
end
//second
always @* begin
	// Start by defining default values
	nextstate = IDLE;// Stay in the same state by default
	case (state)
		IDLE : begin
			if(cpu_req_valid)
				nextstate = COMPARE;
		end
		COMPARE : begin
			if(hit)
				nextstate = COMPARE;
			else
				nextstate = MISS_STAGE;
		end
		MISS_STAGE : begin
			if(cycle_count == 3'd7)
				nextstate = COMPARE;
			else
				nextstate = MISS_STAGE;
		end
	endcase
end
//third
always @(posedge clk) begin
if(reset)begin
	cache_tag_WEB1 <= 1;
	hit <= 0;
	miss <= 0;
	cpu_req_ready <= 0;
	cpu_resp_data <= 32'd0;
	mem_req_valid <= 0;
	mem_req_addr <= 28'd0;
	mem_req_rw <= 0;
	valid <= 0;
	cache_data_WB1 <= 1;//read
	cache_data_WB2 <= 1;//read
	cache_data_addr1 <= 7'd0;
	cache_data_addr2 <= 7'd0;
	cycle_count_4words <= 0;
	cycle_count <= 3'd0;
end
else
	case (nextstate)
		IDLE : begin
			if(cpu_req_valid)
				cache_tag_WEB1 <= 1;	//read
		end
		COMPARE : begin
			if(cpu_addr_tag == tag && valid) begin	//hit
				hit <= 1;
				miss <= 0;
				cpu_req_ready <= 1;
				cache_data_WB1 <= 1;//read
				cpu_resp_data <= cache_read_data1;
			end
			else	begin						//miss
				miss <= 1;
				hit <= 0;
				cpu_req_ready <= 0;
			end
		end
		MISS_STAGE : begin					// read data from main memory and give one word to cpu
			mem_req_valid <= 1;	//read
			mem_req_rw <= 0;		//read
			if(mem_req_ready) begin
				case(cycle_count)
					3'd0:mem_req_addr <= {cpu_req_addr[29:4],2'b00};//get 128bits
					3'd2:mem_req_addr <= {cpu_req_addr[29:4],2'b01};
					3'd4:mem_req_addr <= {cpu_req_addr[29:4],2'b10};
					3'd6:mem_req_addr <= {cpu_req_addr[29:4],2'b11};
					default:mem_req_addr <= mem_req_addr;
				endcase
			end
			if(mem_resp_valid) begin
				cache_data_WB1 <= 0;	//write
				cache_data_WB2 <= 0;	//write
				case(cycle_count_4words)
					1'b0: begin
						cache_data_addr1 <= cpu_addr_index*16+cpu_req_addr[3:2]*4;
						cache_write_data1 <= mem_resp_data[31:0];
						cache_data_addr2 <= cpu_addr_index*16+cpu_req_addr[3:2]*4+1;
						cache_write_data2 <= mem_resp_data[63:32];
						mem_req_valid <= 0;
					end
					1'b1: begin
						cache_data_addr1 <= cpu_addr_index*16+cpu_req_addr[3:2]*4+2;
						cache_write_data1 <= mem_resp_data[95:64];
						cache_data_addr2 <= cpu_addr_index*16+cpu_req_addr[3:2]*4+3;
						cache_write_data1 <= mem_resp_data[127:96];
						mem_req_valid <= 1;
					end
				endcase
			if(cycle_count == 7) begin
				cache_tag_WEB1 <= 0;	//write
				cache_write_tag1 <= cpu_addr_tag;
			end
				cycle_count_4words <= cycle_count_4words+1;
				cycle_count <= cycle_count+1;
			end
		end
	endcase
end


generate
	case(WAY)
		1: begin
			SRAM2RW16x32M tag_cache(	.A1({1'b0,cpu_addr_index}),.A2(),
							.CE1(clk),.CE2(clk),.WEB1(cache_tag_WEB1),.WEB2(),	//addr_0-7 -8lines
						  	.OEB1(1'b0),.OEB2(1'b0),.CSB1(1'b0),.CSB2(1'b0),		//[22:0]-cpu_addr_tag
							.BYTEMASK1(4'd0),.BYTEMASK2(4'd0),.I1(cache_write_tag1),.I2(cache_write_tag2),
							.O1(sram_tag),.O2()	);

			SRAM2RW128x32M data_cache_inst(	
				.A1(cache_data_addr1),.A2(cache_data_addr2),
				.CE1(),.CE2(clk),
				.WEB1(cache_data_WB1),.WEB2(cache_data_WB2),
				.OEB1(1'b0),.OEB2(1'b0),
				.CSB1(1'b0),.CSB2(1'b0),
				.BYTEMASK1(4'd0),.BYTEMASK2(4'd0),
				.I1(cache_write_data1),.I2(cache_write_data2),
				.O1(cache_read_data1),.O2()	
			);
		end
	endcase
endgenerate









endmodule
