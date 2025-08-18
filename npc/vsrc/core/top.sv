`ifndef CONFIG_YOSYS
import "DPI-C" function void quit();
import "DPI-C" function void difftest();
import "DPI-C" function void difftest2();
import "DPI-C" function void diff_skip();
import "DPI-C" function void diff_skip2();
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
  logic flush;
  rob::rob_t rob_sim;
  wire [31:0] upc = rob_sim.result.upc;
  wire [31:0] pc = rob_sim.inst_info.pc;
`ifdef CONFIG_SIM
  logic [31:0][5:0] rat;
  logic [1:0] difftest_skip;
  logic sim_quit;
  logic [1:0][31:0] retire_pc;
  logic [1:0][31:0] sim_pc;
  logic [2:0][31:0] sim_pc_r;
  logic [31:0] sim_pc_w;
  always_ff @(posedge clock) begin
    if (retire_valid != 0)
      if (flush) sim_pc_w <= bp_result.pred_taken ? bp_result.pc + 4 : bp_result.upc;
      else sim_pc_w <= bp_result.pred_taken ? bp_result.upc : bp_result.pc + 4;
  end
  always_comb begin
    if (flush) sim_pc[0] = bp_result.pred_taken ? retire_pc[0] + 4 : bp_result.upc;
    else sim_pc[0] = bp_result.pred_taken ? bp_result.upc : retire_pc[0] + 4;
  end
  always_comb begin
    if (flush) sim_pc[1] = bp_result.pred_taken ? retire_pc[1] + 4 : bp_result.upc;
    else sim_pc[1] = bp_result.pred_taken ? bp_result.upc : retire_pc[1] + 4;
  end
  always_ff @(posedge clock) begin
    if (retire_valid != 0) begin
      sim_pc_r[0] <= sim_pc[0];
      sim_pc_r[1] <= sim_pc[1];
      sim_pc_r[2] <= retire_pc[0];
    end
  end
  always @(posedge clock) begin
    if (retire_valid[0]) begin
      if (difftest_skip[0]) diff_skip();
      if (difftest_skip[1] && retire_valid[1]) diff_skip2();
      if (sim_quit) quit();
      if (retire_valid[1]) difftest2();
      else difftest();
    end
  end
  reg [63:0] mtime;
  always_ff @(posedge clock) begin
    if (reset) mtime <= 0;
    else mtime <= mtime + 1;
  end
`endif
  rf::rinfo_t reg_rinfo_int[0], reg_rinfo_load, reg_rinfo_store;
  rf::rdata_t reg_rdata_int[0], reg_rdata_load, reg_rdata_store;
  rf::winfo_t reg_winfo_int[0], reg_winfo_lsu;
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
  pipe::ifu2idu_t from_ifu;
  pipe::ifu2idu_t to_idu;
  if_icache_rq ifu_rq ();
  pipe::csr_rinfo_t csr_rinfo;
  pipe::csr_rdata_t csr_rdata;
  alu::op_t alu_op;
  pipe::csr_winfo_t csr_winfo;
  pipe::csr_einfo_t bru_csr_einfo, lsu_csr_einfo, csr_einfo;
  if_mem_rq icache_mem_rq ();
  if_pipeline_vr ifu_vr_ibuffer (), ibuffer_vr_idu ();
  if_pipeline_vr ifu_vr_idu ();
  ooo::idu2rename_t idu2rename;
  if_pipeline_vr idu_vr_rename ();
  if_pipeline_vr rename_vr_dispatch ();
  if_pipeline_vr dispatch_vr_int [2] ();
  if_pipeline_vr dispatch_vr_rob ();
  if_pipeline_vr dispatch_vr_load ();
  if_pipeline_vr dispatch_vr_store ();
  if_pipeline_vr iq_vr_int [2] ();
  if_pipeline_vr iq_vr_load ();
  if_pipeline_vr iq_vr_store ();
  if_pipeline_vr agu_vr_load ();
  if_pipeline_vr agu_vr_store ();
  ooo::dispatch_info_t dispatch_info;
  ooo::dispatch_inst_t dispatch_int[2], dispatch_load, dispatch_store;
  rob::info_t dispatch_rob;
  ooo::issue_int_t issue_int[2];
  ooo::issue_lsu_t issue_load, issue_store;
  rob::commit_info_t commit_int[2], commit_load;
  rob::wb_index rob_index [2];
  logic [1:0] retire_valid;
  ooo::exu_info_t exu_info [2];
  ooo::lsu_info_t lsu_info;
  if_rq_load rq_lunit ();
  if_rq_store rq_sunit ();
  lsu::rq_store_t rq_agu_store, rq_sbuf;
  lsu::rq_load_t rq_agu_load;
  if_pipeline_vr sbuf_vr_sunit ();
  if_load_check load_check ();
  rob::store_commit_t store_commit;
  logic store_retire;
  logic store_finish;
  rename::commit_t rename_commit_load, rename_commit_int[2];
  bypass::wakeup_t int_wakeup[2], lsu_wakeup;
  bypass::src_t bypass_src_int[2], bypass_src_load, bypass_src_store;
  bypass::src_loction_t src_loction_int[2], src_loction_load, src_loction_store;
  rename::retire_group_t rename_retire;
  bp::result_t bp_result;
  bp::btb_update_t btb_update;
  if_rq_btb btb_rq ();
  lsu::older_store_t older_store;
  bypass::wakeup_group_t wakeup;
  rename::commit_group_t commit;
  rename::retire_group_t retire;
  assign wakeup = {lsu_wakeup, int_wakeup[1], int_wakeup[0]};
  assign commit = {rename_commit_load, rename_commit_int[1], rename_commit_int[0]};
  rob::wb_index rob_int[2], rob_load, rob_store;
  logic [31:0] bypass_int [2];
  assign bypass_int[0] = reg_winfo_int[0].wdata;
  assign bypass_int[1] = reg_winfo_int[1].wdata;
`ifndef CONFIG_YSYXSOC
  if_axi_write uart_axi ();
`endif
  if_axi_read clint_axi ();

  ysyx_24110006_IFU mifu (
      .i_clock(clock),
      .i_reset(reset),
      .to_idu(from_ifu),
      .o_icache_rq(ifu_icache),
      .o_btb_rq(btb_rq),
      .btb_update(btb_update),
      .bp_result(bp_result),
      .i_fencei(fencei),
      .i_dcache_fencei_fin(fencei_fin),
      .o_vr(ifu_vr_ibuffer),
      .i_flush(flush)
  );
  ysyx_24110006_BTB mbtb (
      .i_clock(clock),
      .i_reset(reset),
      .update(btb_update),
      .i_rq(btb_rq)
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
      .retire(retire),
      .from_idu(idu2rename),
      .dispatch_info(dispatch_info),
      .commit(commit),
      .wakeup(wakeup),
`ifdef CONFIG_SIM
      .o_rat(rat),
`endif
      .i_vr(idu_vr_rename),
      .o_vr(rename_vr_dispatch)
  );
  ysyx_24110006_DISPATCH mdispatch (
      .vr_in(rename_vr_dispatch),
      .vr_load(dispatch_vr_load),
      .vr_store(dispatch_vr_store),
      .vr_int(dispatch_vr_int),
      .vr_rob(dispatch_vr_rob),
      .dispatch_info(dispatch_info),
      .dispatch_int(dispatch_int),
      .dispatch_load(dispatch_load),
      .dispatch_store(dispatch_store),
      .rob_info(dispatch_rob),
      .rob_index(rob_index),
      .rob_int(rob_int),
      .rob_load(rob_load),
      .rob_store(rob_store)
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
      .retire_info(retire),
      .rob_index(rob_index),
      .rob_out(rob_sim),
      .bp_result(bp_result),
      .flush(flush),
      .quit(sim_quit),
      .retire_pc(retire_pc),
      .diff_skip(difftest_skip),
      .store_retire(store_retire)
  );
  generate
    for (genvar i = 0; i < 2; i++) begin :int_unit
      ysyx_24110006_INT_IQ mint_iq (
          .i_clock(clock),
          .i_reset(reset),
          .i_flush(flush),
          .rob_index(rob_int[i]),
          .dispatch_inst(dispatch_int[i]),
          .int_wakeup(int_wakeup[i]),
          .wakeup(wakeup),
          .commit(commit),
          .issue_inst(issue_int[i]),
          .reg_rinfo(reg_rinfo_int[i]),
          .loc(src_loction_int[i]),
          .i_vr(dispatch_vr_int[i]),
          .o_vr(iq_vr_int[i])
      );
      ysyx_24110006_BYPASS mbypass_int (
          .loc(src_loction_int[i]),
          .reg_rdata(reg_rdata_int[i]),
          .int_result(bypass_int),
          .lsu_result(reg_winfo_lsu.wdata),
          .src(bypass_src_int[i])
      );
      ysyx_24110006_ALUOP maluop (
          .csr_rdata(csr_rdata),
          .src(bypass_src_int[i]),
          .issue_info(issue_int[i]),
          .exu_info(exu_info[i])
      );

      ysyx_24110006_EXU mexu (
          .i_clock(clock),
          .i_reset(reset),
          .issue_inst(exu_info[i]),
          .commit(commit_int[i]),
          .rename_commit(rename_commit_int[i]),
          .winfo(reg_winfo_int[i]),
          .i_vr(iq_vr_int[i]),
          .i_flush(flush | fencei)
      );
    end
  endgenerate
  ysyx_24110006_LOAD_IQ mload_iq (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .rob_index(rob_load),
      .dispatch_inst(dispatch_load),
      .wakeup(wakeup),
      .commit(commit),
      .issue_inst(issue_load),
      .reg_rinfo(reg_rinfo_load),
      .store_commit(store_commit),
      .loc(src_loction_load),
      .older_store(older_store),
      .i_vr(dispatch_vr_load),
      .o_vr(iq_vr_load)
  );
  ysyx_24110006_STORE_IQ mstore_iq (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .rob_index(rob_store),
      .dispatch_inst(dispatch_store),
      .wakeup(wakeup),
      .commit(commit),
      .issue_inst(issue_store),
      .reg_rinfo(reg_rinfo_store),
      .store_commit(store_commit),
      .loc(src_loction_store),
      .older_store(older_store),
      .i_vr(dispatch_vr_store),
      .o_vr(iq_vr_store)
  );
  ysyx_24110006_RegisterFile mreg (
      .i_clock(clock),
      .i_reset(reset),
      .rinfo1 (reg_rinfo_int[0]),
      .rdata1 (reg_rdata_int[0]),
      .rinfo2 (reg_rinfo_load),
      .rdata2 (reg_rdata_load),
      .rinfo3 (reg_rinfo_store),
      .rdata3 (reg_rdata_store),
      .rinfo4 (reg_rinfo_int[1]),
      .rdata4 (reg_rdata_int[1]),
      .winfo1 (reg_winfo_int[0]),
      .winfo2 (reg_winfo_lsu),
      .winfo3 (reg_winfo_int[1])
`ifdef CONFIG_SIM,
      .i_rat  (rat)
`endif
  );
  /* ysyx_24110006_CSR mcsr ( */
  /*     .i_clock(clock), */
  /*     .i_reset(reset), */
  /*     .rinfo  (csr_rinfo), */
  /*     .rdata  (csr_rdata), */
  /*     .winfo  (csr_winfo), */
  /*     .einfo  (csr_einfo), */
  /*     .i_valid(retire_valid) */
  /* ); */
  ysyx_24110006_BYPASS mbypass_store (
      .loc(src_loction_store),
      .reg_rdata(reg_rdata_store),
      .int_result(bypass_int),
      .lsu_result(reg_winfo_lsu.wdata),
      .src(bypass_src_store)
  );
  ysyx_24110006_AGU_STORE magu_store (
      .i_clock(clock),
      .vr_in(iq_vr_store),
      .vr_out(agu_vr_store),
      .src(bypass_src_store),
      .issue_info(issue_store),
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
      .o_rq(rq_sbuf),
      .store_finish(rq_sunit.valid)
  );
  ysyx_24110006_STORE_UNIT mstore_unit (
      .i_clock(clock),
      .i_reset(reset),
      .i_vr(sbuf_vr_sunit),
      .i_rq(rq_sbuf),
      .o_rq(rq_sunit)
  );
  ysyx_24110006_BYPASS mbypass_load (
      .loc(src_loction_load),
      .reg_rdata(reg_rdata_load),
      .int_result(bypass_int),
      .lsu_result(reg_winfo_lsu.wdata),
      .src(bypass_src_load)
  );
  ysyx_24110006_AGU_LOAD magu_load (
      .i_clock(clock),
      .vr_in(iq_vr_load),
      .vr_out(agu_vr_load),
      .src(bypass_src_load),
      .issue_info(issue_load),
      .rq_load(rq_agu_load)
  );
  ysyx_24110006_LOAD_UNIT mload_unit (
      .i_clock(clock),
      .i_reset(reset),
      .i_flush(flush),
      .i_vr(agu_vr_load),
      .i_rq(rq_agu_load),
      .o_rq(rq_lunit),
      .check(load_check),
      .winfo(reg_winfo_lsu),
      .rename_commit(rename_commit_load),
      .lsu_wakeup(lsu_wakeup),
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
