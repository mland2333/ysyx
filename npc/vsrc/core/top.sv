`ifndef CONFIG_YOSYS
import "DPI-C" function void quit();
import "DPI-C" function void difftest();
import "DPI-C" function void diff_skip();
import "DPI-C" function void fetch_inst();
`endif
`include "alu_config.sv"
`include "common_config.sv"
module ysyx_24110006_top (
    input         clock,
`ifdef CONFIG_YSYXSOC
    input         io_interrupt,
    input         io_master_awready,
    output        io_master_awvalid,
    output [31:0] io_master_awaddr,
    output [ 3:0] io_master_awid,
    output [ 7:0] io_master_awlen,
    output [ 2:0] io_master_awsize,
    output [ 1:0] io_master_awburst,
    input         io_master_wready,
    output        io_master_wvalid,
    output [31:0] io_master_wdata,
    output [ 3:0] io_master_wstrb,
    output        io_master_wlast,
    output        io_master_bready,
    input         io_master_bvalid,
    input  [ 1:0] io_master_bresp,
    input  [ 3:0] io_master_bid,
    input         io_master_arready,
    output        io_master_arvalid,
    output [31:0] io_master_araddr,
    output [ 3:0] io_master_arid,
    output [ 7:0] io_master_arlen,
    output [ 2:0] io_master_arsize,
    output [ 1:0] io_master_arburst,
    output        io_master_rready,
    input         io_master_rvalid,
    input  [ 1:0] io_master_rresp,
    input  [31:0] io_master_rdata,
    input         io_master_rlast,
    input  [ 3:0] io_master_rid,

    output        io_slave_awready,
    input         io_slave_awvalid,
    input  [31:0] io_slave_awaddr,
    input  [ 3:0] io_slave_awid,
    input  [ 7:0] io_slave_awlen,
    input  [ 2:0] io_slave_awsize,
    input  [ 1:0] io_slave_awburst,
    output        io_slave_wready,
    input         io_slave_wvalid,
    input  [31:0] io_slave_wdata,
    input  [ 3:0] io_slave_wstrb,
    input         io_slave_wlast,
    input         io_slave_bready,
    output        io_slave_bvalid,
    output [ 1:0] io_slave_bresp,
    output [ 3:0] io_slave_bid,
    output        io_slave_arready,
    input         io_slave_arvalid,
    input  [31:0] io_slave_araddr,
    input  [ 3:0] io_slave_arid,
    input  [ 7:0] io_slave_arlen,
    input  [ 2:0] io_slave_arsize,
    input  [ 1:0] io_slave_arburst,
    input         io_slave_rready,
    output        io_slave_rvalid,
    output [ 1:0] io_slave_rresp,
    output [31:0] io_slave_rdata,
    output        io_slave_rlast,
    output [ 3:0] io_slave_rid,
`endif
    input         reset
);
  wire flush;
  wire stall;
  wire exception;
  wire branch;
  wire csr_flush;
  wire [31:0] upc;
  wire jal_btb_update;
  wire branch_btb_update;
  wire btb_update;
  wire predict_err;
  wire [31:0] btb_pc;
  wire wbu_valid;
  assign exception = wbu_valid & wbu_exception;
  assign branch = bru_vr_wbu.valid & bru_branch;
  assign csr_flush = bru_vr_wbu.valid & bru_csr_t[0];
  assign flush = exu_flush | exception | branch | csr_flush;
  assign upc = exception ? csr_upc : (branch | branch_btb_update | csr_flush) ? bru_upc : exu_upc;
  assign jal_btb_update = exu_btb_update;
  assign branch_btb_update = bru_btb_update & bru_vr_wbu.valid & branch;
  assign btb_update = jal_btb_update | branch_btb_update;
  assign predict_err = bru_predict_err & bru_vr_wbu.valid;
  assign btb_pc = (branch_btb_update | predict_err) ? bru_pc : (jal_btb_update | fencei) ? exu_pc : 0;
  wire [`BRANCH_MID] branch_mid;
  wire bru_branch;
  wire arbiter_ifu_read;
  wire ifu_predict, idu_predict, exu_predict, bru_predict;
  wire exu_btb_update, bru_btb_update;
  wire bru_predict_err;

  wire idu_mret;
  wire exu_flush;
  wire exu_cmp;
  wire exu_zero;
  wire exu_jump;
  wire exu_trap;
  wire exu_result_t;
  wire [3:0] exu_alu_t;

  wire [31:0] exu_result, bru_result, lsu_result, wbu_result;
  wire idu_reg_wen, exu_reg_wen, lsu_reg_wen, bru_reg_wen, wbu_reg_wen;

  wire [31:0] pc, ifu_pc, idu_pc, exu_pc, bru_pc, lsu_pc, wbu_pc;
  wire [31:0] exu_upc, bru_upc, csr_upc;

  wire [31:0] ifu_inst;
  wire [6:0] idu_op, exu_op, lsu_op, bru_op;
  wire [2:0] idu_func;
  wire [4:0] idu_rs1, idu_rs2, idu_rd, exu_rd, lsu_rd, bru_rd, wbu_rd;
  wire [31:0] ifu_imm, idu_imm;
  wire fencei;

  wire [31:0] reg_src1, reg_src2;
  wire [31:0] reg_wdata;
  wire [31:0] csr_src;
  wire [31:0] forward_src1, forward_src2;
  wire [31:0] src1, src2;
  assign src1 = forward_src1;
  assign src2 = forward_src2;


  wire [11:0] idu_csr, exu_csr, bru_csr;
  wire [1:0] idu_csr_t, exu_csr_t, bru_csr_t;
  wire [31:0] csr_wdata;
  wire ifu_exception, idu_exception, exu_exception, lsu_exception, bru_exception, wbu_exception;
  wire [3:0] ifu_mcause, idu_mcause, exu_mcause, lsu_mcause, bru_mcause, wbu_mcause;
  wire [31:0] alu_a, alu_b;
  wire [`ALU_TYPE-1:0] alu_t;
  wire alu_sign, alu_sub;


  wire exu_mem_ren, exu_mem_wen;
  wire [3:0] exu_mem_wmask;
  wire [2:0] exu_mem_read_t;
  wire [31:0] exu_mem_addr;
  wire [31:0] mem_wdata;
  wire [31:0] mem_rdata;
  wire bru_jump;
  wire mret = bru_csr_t[1];
  wire jump = bru_jump | bru_exception | mret;
  assign csr_wdata = bru_result;
  wire lsu_wen, lsu_ren;
  
`ifdef CONFIG_SIM
  reg [31:0] sim_pc;
  wire sim_branch;
  wire wbu_op  /*verilator public_flat*/;
  wire is_diff_skip;
  wire [31:0] lsu_addr;
`ifndef CONFIG_YSYXSOC
  assign is_diff_skip = clint_rvalid || uart_bvalid || wbu_valid && (exu_mem_ren || exu_mem_wen) && exu_result >= 32'ha0000000;
`else
  assign is_diff_skip = clint_axi.rvalid || (lsu_wen||lsu_ren)&&(lsu_addr >= 32'h10000000 && lsu_addr < 32'h10001000 || lsu_addr >= 32'h02000000 && lsu_addr < 32'h03000000);
`endif


  always @(posedge clock) begin
    if (reset) sim_pc <= 0;
    else begin
      if (wbu_valid) sim_pc <= (bru_jump | sim_branch) ? bru_upc : wbu_exception ? upc : wbu_pc + 4;
    end
  end

  always @(posedge clock) begin
    if (wbu_valid) begin
      if (is_diff_skip) diff_skip();
      difftest();
    end
  end
  always @(posedge clock) begin
    if (ifu_vr_idu.valid) fetch_inst();
  end

  always @* if (ifu_inst == 32'h100073) quit();
  reg [31:0] npc_upc;
  always @(posedge clock) npc_upc <= exu_upc;

  wire reg_valid;
`endif
  logic fencei_fin;
  if_pipeline_vr ifu_vr_idu ();
  if_pipeline_vr idu_vr_exu ();
  if_pipeline_vr exu_vr_alloc ();
  if_pipeline_vr alloc_vr_lsu ();
  if_pipeline_vr alloc_vr_bru ();
  if_pipeline_vr lsu_vr_wbu ();
  if_pipeline_vr bru_vr_wbu ();
  if_axi_read ifu_axi ();
  if_lsu_adapter lsu_adapter();
  if_lsu_dcache lsu_dcache();
  if_dcache_axi dcache_bridge();
  if_axi dcache_axi ();
  if_lsu_adapter lsu_adapter_axi();
  if_axi lsu_axi ();
  if_axi xbar_axi ();
  if_axi mem_axi ();
  
`ifdef CONFIG_YSYXSOC
  assign io_master_awvalid = mem_axi.awvalid;
  assign io_master_awaddr  = mem_axi.awaddr;
  assign io_master_awid    = mem_axi.awid;
  assign io_master_awlen   = mem_axi.awlen;
  assign io_master_awsize  = mem_axi.awsize;
  assign io_master_awburst = mem_axi.awburst;
  assign mem_axi.awready   = io_master_awready;
  assign io_master_wvalid  = mem_axi.wvalid;
  assign io_master_wdata   = mem_axi.wdata;
  assign io_master_wstrb   = mem_axi.wstrb;
  assign io_master_wlast   = mem_axi.wlast;
  assign mem_axi.wready    = io_master_wready;
  assign io_master_bready  = mem_axi.bready;
  assign mem_axi.bvalid    = io_master_bvalid;
  assign mem_axi.bresp     = io_master_bresp;
  assign mem_axi.bid       = io_master_bid;
  assign io_master_arvalid = mem_axi.arvalid;
  assign io_master_araddr  = mem_axi.araddr;
  assign io_master_arid    = mem_axi.arid;
  assign io_master_arlen   = mem_axi.arlen;
  assign io_master_arsize  = mem_axi.arsize;
  assign io_master_arburst = mem_axi.arburst;
  assign mem_axi.arready   = io_master_arready;
  assign io_master_rready  = mem_axi.rready;
  assign mem_axi.rvalid    = io_master_rvalid;
  assign mem_axi.rresp     = io_master_rresp;
  assign mem_axi.rdata     = io_master_rdata;
  assign mem_axi.rlast     = io_master_rlast;
  assign mem_axi.rid       = io_master_rid;
`else
  if_axi_write uart_axi ();
`endif
  if_axi_read clint_axi ();

  ysyx_24110006_IFU mifu (
      .i_clock(clock),
      .i_reset(reset),
      .i_upc(upc),
      .i_busy(arbiter_ifu_read),
      .o_inst(ifu_inst),
      .i_fencei(fencei),
      .o_pc(ifu_pc),
      .o_exception(ifu_exception),
      .o_mcause(ifu_mcause),
      .i_pc(btb_pc),
      .o_predict(ifu_predict),
      .i_predict_err(predict_err),
      .i_btb_update(btb_update),
      .o_vr(ifu_vr_idu),
      .i_flush(flush),
      .i_fencei_fin(fencei_fin),
      .o_axi(ifu_axi.master)
  );

  ysyx_24110006_IMM mimm (
      .i_inst(ifu_inst),
      .o_imm (ifu_imm)
  );

  ysyx_24110006_IDU midu (
      .i_clock(clock),
      .i_reset(reset),
      .i_inst(ifu_inst),
      .i_imm(ifu_imm),
      .i_pc(ifu_pc),
      .o_op(idu_op),
      .o_func(idu_func),
      .o_reg_rs1(idu_rs1),
      .o_reg_rs2(idu_rs2),
      .o_reg_rd(idu_rd),
      .o_reg_wen(idu_reg_wen),
      .o_imm(idu_imm),
      .o_pc(idu_pc),
      .o_csr_t(idu_csr_t),
      .i_exception(ifu_exception),
      .o_exception(idu_exception),
      .i_mcause(ifu_mcause),
      .o_mcause(idu_mcause),
      .o_csr(idu_csr),
      .o_mret(idu_mret),
      .i_predict(ifu_predict),
      .o_predict(idu_predict),
      .i_vr(ifu_vr_idu),
      .o_vr(idu_vr_exu),
      .i_flush(flush),
      .i_stall(stall),
      .i_wen(exu_mem_wen),
      .i_ren(exu_mem_ren)
  );

  ysyx_24110006_RegisterFile mreg (
      .i_clock(clock),
      .i_reset(reset),
      .i_waddr(wbu_rd),
      .i_wdata(wbu_result),
      .i_raddr1(idu_rs1),
      .i_raddr2(idu_rs2),
      .i_wen(wbu_reg_wen),
      .o_rdata1(reg_src1),
      .o_rdata2(reg_src2),
      .i_valid(wbu_valid),
      .o_valid(reg_valid)
  );

  ysyx_24110006_CSR mcsr (
      .i_clock(clock),
      .i_reset(reset),
      .i_csr_t(bru_csr_t),
      .i_csr_r(idu_csr),
      .i_mret(idu_mret),
      .i_csr_w(bru_csr),
      .i_pc(wbu_pc),
      .i_exception(exception),
      .i_mcause(wbu_mcause),
      .i_wdata(wbu_result),
      .o_rdata(csr_src),
      .o_upc(csr_upc),
      .i_valid(wbu_valid)
  );

  ysyx_24110006_FORWARD_STALL mforward_stall (
      .i_valid(idu_vr_exu.valid),
      .i_op(idu_op),
      .i_rs1(idu_rs1),
      .i_rs2(idu_rs2),
      .i_reg_src1(reg_src1),
      .i_reg_src2(reg_src2),
      .i_lsu_data(wbu_result),
      .i_exu_data(exu_result),
      .i_exu_load(exu_mem_ren),
      .i_lsu_load(lsu_ren),
      .i_exu_valid(exu_vr_alloc.valid),
      .i_lsu_valid(wbu_valid),
      .i_lsu_ready(exu_vr_alloc.ready),
      .i_exu_rd(exu_rd),
      .i_lsu_rd(wbu_rd),
      .i_exu_wen(exu_reg_wen),
      .i_lsu_wen(wbu_reg_wen),
      .o_src1(forward_src1),
      .o_src2(forward_src2),
      .o_stall(stall)
  );

  ysyx_24110006_ALUOP maluop (
      .i_src1(src1),
      .i_src2(src2),
      .i_imm(idu_imm),
      .i_csr_rdata(csr_src),
      .i_pc(idu_pc),
      .i_op(idu_op),
      .i_func(idu_func),
      .o_alu_a(alu_a),
      .o_alu_b(alu_b),
      .o_alu_sub(alu_sub),
      .o_alu_sign(alu_sign),
      .o_alu_t(alu_t)
  );

  ysyx_24110006_EXU mexu (
      .i_clock(clock),
      .i_reset(reset),
      .i_alu_a(alu_a),
      .i_alu_b(alu_b),
      .i_alu_sub(alu_sub),
      .i_alu_sign(alu_sign),
      .i_alu_t(alu_t),
      .i_op(idu_op),
      .i_func(idu_func),
      .i_reg_src1(src1),
      .i_reg_src2(src2),
      .i_reg_rd(idu_rd),
      .i_csr_t(idu_csr_t),
      .i_imm(idu_imm),
      .i_pc(idu_pc),
      .o_result(exu_result),
      .o_upc(exu_upc),
      .o_pc(exu_pc),
      .o_reg_wen(exu_reg_wen),
      .o_result_t(exu_result_t),
      .o_csr_t(exu_csr_t),
      .o_jump(exu_jump),
      .o_reg_rd(exu_rd),
      .o_mem_ren(exu_mem_ren),
      .o_mem_wen(exu_mem_wen),
      .o_mem_wmask(exu_mem_wmask),
      .o_mem_read_t(exu_mem_read_t),
      .o_mem_addr(exu_mem_addr),
      .o_mem_wdata(mem_wdata),
      .o_fencei(fencei),
      .o_op(exu_op),
      .o_branch_mid(branch_mid),
      .i_exception(idu_exception),
      .o_exception(exu_exception),
      .i_mcause(idu_mcause),
      .o_mcause(exu_mcause),
      .i_csr(idu_csr),
      .o_csr(exu_csr),
      .i_csr_upc(csr_upc),
      .i_predict(idu_predict),
      .o_predict(exu_predict),
      .o_btb_update(exu_btb_update),
      .i_vr(idu_vr_exu),
      .o_vr(exu_vr_alloc),
      .i_flush(flush),
      .i_stall(stall),
      .o_flush(exu_flush)
  );

  ysyx_24110006_EXU_ALLOC_VALID exu_alloc_valid (
      .i_vr(exu_vr_alloc),
      .i_wen(exu_mem_wen),
      .i_ren(exu_mem_ren),
      .o_vr_bru(alloc_vr_bru),
      .o_vr_lsu(alloc_vr_lsu)
  );
  ysyx_24110006_BRU mbru (
      .i_clock  (clock),
      .i_reset  (reset),
      .i_reg_wen(exu_reg_wen),
      .i_result (exu_result),
      .i_reg_rd (exu_rd),
      .i_csr_t  (exu_csr_t),

      .o_result(bru_result),
      .o_reg_wen(bru_reg_wen),
      .o_reg_rd(bru_rd),
      .o_csr_t(bru_csr_t),
      .i_exception(exu_exception),
      .o_exception(bru_exception),
      .i_mcause(exu_mcause),
      .o_mcause(bru_mcause),
      .i_jump(exu_jump),
      .o_jump(bru_jump),
      .i_pc(exu_pc),
      .o_pc(bru_pc),
      .i_csr(exu_csr),
      .o_csr(bru_csr),
      .i_upc(exu_upc),
      .o_upc(bru_upc),
      .i_branch_mid(branch_mid),
      .o_branch(bru_branch),
      .i_predict(exu_predict),
      .o_predict(bru_predict),
      .o_predict_err(bru_predict_err),
      .o_btb_update(bru_btb_update),
`ifdef CONFIG_SIM
      .i_op(exu_op),
      .o_op(bru_op),
      .o_sim_branch(sim_branch),
`endif
      .i_vr(alloc_vr_bru),
      .o_vr(bru_vr_wbu),
      .i_flush(exception | branch | csr_flush)
  );
  ysyx_24110006_LSU mlsu (
      .i_clock(clock),
      .i_reset(reset),
      .i_ren(exu_mem_ren),
      .i_wen(exu_mem_wen),
      .i_wdata(mem_wdata),
      .i_wmask(exu_mem_wmask),
      .i_read_t(exu_mem_read_t),
      .i_reg_wen(exu_reg_wen),
      .i_addr(exu_result),
      .i_reg_rd(exu_rd),

      .o_result(lsu_result),
      .o_reg_wen(lsu_reg_wen),
      .o_reg_rd(lsu_rd),
      .i_exception(exu_exception),
      .o_exception(lsu_exception),
      .i_mcause(exu_mcause),
      .o_mcause(lsu_mcause),
      .o_ren(lsu_ren),
      .i_pc(exu_pc),
      .o_pc(lsu_pc),
`ifdef CONFIG_SIM
      .i_op(exu_op),
      .o_op(lsu_op),
      .o_wen(lsu_wen),
      .o_addr(lsu_addr),
`endif
      .i_vr(alloc_vr_lsu),
      .o_vr(lsu_vr_wbu),
      .i_flush(exception | branch | csr_flush),
      .o_lsu_rq(lsu_adapter.master)
  );
  ysyx_24110006_LSU_ADAPTER mlsu_adapter (
      .i_lsu_adapter(lsu_adapter.slave),
`ifdef CONFIG_DCACHE
      .o_lsu_dcache(lsu_dcache.master)
`else
      .o_lsu_adapter(lsu_adapter_axi.master)
`endif
  );
`ifdef CONFIG_DCACHE
  ysyx_24110006_DCACHE mdcache (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(fencei && !predict_err),
      .o_fin(fencei_fin),
      .i_lsu_rq(lsu_dcache.slave),
      .o_axi_rq(dcache_bridge.master)
  );
  ysyx_24110006_CACHE2AXI mcache2axi(
      .i_clock(clock),
      .i_reset(reset),
      .i_dcache_rq(dcache_bridge.slave),
      .o_axi_rq(dcache_axi.master)
  );
`else
  ysyx_24110006_LSU2AXI mlsu2axi (
      .i_clock(clock),
      .i_reset(reset),
      .i_dcache_rq(lsu_adapter_axi.slave),
      .o_axi_rq(lsu_axi.master)
  );
`endif
  ysyx_24110006_WBU mwbu (
      .i_bru_result(bru_result),
      .i_lsu_result(lsu_result),
      .o_result(wbu_result),

      .i_bru_pc(bru_pc),
      .i_lsu_pc(lsu_pc),
      .o_pc(wbu_pc),

      .i_bru_reg_wen(bru_reg_wen),
      .i_lsu_reg_wen(lsu_reg_wen),
      .o_reg_wen(wbu_reg_wen),

      .i_bru_rd(bru_rd),
      .i_lsu_rd(lsu_rd),
      .o_rd(wbu_rd),

      .i_bru_mcause(bru_mcause),
      .i_lsu_mcause(lsu_mcause),
      .o_mcause(wbu_mcause),

      .i_bru_exception(bru_exception),
      .i_lsu_exception(lsu_exception),
      .o_exception(wbu_exception),
`ifdef CONFIG_SIM
      .i_bru_op(bru_op),
      .i_lsu_op(lsu_op),
      .o_op(wbu_op),
`endif
      .i_vr_bru(bru_vr_wbu),
      .i_vr_lsu(lsu_vr_wbu),
      .o_valid(wbu_valid)
  );

  ysyx_24110006_ARBITER marbiter (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .o_busy(arbiter_ifu_read),
      .ifu(ifu_axi.slave),
`ifdef CONFIG_DCACHE
      .lsu(dcache_axi.slave),
`else
      .lsu(lsu_axi.slave),
`endif
      .out(xbar_axi.master)
  );

  ysyx_24110006_XBAR mxbar (
      .i_clock(clock),
      .i_reset(reset),
      .in(xbar_axi.slave),
      .mem(mem_axi.master),
`ifndef CONFIG_YSYXSOC
      .uart(uart_axi),
`endif
      .clint(clint_axi.master)
  );

`ifndef CONFIG_YSYXSOC
  ysyx_24110006_SRAM msram (
      .i_clock(clock),
      .i_reset(reset),
      .in(mem_axi.slave)
  );

  ysyx_24110006_UART muart (
      .i_clock(clock),
      .i_reset(reset),
      .in(uart_axi.slave)
  );
`endif

  ysyx_24110006_CLINT mclint (
      .i_clock(clock),
      .i_reset(reset),
      .in(clint_axi.slave)
  );

endmodule
