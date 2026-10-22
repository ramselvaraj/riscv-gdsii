`timescale 1ns/1ps
module pipeline_cache_asic (
    input logic clk, reset,
    output logic imem_req_valid,
    input logic imem_req_ready,
    output logic [31:0] imem_req_addr,
    input logic imem_resp_valid,
    output logic imem_resp_ready,
    input logic [31:0] imem_resp_data,
    output logic dmem_req_valid,
    input logic dmem_req_ready,
    output logic [31:0] dmem_req_addr, dmem_req_data,
    output logic [3:0] dmem_req_strb,
    input logic dmem_resp_valid,
    output logic dmem_resp_ready,
    input logic [31:0] dmem_resp_data,
    output logic fault
);
    pipeline_cache #(
        .CACHE_LINES(4), .WORDS_PER_LINE(4),
        .DATA_WRITE_BACK(1), .BYPASS_ICACHE(0)
    ) cpu (
        .clk, .reset,
        .imem_req_valid, .imem_req_ready, .imem_req_addr,
        .imem_req_data(), .imem_req_strb(),
        .imem_resp_valid, .imem_resp_ready, .imem_resp_data,
        .dmem_req_valid, .dmem_req_ready, .dmem_req_addr,
        .dmem_req_data, .dmem_req_strb,
        .dmem_resp_valid, .dmem_resp_ready, .dmem_resp_data,
        .retire_valid(), .retire_write(), .retire_pc(),
        .retire_instruction(), .retire_data(), .retire_rd(),
        .cycles(), .retired(), .load_stalls(), .memory_stalls(),
        .fetch_stalls(), .redirects(), .branch_misses(),
        .icache_hits(), .icache_misses(), .dcache_hits(),
        .dcache_misses(), .dcache_writebacks(), .fault
    );
endmodule
