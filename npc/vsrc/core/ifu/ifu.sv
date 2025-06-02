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
`ifdef CONFIG_SIM
    output pipe::sim_t o_sim,
`endif
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
  logic in_flush;
  always_ff@(posedge i_clock)begin
    if(i_reset) in_flush <= 0;
    else if(i_flush && !o_icache_rq.valid) in_flush <= 1;
    else if(in_flush && o_icache_rq.valid) in_flush <= 0;
  end

  typedef enum logic [2:0] {
    idle, in_fencei, wait_dcache, wait_icache, fencei_fin
  } fencei_state_t;
  fencei_state_t state;
  always_ff@(posedge i_clock)begin
    if(i_reset) state <= idle;
    else begin
      unique case(state)
        idle:if(i_fencei) state <= in_fencei;
        in_fencei: if(o_icache_rq.flush_fin && i_dcache_fencei_fin) state <= fencei_fin;
                   else if(o_icache_rq.flush_fin) state <= wait_dcache;
                   else if(i_dcache_fencei_fin) state <= wait_icache;
        wait_dcache: if(i_dcache_fencei_fin) state <= fencei_fin;
        wait_icache: if(o_icache_rq.flush_fin) state <= fencei_fin;
        fencei_fin: state <= idle;
      endcase
    end
  end

  always_ff @(posedge i_clock) begin
    if (i_reset) pc <= PC;
    else if (i_flush) begin
      pc <= i_upc;
    end else if (i_fencei) begin
      pc <= i_pc + 4;
    end else if (o_icache_rq.valid && !(i_flush || in_flush)) begin
      pc <= pc + 4;
    end
  end

  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush || i_fencei) o_vr.valid <= 0;
    else if (o_icache_rq.valid && !(i_flush || in_flush)) o_vr.valid <= 1;
    else if (o_vr.valid && o_vr.ready) o_vr.valid <= 0;
  end
  logic reset;
  always_ff @(posedge i_clock) begin
    if (i_reset) reset <= i_reset;
    else reset <= 0;
  end
  always_ff @(posedge i_clock) begin
    if (i_reset || in_flush || state != idle) o_icache_rq.rq <= 0;
    else if (o_icache_rq.rq && o_icache_rq.cache_ready) o_icache_rq.rq <= 0;
    else if (o_icache_rq.cache_ready && o_vr.ready) o_icache_rq.rq <= 1;
  end
  assign o_icache_rq.ready = 1;
  assign o_icache_rq.addr  = pc;
  assign o_icache_rq.flush = i_fencei;

  logic [31:0] imm;
  logic [31:0] pc_pipeline;
  always_ff @(posedge i_clock) if (o_icache_rq.valid && !(i_flush || in_flush)) pc_pipeline <= pc;
  assign to_idu.inst = o_icache_rq.rdata;
  assign to_idu.pc = pc_pipeline;
  assign to_idu.exception = 0;
  assign to_idu.mcause = 0;
  assign to_idu.imm = imm;
  ysyx_24110006_IMM mimm (
      .i_inst(o_icache_rq.rdata),
      .o_imm (imm)
  );

`ifdef CONFIG_SIM
  assign o_sim.pc   = pc;
  assign o_sim.inst = o_icache_rq.rdata;
`endif
  /* assign to_idu = {rdata, pc, predict, exception, mcause}; */
endmodule
