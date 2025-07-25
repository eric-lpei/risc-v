`include "util.vh"
`include "const.vh"

module no_cache_mem #(
  parameter CPU_WIDTH      = `CPU_INST_BITS,//32
  parameter WORD_ADDR_BITS = `CPU_ADDR_BITS - `ceilLog2(`CPU_INST_BITS/8)//32-2
) (
  input clk,
  input reset,

  input                       cpu_req_valid,
  output                      cpu_req_ready,
  input [WORD_ADDR_BITS-1:0]  cpu_req_addr,//30bits
  input [CPU_WIDTH-1:0]       cpu_req_data,
  input [3:0]                 cpu_req_write,

  output reg                  cpu_resp_valid,
  output reg [CPU_WIDTH-1:0]  cpu_resp_data
);

  localparam DEPTH = 2*1024*1024;
  localparam WORDS = `MEM_DATA_BITS/CPU_WIDTH;//4

  reg [`MEM_DATA_BITS-1:0] ram [DEPTH-1:0];

  wire [WORD_ADDR_BITS-`ceilLog2(WORDS)-1:0] upper_addr;//28bits [27:0]
  assign upper_addr = cpu_req_addr[WORD_ADDR_BITS-1:`ceilLog2(WORDS)];//[29:2]

  wire [`ceilLog2(DEPTH)-1:0] ram_addr;
  assign ram_addr = upper_addr[`ceilLog2(DEPTH)-1:0];//[20:0]

  wire [`ceilLog2(WORDS)-1:0] lower_addr;
  assign lower_addr = cpu_req_addr[`ceilLog2(WORDS)-1:0];//[1:0]

  wire [`MEM_DATA_BITS-1:0] read_data;
  assign read_data = (ram[ram_addr] >> CPU_WIDTH*lower_addr);

  assign cpu_req_ready = 1'b1;

  wire [CPU_WIDTH-1:0] wmask;
  assign wmask = {{8{cpu_req_write[3]}},
                  {8{cpu_req_write[2]}},
                  {8{cpu_req_write[1]}},
                  {8{cpu_req_write[0]}}};

  wire [`MEM_DATA_BITS-1:0] write_data;
  assign write_data = (ram[ram_addr] & ~({{`MEM_DATA_BITS-CPU_WIDTH{1'b0}},wmask} << CPU_WIDTH*lower_addr)) | ((cpu_req_data & wmask) << CPU_WIDTH*lower_addr);

  always @(posedge clk) begin
    if (reset) 
      cpu_resp_valid <= 1'b0;
    else if (cpu_req_valid && cpu_req_ready) begin
      if (cpu_req_write) begin
        cpu_resp_valid <= 1'b0;
        ram[ram_addr] <= write_data;
      end else begin
        cpu_resp_valid <= 1'b1;
        cpu_resp_data <= read_data[CPU_WIDTH-1:0];
      end
    end else
      cpu_resp_valid <= 1'b0;
  end

  initial
  begin : zero
    integer i;
    for (i = 0; i < DEPTH; i = i + 1)
      ram[i] = 0;
  end

endmodule

