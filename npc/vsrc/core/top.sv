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
    input               clock,
`ifdef CONFIG_YSYXSOC
          if_axi.master master,
`endif
    input               reset
);

  wire fencei, fencei_fin;
  rob::rob_t rob_sim;
  wire flush = rob_sim.result.flush && rob_sim.valid;
  wire [31:0] upc = rob_sim.result.upc;
  wire [31:0] pc = rob_sim.inst_info.pc;
`ifdef CONFIG_SIM
  logic [31:0][5:0] rat;
  reg [31:0] sim_pc;
  always_ff @(posedge clock) begin
    if (retire_valid) begin
      sim_pc <= flush ? upc : pc + 4;
    end
  end
  always @(posedge clock) begin
    if (retire_valid) begin
      if (rob_sim.result.sim.difftest_skip) diff_skip();
      if (rob_sim.inst_info.quit) quit();
      else difftest();
    end
  end
  reg [63:0] mtime;
  always_ff @(posedge clock) begin
    if (reset) mtime <= 0;
    else mtime <= mtime + 1;
  end
  wire reg_valid;
`endif
  pipe::reg_rinfo_t reg_rinfo_int, reg_rinfo_lsu;
  if_axi_read icache_axi ();
  if_lsu_adapter rq_axi ();
  if_lsu_dcache rq_dcache ();
  if_dcache_rq dcache_bridge ();
  if_axi dcache_axi ();
  if_lsu_adapter lsu_adapter_axi ();
  if_axi lsu_axi ();
  if_axi xbar_axi ();
  if_axi mem_axi ();
  if_icache_rq ifu_icache ();
  pipe::ifu2idu_t from_ifu, to_idu;
  if_icache_rq ifu_rq ();
  pipe::csr_rinfo_t csr_rinfo;
  pipe::csr_rdata_t csr_rdata;
  alu::op_t alu_op;
  pipe::csr_winfo_t csr_winfo;
  pipe::csr_einfo_t bru_csr_einfo, lsu_csr_einfo, csr_einfo;
  if_mem_rq icache_mem_rq ();
  if_pipeline_vr ifu_vr_ibuffer (), ibuffer_vr_idu ();
  if_pipeline_vr ifu_vr_idu ();
  pipe::reg_winfo_t reg_winfo;
  ooo::idu2rename_t idu2rename;
  if_pipeline_vr idu_vr_rename ();
  if_pipeline_vr rename_vr_dispatch ();
  if_pipeline_vr dispatch_vr_int ();
  if_pipeline_vr dispatch_vr_rob ();
  if_pipeline_vr dispatch_vr_lsu ();
  if_pipeline_vr iq_vr_int ();
  if_pipeline_vr iq_vr_lsu ();
  if_pipeline_vr agu_vr_lsu ();
  ooo::dispatch_info_t dispatch_info;
  ooo::dispatch_inst_t dispatch_int, dispatch_lsu;
  rob::inst_info_t dispatch_rob;
  ooo::issue_int_t issue_int;
  ooo::issue_lsu_t issue_lsu;
  rob::commit_info_t commit_int, commit_load;
  ooo::retire_info_t retire_info;
  rob::wb_index rob_index;
  logic retire_valid;
  pipe::reg_rdata_t reg_rdata_int, reg_rdata_lsu;
  ooo::exu_info_t exu_info;
  ooo::lsu_info_t lsu_info;
  if_rq_load rq_lunit();
  if_rq_store rq_sunit();
  lsu::rq_store_t rq_agu_store, rq_sbuf;
  lsu::rq_load_t rq_agu_load;
  if_pipeline_vr agu_vr_load();
  if_pipeline_vr agu_vr_store();
  if_pipeline_vr sbuf_vr_sunit();
  if_load_check load_check();
  rob::store_commit_t store_commit;
  logic store_retire;

`ifndef CONFIG_YSYXSOC
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
      .i_pc(pc),
      .o_vr(ifu_vr_ibuffer),
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

  ysyx_24110006_IBUFFER mibuffer (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .i_fencei(fencei),
      .from_ifu(from_ifu),
      .to_idu(to_idu),
      .i_vr(ifu_vr_ibuffer),
      .o_vr(ibuffer_vr_idu)
  );
  ysyx_24110006_IDU midu (
      .i_clock(clock),
      .i_reset(reset),
      .from_ifu(to_idu),
      .to_rename(idu2rename),
      .i_vr(ibuffer_vr_idu),
      .o_vr(idu_vr_rename),
      .i_flush(flush | fencei)
  );
  ysyx_24110006_RENAME mrename (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .retire_info(retire_info),
      .from_idu(idu2rename),
      .dispatch_info(dispatch_info),
`ifdef CONFIG_SIM
      .o_rat(rat),
`endif
      .i_vr(idu_vr_rename),
      .o_vr(rename_vr_dispatch)
  );
  ysyx_24110006_DISPATCH mdispatch (
      .vr_in(rename_vr_dispatch),
      .vr_lsu(dispatch_vr_lsu),
      .vr_int(dispatch_vr_int),
      .vr_rob(dispatch_vr_rob),
      .dispatch_info(dispatch_info),
      .dispatch_int(dispatch_int),
      .dispatch_lsu(dispatch_lsu),
      .rob_info(dispatch_rob)
  );
  ysyx_24110006_ROB mrob (
      .i_clock(clock),
      .i_reset(reset),
      .vr_in(dispatch_vr_rob),
      .dispatch_inst(dispatch_rob),
      .commit_int(commit_int),
      .commit_lsu(commit_load),
      .commit_store(store_commit),
      .retire_valid(retire_valid),
      .retire_info(retire_info),
      .rob_index(rob_index),
      .rob_out(rob_sim),
      .reg_winfo(reg_winfo),
      .store_retire(store_retire)
  );
  ysyx_24110006_INT_IQ mint_iq (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .rob_index(rob_index),
      .dispatch_inst(dispatch_int),
      .reg_winfo(reg_winfo),
      .issue_inst(issue_int),
      .reg_rinfo(reg_rinfo_int),
      .i_vr(dispatch_vr_int),
      .o_vr(iq_vr_int)
  );
  ysyx_24110006_LSU_IQ mlsu_iq (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .rob_index(rob_index),
      .dispatch_inst(dispatch_lsu),
      .reg_winfo(reg_winfo),
      .issue_inst(issue_lsu),
      .reg_rinfo(reg_rinfo_lsu),
      .store_commit(store_commit),
      .i_vr(dispatch_vr_lsu),
      .o_vr(iq_vr_lsu)
  );
  ysyx_24110006_RegisterFile mreg (
      .i_clock(clock),
      .i_reset(reset),
      .rinfo1 (reg_rinfo_int),
      .rdata1 (reg_rdata_int),
      .rinfo2 (reg_rinfo_lsu),
      .rdata2 (reg_rdata_lsu),
      .winfo  (reg_winfo),
`ifdef CONFIG_SIM
      .i_rat  (rat),
`endif
      .o_valid(reg_valid)
  );
  ysyx_24110006_CSR mcsr (
      .i_clock(clock),
      .i_reset(reset),
      .rinfo  (csr_rinfo),
      .rdata  (csr_rdata),
      .winfo  (csr_winfo),
      .einfo  (csr_einfo),
      .i_valid(retire_valid)
  );
  ysyx_24110006_ALUOP maluop (
      .csr_rdata (csr_rdata),
      .reg_rdata (reg_rdata_int),
      .issue_info(issue_int),
      .exu_info  (exu_info)
  );

  ysyx_24110006_EXU mexu (
      .i_clock(clock),
      .i_reset(reset),
      .issue_inst(exu_info),
      .commit(commit_int),
      .i_vr(iq_vr_int),
      .i_flush(flush | fencei)
  );
  ysyx_24110006_AGU magu (
      .i_clock(clock),
      .vr_in(iq_vr_lsu),
      .vr_load(agu_vr_load),
      .vr_store(agu_vr_store),
      .reg_rdata(reg_rdata_lsu),
      .issue_info(issue_lsu),
      .rq_load(rq_agu_load),
      .rq_store(rq_agu_store)
  );
  ysyx_24110006_STORE_BUFFER mstore_buffer (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .i_vr(agu_vr_store),
      .o_vr(sbuf_vr_sunit),
      .i_rq(rq_agu_store),
      .store_retire(store_retire),
      .check(load_check),
      .o_rq(rq_sbuf)
  );
  ysyx_24110006_STORE_UNIT mstore_unit (
      .i_clock(clock),
      .i_reset(reset),
      .i_vr(sbuf_vr_sunit),
      .i_rq(rq_sbuf),
      .o_rq(rq_sunit)
  );
  ysyx_24110006_LOAD_UNIT mload_unit (
      .i_clock(clock),
      .i_reset(reset),
      .i_vr(agu_vr_load),
      .i_rq(rq_agu_load),
      .o_rq(rq_lunit),
      .check(load_check),
      .commit(commit_load)
  );
  ysyx_24110006_LSU_ARIBITER mlsu_aribiter (
      .i_clock(clock),
      .i_reset(reset),
      .rq_load(rq_lunit),
      .rq_store(rq_sunit),
      .rq_dcache(rq_dcache),
      .rq_axi(rq_axi)
  );
  ysyx_24110006_DCACHE mdcache (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(fencei),
      .o_fin(fencei_fin),
      .i_lsu_rq(rq_dcache),
      .o_axi_rq(dcache_bridge)
  );
  ysyx_24110006_DCACHE2AXI mdcache2axi (
      .i_clock(clock),
      .i_reset(reset),
      .i_dcache_rq(dcache_bridge),
      .o_axi_rq(dcache_axi)
  );
  ysyx_24110006_LSU2AXI mlsu2axi (
      .i_clock(clock),
      .i_reset(reset),
      .i_lsu_adapter(rq_axi),
      .o_axi(lsu_axi)
  );

  ysyx_24110006_ARBITER marbiter (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .ifu(icache_axi.slave),
      .dcache(dcache_axi.slave),
      .lsu(lsu_axi.slave),
      .out(xbar_axi.master)
  );

  ysyx_24110006_XBAR mxbar (
      .i_clock(clock),
      .i_reset(reset),
      .in(xbar_axi.slave),
`ifdef CONFIG_YSYXSOC
      .mem(master)
`else
      .mem(mem_axi),
      .uart(uart_axi),
`endif
      .clint(clint_axi.master)
  );

`ifndef CONFIG_YSYXSOC
  ysyx_24110006_SRAM msram (
      .i_clock(clock),
      .i_reset(reset),
      .i_axi  (mem_axi.slave)
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
