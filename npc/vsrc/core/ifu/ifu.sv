/* import "DPI-C" function int inst_fetch(input int addr); */
`include "common_config.sv"
module ysyx_24110006_IFU (
    input i_clock,
    input i_reset,
    output pipe::ifu2idu_t to_idu,
    /* if_btb_rq.master o_btb_rq, */
    if_icache_rq.master o_icache_rq,
    /* if_branch_ctrl.in i_branch_ctrl, */
    input i_flush,
    input i_fencei,
    input i_dcache_fencei_fin,
    input [31:0] i_pc,
    input [31:0] i_upc,

    if_pipeline_vr.out o_vr
);
  logic [31:0] pc;
  localparam MROM = 32'h20000000;
  localparam FLASH = 32'h30000000;
  localparam NPC_START = 32'h80000000;
`ifdef CONFIG_YSYXSOC
  localparam PC = FLASH;
`else
  localparam PC = NPC_START;
`endif
  always_ff @(posedge i_clock) begin
    if (i_reset) pc <= PC;
    else if (i_flush) begin
      pc <= i_upc;
    end else if (i_fencei) begin
      pc <= i_pc + 4;
    end else if (o_icache_rq.rq && o_icache_rq.cache_ready) begin
      pc <= pc + 4;
    end
  end
  logic rq_icache;
  always_ff @(posedge i_clock) begin
    if (i_reset) rq_icache <= 0;
    else if(o_vr.ready) rq_icache <= 1;
    else if (o_icache_rq.rq && o_icache_rq.cache_ready) rq_icache <= 0;
  end

  logic [1:0] rq_vector;
  always_ff@(posedge i_clock)begin
    if(i_reset) rq_vector <= 0;
    else begin
      if(!(o_icache_rq.rq && o_icache_rq.cache_ready && o_icache_rq.valid))begin
        rq_vector[1] <= o_icache_rq.rq && o_icache_rq.cache_ready ? rq_vector[0] : o_icache_rq.valid ? 0 : rq_vector[1];
        rq_vector[0] <= o_icache_rq.rq && o_icache_rq.cache_ready ? 1 : o_icache_rq.valid && !rq_vector[1] ? 0 : rq_vector[0];
      end
    end
  end
  logic in_flush;
  always_ff@(posedge i_clock)begin
    if(i_reset) in_flush <= 0;
    else if(i_flush && rq_vector != 0) in_flush <= 1;
    else if(in_flush && rq_vector == 0) in_flush <= 0;
  end
  assign o_icache_rq.rq = rq_icache && !i_flush && !in_flush;
  assign o_icache_rq.ready = 1;
  assign o_icache_rq.addr  = pc;
  assign o_icache_rq.flush = i_fencei;
  logic [31:0] imm;
  assign o_vr.valid = o_icache_rq.valid && !i_flush && !in_flush;
  assign to_idu.inst = o_icache_rq.rdata;
  assign to_idu.pc = o_icache_rq.pc;
  assign to_idu.exception = 0;
  assign to_idu.mcause = 0;
  assign to_idu.imm = imm;
  ysyx_24110006_IMM mimm (
      .i_inst(o_icache_rq.rdata),
      .o_imm (imm)
  );

  /* assign to_idu = {rdata, pc, predict, exception, mcause}; */
endmodule
