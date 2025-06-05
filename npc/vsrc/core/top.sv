`ifndef CONFIG_YOSYS
import "DPI-C" function void quit();
import "DPI-C" function void difftest();
import "DPI-C" function void diff_skip();
import "DPI-C" function void fetch_inst();
import "DPI-C" context function void update_pc(input int pc);
import "DPI-C" context function void update_reg(
  input int rd,
  input int wdata
);
import "DPI-C" context function void update_inst(input int inst);
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

  wire [31:0] upc, bru_upc;
  wire wbu_valid;
  wire exception, branch, exu_flush, csr_flush, flush, stall, bru_branch;
  assign exception = csr_einfo.exception;
  assign flush = exu_flush | exception | branch | csr_flush;
  assign upc = exception ? csr_rdata.upc : (branch | csr_flush) ? bru_upc : exu_flush ? exu2bru.upc : 0;

  wire fencei, fencei_fin;

  wire bru_jump;
  wire lsu_wen, lsu_ren;

`ifdef CONFIG_SIM
  wire sim_branch;
  wire is_diff_skip;
  wire [31:0] lsu_addr;
  wire [31:0] wbu_pc;
  pipe::sim_t ifu_sim, idu_sim, exu_sim, bru_sim, lsu_sim, wbu_sim;
`ifndef CONFIG_YSYXSOC
  assign is_diff_skip = clint_axi.rvalid || uart_axi.bvalid || lsu_vr_wbu.valid && (lsu_addr < 32'h80000000 || lsu_addr >= 32'h90000000);
`else
  assign is_diff_skip = clint_axi.rvalid || lsu_vr_wbu.valid &&(lsu_addr >= 32'h10000000 && lsu_addr < 32'h10001000 || lsu_addr >= 32'h02000000 && lsu_addr < 32'h03000000);
`endif
  logic [31:0] sim_pc /*verilator public*/;
  logic [31:0] sim_inst /*verilator public*/;
  always_ff @(posedge clock)begin
    if(wbu_valid) begin
      sim_pc <= (bru_jump | sim_branch) ? bru_upc : mquit ? wbu_pc : exception ? upc : wbu_pc + 4;
      sim_inst <= wbu_sim.inst;
    end
  end
  wire mquit;
  always @(posedge clock) begin
    if (wbu_valid) begin
      if (is_diff_skip) diff_skip();
      if (mquit) quit();
      else difftest();
    end
  end
  reg [63:0] mtime;
  always_ff @(posedge clock) begin
    if (reset) mtime <= 0;
    else mtime <= mtime + 1;
  end
  /*  */
  /* always_comb if (mquit) quit(); */
  reg [31:0] npc_upc;
  always @(posedge clock) npc_upc <= exu2bru.upc;
  always_ff @(posedge clock) begin
    if (wbu_valid) begin
      fetch_inst();
    end
  end
  wire reg_valid;
`endif
  if_pipeline_vr idu_vr_exu ();
  if_pipeline_vr exu_vr_alloc ();
  if_pipeline_vr alloc_vr_lsu ();
  if_pipeline_vr alloc_vr_bru ();
  if_pipeline_vr lsu_vr_wbu ();
  if_pipeline_vr bru_vr_wbu ();
  if_axi_read icache_axi ();
  if_lsu_adapter lsu_adapter ();
  if_lsu_dcache lsu_dcache ();
  if_dcache_rq dcache_bridge ();
  if_axi dcache_axi ();
  if_lsu_adapter lsu_adapter_axi ();
  if_axi lsu_axi ();
  if_axi xbar_axi ();
  if_axi mem_axi ();
  if_icache_rq ifu_icache ();
  pipe::ifu2idu_t from_ifu, to_idu;
  if_icache_rq ifu_rq ();
  pipe::idu2aluop_t idu2aluop;
  pipe::idu2exu_t idu2exu;
  pipe::reg_rinfo_t reg_rinfo;
  pipe::csr_rinfo_t csr_rinfo;
  pipe::reg_rdata_t reg_rdata;
  pipe::reg_rdata_t from_forward;
  pipe::csr_rdata_t csr_rdata;
  pipe::reg_winfo_t reg_winfo;
  pipe::exu2bru_t exu2bru;
  pipe::exu2lsu_t exu2lsu;
  alu::op_t alu_op;
  pipe::wbu_t bru2wbu, lsu2wbu;
  pipe::csr_winfo_t csr_winfo;
  pipe::csr_einfo_t bru_csr_einfo, lsu_csr_einfo, csr_einfo;
  if_mem_rq icache_mem_rq ();
`ifdef CONFIG_IBUFFER
  if_pipeline_vr ifu_vr_ibuffer(), ibuffer_vr_idu();
`else
  if_pipeline_vr ifu_vr_idu();
`endif
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
      .to_idu(from_ifu),
      .o_icache_rq(ifu_icache),
      .i_upc(upc),
      .i_fencei(fencei),
      .i_dcache_fencei_fin(fencei_fin),
      .i_pc(wbu_pc),
`ifdef CONFIG_IBUFFER
      .o_vr(ifu_vr_ibuffer),
`else
      .o_vr(ifu_vr_idu),
`endif
`ifdef CONFIG_SIM
      .o_sim(ifu_sim),
`endif
      .i_flush(flush)
  );

  ysyx_24110006_ICACHE micache (
      .i_clock(clock),
      .i_reset(reset),
      .i_rq(ifu_icache),
      .o_rq(icache_mem_rq)
  );
  ysyx_24110006_ICACHE2AXI micache2axi (
      .i_clock(clock),
      .i_reset(reset),
      .i_icache_rq(icache_mem_rq),
      .o_axi_rq(icache_axi)
  );

`ifdef CONFIG_IBUFFER
  ysyx_24110006_IBUFFER mibuffer(
    .i_clock(clock),
    .i_reset(reset),
    .i_flush(flush),
    .i_fencei(fencei),
    .from_ifu(from_ifu),
    .to_idu(to_idu),
    .i_vr(ifu_vr_ibuffer),
    .o_vr(ibuffer_vr_idu)
  );
`else
  assign to_idu = from_ifu;
`endif
  ysyx_24110006_IDU midu (
      .i_clock(clock),
      .i_reset(reset),
      .from_ifu(to_idu),
      .to_exu(idu2exu),
      .to_reg(reg_rinfo),
      .to_csr(csr_rinfo),
      .to_aluop(idu2aluop),
`ifdef CONFIG_IBUFFER
      .i_vr(ibuffer_vr_idu),
`else
      .i_vr(ifu_vr_idu),
`endif
      .o_vr(idu_vr_exu),
`ifdef CONFIG_SIM
      .i_sim(ifu_sim),
      .o_sim(idu_sim),
`endif
      .i_flush(flush | fencei),
      .i_stall(stall),
      .i_wen(exu2lsu.wen),
      .i_ren(exu2lsu.ren)
  );

  ysyx_24110006_RegisterFile mreg (
      .i_clock(clock),
      .i_reset(reset),
      .rinfo  (reg_rinfo),
      .rdata  (reg_rdata),
      .winfo  (reg_winfo),
      .i_valid(wbu_valid),
      .o_valid(reg_valid)
  );

  ysyx_24110006_CSR mcsr (
      .i_clock(clock),
      .i_reset(reset),
      .rinfo  (csr_rinfo),
      .rdata  (csr_rdata),
      .winfo  (csr_winfo),
      .einfo  (csr_einfo),
      .i_valid(wbu_valid)
  );

  ysyx_24110006_FORWARD_STALL mforward_stall (
      .i_valid(idu_vr_exu.valid),
      .i_op(idu2exu.op),
      .i_rs1(reg_rinfo.rs1),
      .i_rs2(reg_rinfo.rs2),
      .i_reg_src1(reg_rdata.r1),
      .i_reg_src2(reg_rdata.r2),
      .i_lsu_data(lsu2wbu.result),
      .i_exu_data(exu2bru.result),
      .i_bru_data(bru2wbu.result),
      /* .i_exu_load(exu_mem_ren), */
      /* .i_lsu_load(lsu_ren), */
      .i_exu2bru_valid(alloc_vr_bru.valid),
      .i_exu2lsu_valid(alloc_vr_lsu.valid),
      .i_lsu_valid(lsu_vr_wbu.valid),
      .i_bru_valid(bru_vr_wbu.valid),
      .i_lsu_ready(alloc_vr_lsu.ready),
      .i_exu2bru_rd(exu2bru.reg_rd),
      .i_exu2lsu_rd(exu2lsu.reg_rd),
      .i_lsu_rd(lsu2wbu.reg_rd),
      .i_bru_rd(bru2wbu.reg_rd),
      .i_exu2lsu_wen(exu2lsu.reg_wen),
      .i_exu2bru_wen(exu2bru.reg_wen),
      .i_lsu_wen(lsu2wbu.reg_wen),
      .i_bru_wen(bru2wbu.reg_wen),
      .o_src1(from_forward.r1),
      .o_src2(from_forward.r2),
      .o_stall(stall)
  );

  ysyx_24110006_ALUOP maluop (
      .from_forward(from_forward),
      .from_csr(csr_rdata),
      .from_idu(idu2aluop),
      .op(alu_op)
  );

  ysyx_24110006_EXU mexu (
      .i_clock(clock),
      .i_reset(reset),
      .from_idu(idu2exu),
      .from_reg(from_forward),
      .from_csr(csr_rdata),
      .from_aluop(alu_op),
      .to_bru(exu2bru),
      .to_lsu(exu2lsu),
`ifdef CONFIG_SIM
      .i_sim(idu_sim),
      .o_sim(exu_sim),
`endif
      .i_vr(idu_vr_exu),
      .o_vr(exu_vr_alloc),
      .i_flush(flush | fencei),
      .i_stall(stall),
      .o_flush(exu_flush)
  );

  ysyx_24110006_EXU_ALLOC_VALID exu_alloc_valid (
      .i_vr(exu_vr_alloc),
      .i_wen(exu2lsu.wen),
      .i_ren(exu2lsu.ren),
      .o_vr_bru(alloc_vr_bru),
      .o_vr_lsu(alloc_vr_lsu)
  );
  ysyx_24110006_BRU mbru (
      .i_clock(clock),
      .i_reset(reset),
      .from_exu(exu2bru),
      .to_wbu(bru2wbu),
      .to_csr(csr_winfo),
      .csr_einfo(bru_csr_einfo),
      .o_upc(bru_upc),
      .o_jump(bru_jump),
      .o_fencei(fencei),
      .o_branch(branch),
      .o_quit(mquit),
      .o_csr_flush(csr_flush),
`ifdef CONFIG_SIM
      .i_sim(exu_sim),
      .o_sim(bru_sim),
      .o_sim_branch(sim_branch),
`endif
      .i_vr(alloc_vr_bru),
      .o_vr(bru_vr_wbu),
      .i_flush(exception | branch | csr_flush | fencei)
  );
  ysyx_24110006_LSU mlsu (
      .i_clock(clock),
      .i_reset(reset),
      .from_exu(exu2lsu),
      .to_wbu(lsu2wbu),
      .csr_einfo(lsu_csr_einfo),
      .o_ren(lsu_ren),
`ifdef CONFIG_SIM
      .i_sim(exu_sim),
      .o_sim(lsu_sim),
      .o_wen(lsu_wen),
      .o_addr(lsu_addr),
`endif
      .i_vr(alloc_vr_lsu),
      .o_vr(lsu_vr_wbu),
      .i_flush(exception | branch | csr_flush | fencei),
      .o_lsu_rq(lsu_adapter.master)
  );
  ysyx_24110006_LSU_ADAPTER mlsu_adapter (
      .i_lsu_adapter(lsu_adapter.slave),
`ifdef CONFIG_DCACHE
      .o_lsu_dcache (lsu_dcache.master),
`endif
      .o_lsu_adapter(lsu_adapter_axi.master)
  );
`ifdef CONFIG_DCACHE
  ysyx_24110006_DCACHE mdcache (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(fencei),
      .o_fin(fencei_fin),
      .i_lsu_rq(lsu_dcache.slave),
      .o_axi_rq(dcache_bridge.master)
  );
  ysyx_24110006_DCACHE2AXI mdcache2axi (
      .i_clock(clock),
      .i_reset(reset),
      .i_dcache_rq(dcache_bridge.slave),
      .o_axi_rq(dcache_axi.master)
  );
`endif
  ysyx_24110006_LSU2AXI mlsu2axi (
      .i_clock(clock),
      .i_reset(reset),
      .i_lsu_adapter(lsu_adapter_axi.slave),
      .o_axi(lsu_axi.master)
  );

  ysyx_24110006_WBU mwbu (
      .from_bru(bru2wbu),
      .from_lsu(lsu2wbu),
      .bru_einfo(bru_csr_einfo),
      .lsu_einfo(lsu_csr_einfo),
      .to_csr(csr_einfo),
      .reg_winfo(reg_winfo),
`ifdef CONFIG_SIM
      .i_bru_sim(bru_sim),
      .i_lsu_sim(lsu_sim),
      .o_sim(wbu_sim),
`endif
      .i_vr_bru(bru_vr_wbu),
      .i_vr_lsu(lsu_vr_wbu),
      .o_pc(wbu_pc),
      .o_valid(wbu_valid)
  );

  ysyx_24110006_ARBITER marbiter (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .ifu(icache_axi.slave),
`ifdef CONFIG_DCACHE
      .dcache(dcache_axi.slave),
`endif
      .lsu(lsu_axi.slave),
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
      .i_axi(mem_axi.slave)
  );

  ysyx_24110006_UART muart (
      .i_clock(clock),
      .i_reset(reset),
      .i_axi_w(uart_axi.slave)
  );
`endif

  ysyx_24110006_CLINT mclint (
      .i_clock(clock),
      .i_reset(reset),
      .in(clint_axi.slave)
  );

endmodule
