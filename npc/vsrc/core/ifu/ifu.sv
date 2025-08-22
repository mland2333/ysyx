/* import "DPI-C" function int inst_fetch(input int addr); */
`include "common_config.sv"
module ysyx_24110006_IFU (
    input i_clock,
    input i_reset,
    output pipe::ifu2idu_t to_idu,
    if_icache_rq.master o_icache_rq,
    input i_flush,
    input i_fencei,
    input i_dcache_fencei_fin,
    if_rq_bp.out rq_bp,
    input bp::result_t bp_result,
    if_pipeline_vr.out o_vr
);
  logic [31:0] pc;
  bp::info_t bp_info;
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
      pc <= bp_result.taken ? bp_result.upc : bp_result.pc + 4;
    end else if (i_fencei) begin
      pc <= bp_result.pc + 4;
    end else if (o_icache_rq.rq && o_icache_rq.cache_ready) begin
      if (rq_bp.pred_taken) pc <= rq_bp.upc;
      else if (pc[3:2] == 2'b11) pc <= pc + 4;
      else pc <= pc + 8;
    end
  end
  logic rq_icache;
  always_ff @(posedge i_clock) begin
    if (i_reset) rq_icache <= 0;
    else if (o_vr.ready) rq_icache <= 1;
    else if (o_icache_rq.rq && o_icache_rq.cache_ready) rq_icache <= 0;
  end

  logic [1:0] rq_vector;
  always_ff @(posedge i_clock) begin
    if (i_reset) rq_vector <= 0;
    else begin
      if (!(o_icache_rq.rq && o_icache_rq.cache_ready && o_icache_rq.valid && o_vr.ready)) begin
        rq_vector[1] <= o_icache_rq.rq && o_icache_rq.cache_ready ? rq_vector[0] : o_icache_rq.valid && o_vr.ready ? 0 : rq_vector[1];
        rq_vector[0] <= o_icache_rq.rq && o_icache_rq.cache_ready ? 1 : o_icache_rq.valid && o_vr.ready && !rq_vector[1] ? 0 : rq_vector[0];
      end
    end
  end
  logic in_flush;
  always_ff @(posedge i_clock) begin
    if (i_reset) in_flush <= 0;
    else if (i_flush && rq_vector != 0) in_flush <= 1;
    else if (in_flush && rq_vector == 0) in_flush <= 0;
  end
  assign o_icache_rq.rq = rq_icache && !i_flush && !in_flush;
  assign o_icache_rq.ready = o_vr.ready;
  assign o_icache_rq.addr = pc;
  assign o_icache_rq.flush = i_fencei;
  assign o_icache_rq.bp_info_in.d1.pred_taken = rq_bp.pred_taken;
  assign o_icache_rq.bp_info_in.d1.pred_pc = rq_bp.upc;
  assign o_icache_rq.bp_info_in.d2.pred_taken = rq_bp.pred_taken;
  assign o_icache_rq.bp_info_in.d2.pred_pc = rq_bp.upc;
  assign rq_bp.pc = pc;
  logic [31:0] imm1, imm2;
  assign o_vr.valid = o_icache_rq.valid && !i_flush && !in_flush;
  pipe::ifu2idu_single_t to_idu1, to_idu2;
  assign to_idu1.inst = o_icache_rq.rdata1;
  assign to_idu1.pc = o_icache_rq.pc;
  assign to_idu1.exception = 0;
  assign to_idu1.mcause = 0;
  assign to_idu1.imm = imm1;
  assign to_idu1.bp_info = o_icache_rq.bp_info_out.d1;

  assign to_idu2.inst = o_icache_rq.rdata2;
  assign to_idu2.pc = o_icache_rq.pc + 4;
  assign to_idu2.exception = 0;
  assign to_idu2.mcause = 0;
  assign to_idu2.imm = imm2;
  assign to_idu2.bp_info = o_icache_rq.bp_info_out.d2;
  assign to_idu.d1 = to_idu1;
  assign to_idu.d2 = to_idu2;
  assign to_idu.inst_valid[0] = 1;
  assign to_idu.inst_valid[1] = !o_icache_rq.bp_info_out.d1.pred_taken && o_icache_rq.pc[3:2] != 2'b11;
  ysyx_24110006_IMM mimm1 (
      .i_inst(o_icache_rq.rdata1),
      .o_imm (imm1)
  );
  ysyx_24110006_IMM mimm2 (
      .i_inst(o_icache_rq.rdata2),
      .o_imm (imm2)
  );

endmodule
