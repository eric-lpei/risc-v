`timescale 1ns/1ps

`include "const.vh"
`include "Opcode.vh"
`define FNC7_0  7'b0000000 // ADD, SRL
`define FNC7_1  7'b0100000 // SUB, SRA
`define OPC_CSR 7'b1110011

// TODO: change CPU.rf to the correct path of your RegFile
// instantiation in Riscv151.v

module Riscv151_testbench();
    reg clk, rst;
    parameter CPU_CLOCK_PERIOD = 2;
    parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

    initial clk = 0;
    always #(CPU_CLOCK_PERIOD/2) clk = ~clk;
    wire [31:0] csr;

    wire [31:0]  dcache_addr, icache_addr;
    wire [3:0]   dcache_we;
    wire         dcache_re, icache_re;
    wire [31:0]  dcache_din;
    wire [31:0]  dcache_dout, icache_dout;
    reg          stall;

    Riscv151 CPU (
        .clk(clk),
        .reset(rst),
        .dcache_addr(dcache_addr), // output
        .icache_addr(icache_addr), // output
        .dcache_we(dcache_we),     // output
        .dcache_re(dcache_re),     // output
        .icache_re(icache_re),     // output
        .dcache_din(dcache_din),   // output
        .dcache_dout(dcache_dout), // input
        .icache_dout(icache_dout), // input
        .stall(stall),             // input
        .csr(csr)                  // output
    );

    wire cpu_icache_req_valid = icache_re;
    wire cpu_dcache_req_valid = dcache_re | (|(dcache_we));

    // Simpler memory model than no_cache_mem or cache
    // One-cycle R/W latency
    // Word size is 32-bit
    SYNC_RAM_WBE #(
        .AWIDTH(32 - 2),
        .DWIDTH(32),
        .DEPTH(16384)
    ) imem (
        .clk(clk),
        .rst(rst),
        .d(),
        .q(icache_dout),
        .addr(cpu_icache_req_valid ? icache_addr[31:2] : 30'hx),
        .wbe(4'b0)
    );

    // Simpler memory model than no_cache_mem or cache
    // One-cycle R/W latency
    // Word-size is 32-bit
    SYNC_RAM_WBE #(
        .AWIDTH(32 - 2),
        .DWIDTH(32),
        .DEPTH(16384)
    ) dmem (
        .clk(clk),
        .rst(rst),
        .d(dcache_din),
        .q(dcache_dout),
        .addr(cpu_dcache_req_valid ? dcache_addr[31:2] : 30'hx),
        .wbe(dcache_we)
    );

    wire [31:0] timeout_cycle = 5000;

    // Reset IMem, DMem, and RegFile before running new test
    task resets;
        integer i;
        begin
            for (i = 0; i < imem.DEPTH; i = i + 1) begin
                imem.mem[i] = 0;
            end
            for (i = 0; i < dmem.DEPTH; i = i + 1) begin
                dmem.mem[i] = 0;
            end
            for (i = 0; i < CPU.rf.DEPTH; i = i + 1) begin
                CPU.rf.mem[i] = 0;
            end

            rst = 1;
            @(negedge clk);
            rst = 0;
        end
    endtask

    task init_rf;
        integer i;
        begin
            for (i = 1; i < CPU.rf.DEPTH; i = i + 1) begin
                CPU.rf.mem[i] = 100 * i;
            end
        end
    endtask

    reg [31:0] cycle;
    reg done;
    reg [31:0]  current_test_id = 0;
    reg [255:0] current_test_type;
    reg [31:0]  current_output;
    reg [31:0]  current_result;
    reg all_tests_passed = 0;

    // Check for timeout
    // If a test does not return correct value in a given timeout cycle,
    // we terminate the testbench
    initial begin
        while (all_tests_passed == 0) begin
            @(posedge clk);
            if (cycle == timeout_cycle) begin
                $display("[Failed] Timeout at [%d] test %s, expected_result = %h, got = %h",
                         current_test_id, current_test_type, current_result, current_output);
                $dumpoff;
                $finish();
            end
        end
    end

    always @(posedge clk) begin
        if (done == 0)
            cycle <= cycle + 1;
        else
            cycle <= 0;
    end

    // Check result of RegFile
    // If the write_back (destination) register has correct value (matches "result"), test passed
    // This is used to test instructions that update RegFile
    task check_result_rf;
        input [31:0]  rf_wa;
        input [31:0]  result;
        input [255:0] test_type;
        begin
            done = 0;
            current_test_id   = current_test_id + 1;
            current_test_type = test_type;
            current_result    = result;
            while (CPU.rf.mem[rf_wa] !== result) begin
                current_output = CPU.rf.mem[rf_wa];
                @(posedge clk);
            end
            done = 1;
            $display("[%d] Test %s passed!", current_test_id, test_type);
        end
    endtask

    // Check result of DMem
    // If the memory location of DMem has correct value (matches "result"), test passed
    // This is used to test store instructions
    task check_result_dmem;
        input [31:0]  addr;
        input [31:0]  result;
        input [255:0] test_type;
        begin
            done = 0;
            current_test_id   = current_test_id + 1;
            current_test_type = test_type;
            current_result    = result;
            while (dmem.mem[addr] !== result) begin
                current_output = dmem.mem[addr];
                @(posedge clk);
            end
            done = 1;
           $display("[%d] Test %s passed!", current_test_id, test_type);
        end
    endtask

    integer i;

    reg [31:0] num_cycles      = 0;
    reg [31:0] num_pipe_stages = 0;
    reg [31:0] num_insts       = 0;
    reg [4:0]  RD, RS1, RS2;
    reg [31:0] RD1, RD2;
    reg [4:0]  SHAMT;
    reg [31:0] IMM, IMM0, IMM1, IMM2, IMM3;
    reg [31-2:0] INST_ADDR;
    reg [31-2:0] DATA_ADDR;
    reg [31-2:0] DATA_ADDR0, DATA_ADDR1, DATA_ADDR2, DATA_ADDR3;
    reg [31-2:0] DATA_ADDR4, DATA_ADDR5, DATA_ADDR6, DATA_ADDR7;
    reg [31-2:0] DATA_ADDR8, DATA_ADDR9;

    reg [31:0] JUMP_ADDR;

    reg [31:0]  BR_TAKEN_OP1  [5:0];
    reg [31:0]  BR_TAKEN_OP2  [5:0];
    reg [31:0]  BR_NTAKEN_OP1 [5:0];
    reg [31:0]  BR_NTAKEN_OP2 [5:0];
    reg [2:0]   BR_TYPE       [5:0];
    reg [255:0] BR_NAME_TK1   [5:0];
    reg [255:0] BR_NAME_TK2   [5:0];
    reg [255:0] BR_NAME_NTK   [5:0];

    initial begin
        $dumpfile("Riscv151.vcd");
        $dumpvars(0, CPU);
        $dumpon;

        rst = 0;
        stall = 1'b0;

        // Reset the CPU
        rst = 1;
        // Hold reset for a while
        repeat (10) @(negedge clk);
        rst = 0;

        // Test R-Type Insts --------------------------------------------------
        // - ADD, SUB, SLL, SLT, SLTU, XOR, OR, AND, SRL, SRA
        // - SLLI, SRLI, SRAI
        resets();

        // We can also use $random to generate random values for testing
        RS1 = 1; RD1 = -100;
        RS2 = 2; RD2 =  200;
        RD  = 3;
        CPU.rf.mem[RS1] = RD1;
        CPU.rf.mem[RS2] = RD2;
        SHAMT           = 5'd20;
        INST_ADDR       = `PC_RESET >> 2;

        imem.mem[INST_ADDR + 0]  = {`FNC7_0, RS2,   RS1, `FNC_ADD_SUB, 5'd3,  `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1]  = {`FNC7_1, RS2,   RS1, `FNC_ADD_SUB, 5'd4,  `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 2]  = {`FNC7_0, RS2,   RS1, `FNC_SLL,     5'd5,  `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 3]  = {`FNC7_0, RS2,   RS1, `FNC_SLT,     5'd6,  `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 4]  = {`FNC7_0, RS2,   RS1, `FNC_SLTU,    5'd7,  `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 5]  = {`FNC7_0, RS2,   RS1, `FNC_XOR,     5'd8,  `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 6]  = {`FNC7_0, RS2,   RS1, `FNC_OR,      5'd9,  `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 7]  = {`FNC7_0, RS2,   RS1, `FNC_AND,     5'd10, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 8]  = {`FNC7_0, RS2,   RS1, `FNC_SRL_SRA, 5'd11, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 9]  = {`FNC7_1, RS2,   RS1, `FNC_SRL_SRA, 5'd12, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 10] = {`FNC7_0, SHAMT, RS1, `FNC_SLL,     5'd13, `OPC_ARI_ITYPE};
        imem.mem[INST_ADDR + 11] = {`FNC7_0, SHAMT, RS1, `FNC_SRL_SRA, 5'd14, `OPC_ARI_ITYPE};
        imem.mem[INST_ADDR + 12] = {`FNC7_1, SHAMT, RS1, `FNC_SRL_SRA, 5'd15, `OPC_ARI_ITYPE};

        check_result_rf(5'd3,  32'h00000064, "R-Type ADD");
        check_result_rf(5'd4,  32'hfffffed4, "R-Type SUB");
        check_result_rf(5'd5,  32'hffff9c00, "R-Type SLL");
        check_result_rf(5'd6,  32'h1,        "R-Type SLT");
        check_result_rf(5'd7,  32'h0,        "R-Type SLTU");
        check_result_rf(5'd8,  32'hffffff54, "R-Type XOR");
        check_result_rf(5'd9,  32'hffffffdc, "R-Type OR");
        check_result_rf(5'd10, 32'h00000088, "R-Type AND");
        check_result_rf(5'd11, 32'h00ffffff, "R-Type SRL");
        check_result_rf(5'd12, 32'hffffffff, "R-Type SRA");
        check_result_rf(5'd13, 32'hf9c00000, "R-Type SLLI");
        check_result_rf(5'd14, 32'h00000fff, "R-Type SRLI");
        check_result_rf(5'd15, 32'hffffffff, "R-Type SRAI");

        // Test I-Type Insts --------------------------------------------------
        // - ADDI, SLTI, SLTUI, XORI, ORI, ANDI
        // - LW, LH, LB, LHU, LBU
        // - JALR

        // Test I-type arithmetic instructions
        resets();

        RS1 = 1; RD1 = -100;
        CPU.rf.mem[RS1] = RD1;
        IMM             = -200;
        INST_ADDR       = `PC_RESET >> 2;

        imem.mem[INST_ADDR + 0] = {IMM[11:0], RS1, `FNC_ADD_SUB, 5'd3, `OPC_ARI_ITYPE};
        imem.mem[INST_ADDR + 1] = {IMM[11:0], RS1, `FNC_SLT,     5'd4, `OPC_ARI_ITYPE};
        imem.mem[INST_ADDR + 2] = {IMM[11:0], RS1, `FNC_SLTU,    5'd5, `OPC_ARI_ITYPE};
        imem.mem[INST_ADDR + 3] = {IMM[11:0], RS1, `FNC_XOR,     5'd6, `OPC_ARI_ITYPE};
        imem.mem[INST_ADDR + 4] = {IMM[11:0], RS1, `FNC_OR,      5'd7, `OPC_ARI_ITYPE};
        imem.mem[INST_ADDR + 5] = {IMM[11:0], RS1, `FNC_AND,     5'd8, `OPC_ARI_ITYPE};

        check_result_rf(5'd3,  32'hfffffed4, "I-Type ADD");
        check_result_rf(5'd4,  32'h00000000, "I-Type SLT");
        check_result_rf(5'd5,  32'h00000000, "I-Type SLTU");
        check_result_rf(5'd6,  32'h000000a4, "I-Type XOR");
        check_result_rf(5'd7,  32'hffffffbc, "I-Type OR");
        check_result_rf(5'd8,  32'hffffff18, "I-Type AND");

        // Test I-type load instructions
        resets();

        CPU.rf.mem[1]   = 32'h0000_0100;
        IMM0            = 32'h0000_0004;
        IMM1            = 32'h0000_0005;
        IMM2            = 32'h0000_0006;
        IMM3            = 32'h0000_0007;
        INST_ADDR       = `PC_RESET >> 2;
        DATA_ADDR       = ($signed(CPU.rf.mem[1]) + $signed(IMM0[11:0])) >> 2;

        imem.mem[INST_ADDR + 0]  = {IMM0[11:0], 5'd1, `FNC_LW,  5'd2,  `OPC_LOAD};
        imem.mem[INST_ADDR + 1]  = {IMM0[11:0], 5'd1, `FNC_LH,  5'd3,  `OPC_LOAD};
        imem.mem[INST_ADDR + 2]  = {IMM1[11:0], 5'd1, `FNC_LH,  5'd4,  `OPC_LOAD};
        imem.mem[INST_ADDR + 3]  = {IMM2[11:0], 5'd1, `FNC_LH,  5'd5,  `OPC_LOAD};
        imem.mem[INST_ADDR + 4]  = {IMM3[11:0], 5'd1, `FNC_LH,  5'd6,  `OPC_LOAD};
        imem.mem[INST_ADDR + 5]  = {IMM0[11:0], 5'd1, `FNC_LB,  5'd7,  `OPC_LOAD};
        imem.mem[INST_ADDR + 6]  = {IMM1[11:0], 5'd1, `FNC_LB,  5'd8,  `OPC_LOAD};
        imem.mem[INST_ADDR + 7]  = {IMM2[11:0], 5'd1, `FNC_LB,  5'd9,  `OPC_LOAD};
        imem.mem[INST_ADDR + 8]  = {IMM3[11:0], 5'd1, `FNC_LB,  5'd10, `OPC_LOAD};
        imem.mem[INST_ADDR + 9]  = {IMM0[11:0], 5'd1, `FNC_LHU, 5'd11, `OPC_LOAD};
        imem.mem[INST_ADDR + 10] = {IMM1[11:0], 5'd1, `FNC_LHU, 5'd12, `OPC_LOAD};
        imem.mem[INST_ADDR + 11] = {IMM2[11:0], 5'd1, `FNC_LHU, 5'd13, `OPC_LOAD};
        imem.mem[INST_ADDR + 12] = {IMM3[11:0], 5'd1, `FNC_LHU, 5'd14, `OPC_LOAD};
        imem.mem[INST_ADDR + 13] = {IMM0[11:0], 5'd1, `FNC_LBU, 5'd15, `OPC_LOAD};
        imem.mem[INST_ADDR + 14] = {IMM1[11:0], 5'd1, `FNC_LBU, 5'd16, `OPC_LOAD};
        imem.mem[INST_ADDR + 15] = {IMM2[11:0], 5'd1, `FNC_LBU, 5'd17, `OPC_LOAD};
        imem.mem[INST_ADDR + 16] = {IMM3[11:0], 5'd1, `FNC_LBU, 5'd18, `OPC_LOAD};

        dmem.mem[DATA_ADDR] = 32'hdeadbeef;

        check_result_rf(5'd2,   32'hdeadbeef, "I-Type LW");

        check_result_rf(5'd3,   32'hffffbeef, "I-Type LH 0");
        check_result_rf(5'd4,   32'hffffadbe, "I-Type LH 1");
        check_result_rf(5'd5,   32'hffffdead, "I-Type LH 2");
        check_result_rf(5'd6,   32'hffffdead, "I-Type LH 3");

        check_result_rf(5'd7,   32'hffffffef, "I-Type LB 0");
        check_result_rf(5'd8,   32'hffffffbe, "I-Type LB 1");
        check_result_rf(5'd9,   32'hffffffad, "I-Type LB 2");
        check_result_rf(5'd10,  32'hffffffde, "I-Type LB 3");

        check_result_rf(5'd11,  32'h0000beef, "I-Type LHU 0");
        check_result_rf(5'd12,  32'h0000adbe, "I-Type LHU 1");
        check_result_rf(5'd13,  32'h0000dead, "I-Type LHU 2");
        check_result_rf(5'd14,  32'h0000dead, "I-Type LHU 3");

        check_result_rf(5'd15,  32'h000000ef, "I-Type LBU 0");
        check_result_rf(5'd16,  32'h000000be, "I-Type LBU 1");
        check_result_rf(5'd17,  32'h000000ad, "I-Type LBU 2");
        check_result_rf(5'd18,  32'h000000de, "I-Type LBU 3");

        // Test S-Type Insts --------------------------------------------------
        // - SW, SH, SB

        resets();

        CPU.rf.mem[1]  = 32'h12345678;

        CPU.rf.mem[2]  = 32'h0000_1010;

        CPU.rf.mem[3]  = 32'h0000_1020;
        CPU.rf.mem[4]  = 32'h0000_1030;
        CPU.rf.mem[5]  = 32'h0000_1040;
        CPU.rf.mem[6]  = 32'h0000_1050;

        CPU.rf.mem[7]  = 32'h0000_1060;
        CPU.rf.mem[8]  = 32'h0000_1070;
        CPU.rf.mem[9]  = 32'h0000_1080;
        CPU.rf.mem[10] = 32'h0000_1090;

        IMM0            = 32'h0000_0100;
        IMM1            = 32'h0000_0101;
        IMM2            = 32'h0000_0102;
        IMM3            = 32'h0000_0103;

        INST_ADDR       = `PC_RESET >> 2;

        DATA_ADDR0      = ($signed(CPU.rf.mem[2])  + $signed(IMM0[11:0])) >> 2;

        DATA_ADDR1      = ($signed(CPU.rf.mem[3])  + $signed(IMM0[11:0])) >> 2;
        DATA_ADDR2      = ($signed(CPU.rf.mem[4])  + $signed(IMM1[11:0])) >> 2;
        DATA_ADDR3      = ($signed(CPU.rf.mem[5])  + $signed(IMM2[11:0])) >> 2;
        DATA_ADDR4      = ($signed(CPU.rf.mem[6])  + $signed(IMM3[11:0])) >> 2;

        DATA_ADDR5      = ($signed(CPU.rf.mem[7])  + $signed(IMM0[11:0])) >> 2;
        DATA_ADDR6      = ($signed(CPU.rf.mem[8])  + $signed(IMM1[11:0])) >> 2;
        DATA_ADDR7      = ($signed(CPU.rf.mem[9])  + $signed(IMM2[11:0])) >> 2;
        DATA_ADDR8      = ($signed(CPU.rf.mem[10]) + $signed(IMM3[11:0])) >> 2;

        imem.mem[INST_ADDR + 0] = {IMM0[11:5], 5'd1, 5'd2,  `FNC_SW, IMM0[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 1] = {IMM0[11:5], 5'd1, 5'd3,  `FNC_SH, IMM0[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 2] = {IMM1[11:5], 5'd1, 5'd4,  `FNC_SH, IMM1[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 3] = {IMM2[11:5], 5'd1, 5'd5,  `FNC_SH, IMM2[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 4] = {IMM3[11:5], 5'd1, 5'd6,  `FNC_SH, IMM3[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 5] = {IMM0[11:5], 5'd1, 5'd7,  `FNC_SB, IMM0[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 6] = {IMM1[11:5], 5'd1, 5'd8,  `FNC_SB, IMM1[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 7] = {IMM2[11:5], 5'd1, 5'd9,  `FNC_SB, IMM2[4:0], `OPC_STORE};
        imem.mem[INST_ADDR + 8] = {IMM3[11:5], 5'd1, 5'd10, `FNC_SB, IMM3[4:0], `OPC_STORE};

        dmem.mem[DATA_ADDR0]    = 0;
        dmem.mem[DATA_ADDR1]    = 0;
        dmem.mem[DATA_ADDR3]    = 0;
        dmem.mem[DATA_ADDR4]    = 0;
        dmem.mem[DATA_ADDR5]    = 0;
        dmem.mem[DATA_ADDR6]    = 0;
        dmem.mem[DATA_ADDR7]    = 0;
        dmem.mem[DATA_ADDR8]    = 0;

        check_result_dmem(DATA_ADDR0, 32'h12345678, "S-Type SW");

        check_result_dmem(DATA_ADDR1, 32'h00005678, "S-Type SH 1");
        check_result_dmem(DATA_ADDR2, 32'h00567800, "S-Type SH 2");
        check_result_dmem(DATA_ADDR3, 32'h56780000, "S-Type SH 3");
        check_result_dmem(DATA_ADDR4, 32'h56780000, "S-Type SH 4");

        check_result_dmem(DATA_ADDR5, 32'h00000078, "S-Type SB 1");
        check_result_dmem(DATA_ADDR6, 32'h00007800, "S-Type SB 2");
        check_result_dmem(DATA_ADDR7, 32'h00780000, "S-Type SB 3");
        check_result_dmem(DATA_ADDR8, 32'h78000000, "S-Type SB 4");

        // Test U-Type Insts --------------------------------------------------
        // - LUI, AUIPC
        resets();

        IMM = 32'h7FFF_0123;
        INST_ADDR = `PC_RESET >> 2;

        imem.mem[INST_ADDR + 0] = {IMM[31:12], 5'd3, `OPC_LUI};
        imem.mem[INST_ADDR + 1] = {IMM[31:12], 5'd4, `OPC_AUIPC};

        check_result_rf(5'd3,  32'h7fff0000, "U-Type LUI");
        check_result_rf(5'd4,  32'h7fff2004, "U-Type AUIPC");

        // Test J-Type Insts --------------------------------------------------
        // - JAL
        resets();

        CPU.rf.mem[1] = 100;
        CPU.rf.mem[2] = 200;
        CPU.rf.mem[3] = 300;
        CPU.rf.mem[4] = 400;

        IMM       = 32'h0000_07F0;
        INST_ADDR = `PC_RESET >> 2;
        JUMP_ADDR = ($signed(`PC_RESET) + $signed({IMM[20:1], 1'b0})) >> 2;

        imem.mem[INST_ADDR + 0]   = {IMM[20], IMM[10:1], IMM[11], IMM[19:12], 5'd5, `OPC_JAL};
        imem.mem[INST_ADDR + 1]   = {`FNC7_0, 5'd2, 5'd1, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};
        imem.mem[JUMP_ADDR[13:0]] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd7, `OPC_ARI_RTYPE};

        check_result_rf(5'd5, 32'h0000_2004, "J-Type JAL 1");
        check_result_rf(5'd6, 0, "J-Type JAL 2");
        check_result_rf(5'd7, 700, "J-Type JAL 3");

        // Test I-Type JALR Insts ---------------------------------------------
        resets();

        CPU.rf.mem[1] = 32'h0000_0100;
        CPU.rf.mem[2] = 200;
        CPU.rf.mem[3] = 300;
        CPU.rf.mem[4] = 400;

        IMM       = 32'h0000_0FF0;
        INST_ADDR = `PC_RESET >> 2;
        // Fix: IMM[11:0] should be sign-extended here.
        // We need to wrap both LHS and RHS because Verilog only does signed
        // addition when both operands are signed typed.  Declaring IMM as
        // signed is not sufficient because taking bits using part-select
        // yields an unsigned result.
        // Apply this to all other JUMP_ADDR and DATA_ADDR calculations
        // because we always want signed addition for those.
        JUMP_ADDR = ($signed(CPU.rf.mem[1]) + $signed(IMM[11:0])) >> 2;

        imem.mem[INST_ADDR + 0]   = {IMM[11:0], 5'd1, 3'b000, 5'd5, `OPC_JALR};
        imem.mem[INST_ADDR + 1]   = {`FNC7_0, 5'd2, 5'd1, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};
        imem.mem[JUMP_ADDR[13:0]] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd7, `OPC_ARI_RTYPE};

        check_result_rf(5'd5, 32'h0000_2004, "J-Type JALR 1");
        check_result_rf(5'd6, 0, "J-Type JALR 2");
        check_result_rf(5'd7, 700, "J-Type JALR 3");

        // Test B-Type Insts --------------------------------------------------
        // - BEQ, BNE, BLT, BGE, BLTU, BGEU

        IMM       = 32'h0000_0FF0;
        INST_ADDR = `PC_RESET >> 2;
        JUMP_ADDR = ($signed(`PC_RESET) + $signed(IMM[12:0])) >> 2;

        BR_TYPE[0]     = `FNC_BEQ;
        BR_NAME_TK1[0] = "U-Type BEQ Taken 1";
        BR_NAME_TK2[0] = "U-Type BEQ Taken 2";
        BR_NAME_NTK[0] = "U-Type BEQ Not Taken";

        BR_TAKEN_OP1[0]  = 100; BR_TAKEN_OP2[0]  = 100;
        BR_NTAKEN_OP1[0] = 100; BR_NTAKEN_OP2[0] = 200;

        BR_TYPE[1]       = `FNC_BNE;
        BR_NAME_TK1[1]   = "U-Type BNE Taken 1";
        BR_NAME_TK2[1]   = "U-Type BNE Taken 2";
        BR_NAME_NTK[1]   = "U-Type BNE Not Taken";
        BR_TAKEN_OP1[1]  = 100; BR_TAKEN_OP2[1]  = 200;
        BR_NTAKEN_OP1[1] = 100; BR_NTAKEN_OP2[1] = 100;

        BR_TYPE[2]       = `FNC_BLT;
        BR_NAME_TK1[2]   = "U-Type BLT Taken 1";
        BR_NAME_TK2[2]   = "U-Type BLT Taken 2";
        BR_NAME_NTK[2]   = "U-Type BLT Not Taken";
        BR_TAKEN_OP1[2]  = 100; BR_TAKEN_OP2[2]  = 200;
        BR_NTAKEN_OP1[2] = 200; BR_NTAKEN_OP2[2] = 100;

        BR_TYPE[3]       = `FNC_BGE;
        BR_NAME_TK1[3]   = "U-Type BGE Taken 1";
        BR_NAME_TK2[3]   = "U-Type BGE Taken 2";
        BR_NAME_NTK[3]   = "U-Type BGE Not Taken";
        BR_TAKEN_OP1[3]  = 300; BR_TAKEN_OP2[3]  = 200;
        BR_NTAKEN_OP1[3] = 100; BR_NTAKEN_OP2[3] = 200;

        BR_TYPE[4]       = `FNC_BLTU;
        BR_NAME_TK1[4]   = "U-Type BLTU Taken 1";
        BR_NAME_TK2[4]   = "U-Type BLTU Taken 2";
        BR_NAME_NTK[4]   = "U-Type BLTU Not Taken";
        BR_TAKEN_OP1[4]  = 32'h0000_0001; BR_TAKEN_OP2[4]  = 32'hFFFF_0000;
        BR_NTAKEN_OP1[4] = 32'hFFFF_0000; BR_NTAKEN_OP2[4] = 32'h0000_0001;

        BR_TYPE[5]       = `FNC_BGEU;
        BR_NAME_TK1[5]   = "U-Type BGEU Taken 1";
        BR_NAME_TK2[5]   = "U-Type BGEU Taken 2";
        BR_NAME_NTK[5]   = "U-Type BGEU Not Taken";
        BR_TAKEN_OP1[5]  = 32'hFFFF_0000; BR_TAKEN_OP2[5]  = 32'h0000_0001;
        BR_NTAKEN_OP1[5] = 32'h0000_0001; BR_NTAKEN_OP2[5] = 32'hFFFF_0000;

        for (i = 0; i < 6; i = i + 1) begin
            resets();

            CPU.rf.mem[1] = BR_TAKEN_OP1[i];
            CPU.rf.mem[2] = BR_TAKEN_OP2[i];
            CPU.rf.mem[3] = 300;
            CPU.rf.mem[4] = 400;

            // Test branch taken
            imem.mem[INST_ADDR + 0]   = {IMM[12], IMM[10:5], 5'd2, 5'd1, BR_TYPE[i], IMM[4:1], IMM[11], `OPC_BRANCH};
            imem.mem[INST_ADDR + 1]   = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};
            imem.mem[JUMP_ADDR[13:0]] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};

            check_result_rf(5'd5, 0,   BR_NAME_TK1[i]);
            check_result_rf(5'd6, 700, BR_NAME_TK2[i]);

            resets();

            CPU.rf.mem[1] = BR_NTAKEN_OP1[i];
            CPU.rf.mem[2] = BR_NTAKEN_OP2[i];
            CPU.rf.mem[3] = 300;
            CPU.rf.mem[4] = 400;

            // Test branch not taken
            imem.mem[INST_ADDR + 0] = {IMM[12], IMM[10:5], 5'd2, 5'd1, BR_TYPE[i], IMM[4:1], IMM[11], `OPC_BRANCH};
            imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};

            check_result_rf(5'd5, 700, BR_NAME_NTK[i]);
        end

        // Test CSR Insts -----------------------------------------------------
        // - CSRRW, CSRRWI
        resets();

        CPU.rf.mem[1] = 100;
        IMM           = 5'd16;
        INST_ADDR     = `PC_RESET >> 2;

        imem.mem[INST_ADDR + 0] = {12'h51e, 5'd1, 3'b001, 5'd0, `OPC_CSR};
        imem.mem[INST_ADDR + 1] = {12'h51e, IMM[4:0],  3'b101, 5'd0, `OPC_CSR};

        current_test_id = current_test_id + 1;
        done = 0;
        while (!(csr == CPU.rf.mem[1])) begin
            @(posedge clk);
        end
        done = 1;

        $display("[%d] Test CSRRW passed!", current_test_id);

        current_test_id = current_test_id + 1;
        done = 0;
        while (!(csr == IMM)) begin
            @(posedge clk);
        end
        done = 1;

        $display("[%d] Test CSRRWI passed!", current_test_id);

        // Test Hazards -------------------------------------------------------
        // ALU->ALU hazard (RS1)
        resets();
        init_rf();
        INST_ADDR = `PC_RESET >> 2;

        imem.mem[INST_ADDR + 0] = {`FNC7_0, 5'd1, 5'd2, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd3, 5'd4, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};
        check_result_rf(5'd5, CPU.rf.mem[1] + CPU.rf.mem[2] + CPU.rf.mem[4], "Hazard 1");

        // ALU->ALU hazard (RS2)
        resets();
        init_rf();

        imem.mem[INST_ADDR + 0] = {`FNC7_0, 5'd1, 5'd2, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};
        check_result_rf(5'd5, CPU.rf.mem[1] + CPU.rf.mem[2] + CPU.rf.mem[4], "Hazard 2");

        // Two-cycle ALU->ALU hazard (RS1)
        resets();
        init_rf();

        imem.mem[INST_ADDR + 0] = {`FNC7_0, 5'd1, 5'd2, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd4, 5'd5, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 2] = {`FNC7_0, 5'd3, 5'd7, `FNC_ADD_SUB, 5'd8, `OPC_ARI_RTYPE};

        check_result_rf(5'd8, CPU.rf.mem[1] + CPU.rf.mem[2] + CPU.rf.mem[7], "Hazard 3");

        // Two-cycle ALU->ALU hazard (RS2)
        resets();
        init_rf();

        imem.mem[INST_ADDR + 0] = {`FNC7_0, 5'd1, 5'd2, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd4, 5'd5, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 2] = {`FNC7_0, 5'd7, 5'd3, `FNC_ADD_SUB, 5'd8, `OPC_ARI_RTYPE};

        check_result_rf(5'd8, CPU.rf.mem[1] + CPU.rf.mem[2] + CPU.rf.mem[7], "Hazard 4");

        // Two ALU hazards
        resets();
        init_rf();

        imem.mem[INST_ADDR + 0] = {`FNC7_0, 5'd1, 5'd2, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd4, 5'd3, `FNC_ADD_SUB, 5'd5, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 2] = {`FNC7_0, 5'd5, 5'd6, `FNC_ADD_SUB, 5'd7, `OPC_ARI_RTYPE};

        check_result_rf(5'd7, CPU.rf.mem[1] + CPU.rf.mem[2] + CPU.rf.mem[4] + CPU.rf.mem[6], "Hazard 5");

        // ALU->MEM hazard
        resets();
        init_rf();
        CPU.rf.mem[4]   = 32'h0000_0100;
        IMM             = 32'h0000_0000;
        DATA_ADDR       = ($signed(CPU.rf.mem[4]) + $signed(IMM[11:0])) >> 2;

        imem.mem[INST_ADDR + 0] = {`FNC7_0, 5'd1, 5'd2, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1] = {IMM[11:5], 5'd3, 5'd4, `FNC_SW, IMM[4:0], `OPC_STORE};

        check_result_dmem(DATA_ADDR, CPU.rf.mem[1] + CPU.rf.mem[2], "Hazard 6");

        // MEM->ALU hazard
        resets();
        init_rf();
        CPU.rf.mem[1]   = 32'h0000_0100;
        IMM             = 32'h0000_0000;
        DATA_ADDR       = ($signed(CPU.rf.mem[1]) + $signed(IMM[11:0])) >> 2;

        dmem.mem[DATA_ADDR] = 32'h1234_5678;
        imem.mem[INST_ADDR + 0] = {IMM[11:0], 5'd1, `FNC_LW, 5'd2, `OPC_LOAD};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd2, 5'd3, `FNC_ADD_SUB, 5'd4, `OPC_ARI_RTYPE};

        check_result_rf(5'd4, dmem.mem[DATA_ADDR] + CPU.rf.mem[3], "Hazard 7");

        // MEM->MEM hazard (store data)
        resets();
        init_rf();
        CPU.rf.mem[1]   = 32'h0000_0100;
        CPU.rf.mem[4]   = 32'h0000_0200;
        IMM             = 32'h0000_0000;

        DATA_ADDR0      = ($signed(CPU.rf.mem[1]) + $signed(IMM[11:0])) >> 2;
        DATA_ADDR1      = ($signed(CPU.rf.mem[4]) + $signed(IMM[11:0])) >> 2;

        dmem.mem[DATA_ADDR0] = 32'h1234_5678;
        imem.mem[INST_ADDR + 0] = {IMM[11:0], 5'd1, `FNC_LW, 5'd2, `OPC_LOAD};
        imem.mem[INST_ADDR + 1] = {IMM[11:5], 5'd2, 5'd4, `FNC_SW, IMM[4:0], `OPC_STORE};

        check_result_dmem(DATA_ADDR1, dmem.mem[DATA_ADDR0], "Hazard 8");

        // MEM->MEM hazard (store address)
        resets();
        init_rf();
        CPU.rf.mem[1]   = 32'h0000_0100;
        IMM             = 32'h0000_0000;
        DATA_ADDR0      = ($signed(CPU.rf.mem[1]) + $signed(IMM[11:0])) >> 2;
        dmem.mem[DATA_ADDR0] = 32'h0000_0200;
        DATA_ADDR1      = ($signed(dmem.mem[DATA_ADDR0][31:0]) + $signed(IMM[11:0])) >> 2;

        imem.mem[INST_ADDR + 0] = {IMM[11:0], 5'd1, `FNC_LW, 5'd2, `OPC_LOAD};
        imem.mem[INST_ADDR + 1] = {IMM[11:5], 5'd4, 5'd2, `FNC_SW, IMM[4:0], `OPC_STORE};

        check_result_dmem(DATA_ADDR1, CPU.rf.mem[4], "Hazard 9");

        // Hazard to Branch operands
        resets();
        init_rf();
        IMM       = 32'h0000_0FF0;
        JUMP_ADDR = ($signed(32'h0000_2008) + $signed(IMM[12:0])) >> 2; // note the PC address here

        imem.mem[INST_ADDR + 0]   = {`FNC7_0, 5'd1, 5'd4, `FNC_ADD_SUB, 5'd6, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 1]   = {`FNC7_0, 5'd2, 5'd3, `FNC_ADD_SUB, 5'd7, `OPC_ARI_RTYPE};
        imem.mem[INST_ADDR + 2]   = {IMM[12], IMM[10:5], 5'd6, 5'd7, `FNC_BEQ, IMM[4:1], IMM[11], `OPC_BRANCH}; // Branch will be taken
        imem.mem[INST_ADDR + 3]   = {`FNC7_0, 5'd8, 5'd9, `FNC_ADD_SUB, 5'd10, `OPC_ARI_RTYPE};
        imem.mem[JUMP_ADDR[13:0]] = {`FNC7_1, 5'd8, 5'd9, `FNC_ADD_SUB, 5'd11, `OPC_ARI_RTYPE};

        check_result_rf(5'd10, CPU.rf.mem[10], "Hazard 10 1"); // x10 should not be updated
        check_result_rf(5'd11, CPU.rf.mem[9] - CPU.rf.mem[8], "Hazard 10 2"); // x11 should be updated

        // JAL Writeback hazard
        resets();
        init_rf();
        IMM = 32'h0000_0004;

        imem.mem[INST_ADDR + 0] = {IMM[20], IMM[10:1], IMM[11], IMM[19:12], 5'd1, `OPC_JAL};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd2, 5'd1, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};

        check_result_rf(5'd3, CPU.rf.mem[2] + `PC_RESET + 4, "Hazard 11");

        // JALR Writeback hazard
        resets();
        init_rf();
        CPU.rf.mem[4] = 32'h0000_2000;
        IMM           = 32'h0000_0004;

        imem.mem[INST_ADDR + 0] = {IMM[11:0], 5'd4, 3'b000, 5'd1, `OPC_JALR};
        imem.mem[INST_ADDR + 1] = {`FNC7_0, 5'd2, 5'd1, `FNC_ADD_SUB, 5'd3, `OPC_ARI_RTYPE};

        check_result_rf(5'd3, CPU.rf.mem[2] + `PC_RESET + 4, "Hazard 12");

        // ... what else?


        all_tests_passed = 1'b1;
        #100;

        $dumpoff;
        $finish();

    end

   // Uncomment this always block to print out more information for debugging
//    always @(posedge clk) begin
//        $display("[At time %t, cycle=%d, test_id=%d, test_type=%s] pc=%h, cpu_inst=%h, imem_addrb=%h, dmem_addra=%h, rf_ra1=%d, rf_ra2=%d, rf_rd1=%h, rf_rd2=%h, rf_wa=%d, rf_wd=%h, rf_we=%b, csr=%d, test0=%h, test1=%h",
//            $time, cycle, current_test_id, current_test_type,
//            CPU.pc_reg0, CPU.cpu_inst, CPU.imem_addrb, CPU.dmem_addra,
//            CPU.rf_ra1, CPU.rf_ra2, CPU.rf_rd1, CPU.rf_rd2,
//            CPU.rf_wa,  CPU.rf_wd,  CPU.rf_we,
//            CPU.csr, imem[INST_ADDR + 0], imem[INST_ADDR + 1]);
//    end

endmodule
