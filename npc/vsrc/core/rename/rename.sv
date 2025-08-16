module ysyx_24110006_RENAME #(
    parameter PREG_NUM = 64
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input rename::retire_group_t retire_info,
    input rename::commit_t commit_int,
    commit_lsu,
    input bypass::wakeup_t int_wakeup,
    lsu_wakeup,
    input ooo::idu2rename_t from_idu,
    output ooo::dispatch_info_t dispatch_info,
`ifdef CONFIG_SIM
    output logic [31:0][5:0] o_rat,
`endif
    if_pipeline_vr i_vr,
    if_pipeline_vr o_vr
);
  logic r_valid;
  assign r_valid = i_vr.valid && !i_flush && !full;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) o_vr.valid <= 0;
    else if (r_ready && r_valid && !o_vr.valid) begin
      o_vr.valid <= 1;
    end else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) begin
      o_vr.valid <= 0;
    end
  end
  reg r_ready;
  always @(posedge i_clock) begin
    if (i_reset || i_flush) r_ready <= 1;
    else if (r_ready && r_valid && !o_vr.valid) r_ready <= 0;
    else if (!r_ready && o_vr.valid && o_vr.ready && !r_valid) r_ready <= 1;
  end
  assign i_vr.ready = (r_ready || o_vr.ready) && !full;
  logic update_reg;
  assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush && !full;

  localparam PREG_NUM_INDEX = $clog2(PREG_NUM);
  if_rq_fifo #(
      .WIDTH(PREG_NUM_INDEX)
  )
      rq1(), rq2(), backup_rq1(), backup_rq2();
  assign rq1.pop = r_valid && from_idu.reg_wen && i_vr.ready && from_idu.vrd != 0 && !i_flush;
  assign rq2.pop = 0;
  assign rq1.push = retire_info.d1.valid && retire_info.d1.has_old_map || 
    retire_info.d2.valid && retire_info.d2.has_old_map;
  assign rq2.push = retire_info.d1.valid && retire_info.d1.has_old_map && 
    retire_info.d2.valid && retire_info.d2.has_old_map;
  assign rq1.push_data = retire_info.d1.valid && retire_info.d1.has_old_map ? retire_info.d1.old_index : retire_info.d2.old_index;
  assign rq2.push_data = retire_info.d2.old_index;

  assign backup_rq1.pop = retire_info.d1.valid || retire_info.d2.valid;
  assign backup_rq2.pop = retire_info.d1.valid && retire_info.d2.valid;
  assign backup_rq1.push = retire_info.d1.valid && retire_info.d1.has_old_map ||
    retire_info.d2.valid && retire_info.d2.has_old_map;
  assign backup_rq2.push = retire_info.d1.valid && retire_info.d1.has_old_map &&
    retire_info.d2.valid && retire_info.d2.has_old_map;
  assign backup_rq1.push_data = retire_info.d1.valid && retire_info.d1.has_old_map ? retire_info.d1.old_index : retire_info.d2.old_index;
  assign backup_rq2.push_data = retire_info.d2.old_index;
  rename::free_list_backup_t free_list_backup;
  logic free_list_full, free_list_empty;
  DOUBLE_PROT_FREE_LIST #(
      .WIDTH(PREG_NUM_INDEX),
      .NUM  (PREG_NUM)
  ) mfree_list (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(flush_retire),
      .rq1(rq1),
      .rq2(rq2),
      .empty(free_list_empty),
      .almost_empty(),
      .full(free_list_full),
      .almost_full(),
      .backup(free_list_backup)
  );
  FREE_LIST_BACKUP #(
      .WIDTH(PREG_NUM_INDEX),
      .NUM  (PREG_NUM)
  ) mfree_list_backup (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .rq1(backup_rq1),
      .rq2(backup_rq2),
      .backup(free_list_backup)
  );
  logic full, empty;
  logic need_alloc;
  logic flush_retire;
  assign full = free_list_empty;
  assign empty = free_list_full;
  assign need_alloc = r_valid && from_idu.reg_wen && i_vr.ready && from_idu.vrd != 0 && !i_flush;
  always_ff @(posedge i_clock) begin
    if (i_flush) flush_retire <= 1;
    else if (flush_retire) flush_retire <= 0;
  end

  ooo::idu2rename_t idu_data;
  always_ff @(posedge i_clock) begin
    if (update_reg) idu_data <= from_idu;
  end
  if_rq_rat rq_rat ();
  assign rq_rat.valid = need_alloc;
  assign rq_rat.vrs1  = from_idu.vrs1;
  assign rq_rat.vrs2  = from_idu.vrs2;
  assign rq_rat.vrd   = from_idu.vrd;
  assign rq_rat.valid = rq1.pop;
  assign rq_rat.prd   = rq1.pop_data;
  RAT mrat (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(flush_retire),
      .retire_info(retire_info),
      .commit_int(commit_int),
      .commit_lsu(commit_lsu),
      .int_wakeup(int_wakeup),
      .lsu_wakeup(lsu_wakeup),
`ifdef CONFIG_SIM
      .o_rat(o_rat),
`endif
      .rq(rq_rat)
  );
  rf::preg prs1, prs2, prd;
  logic [1:0] rs_zero;
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      prs1 <= 0;
      prs2 <= 0;
      prd <= 0;
      rs_zero <= 0;
    end else if (update_reg) begin
      prs1 <= rq_rat.prs1;
      prs2 <= rq_rat.prs2;
      prd <= rq1.pop_data;
      rs_zero <= {from_idu.vrs2 == 0, from_idu.vrs1 == 0};
    end
  end

  logic [1:0] rs_valid;
  always_ff @(posedge i_clock) begin
    if (update_reg) begin
      rs_valid <= rq_rat.rs_valid;
    end else if (!o_vr.ready) begin
      rs_valid[0] <= 
        idu_data.vrs1 == 0 ||
        retire_info.d1.valid && retire_info.d1.prd == prs1 ||
        retire_info.d2.valid && retire_info.d2.prd == prs1 ||
        commit_int.valid && commit_int.prd == prs1 ||
        commit_lsu.valid && commit_lsu.prd == prs1 ||
        int_wakeup.valid && int_wakeup.rd == prs1 ||
        lsu_wakeup.valid && lsu_wakeup.rd == prs1 || rs_valid[0];
      rs_valid[1] <= 
        idu_data.vrs2 == 0 ||
        retire_info.d1.valid && retire_info.d1.prd == prs2 ||
        retire_info.d2.valid && retire_info.d2.prd == prs2 ||
        commit_int.valid && commit_int.prd == prs2 ||
        commit_lsu.valid && commit_lsu.prd == prs2 ||
        int_wakeup.valid && int_wakeup.rd == prs2 ||
        lsu_wakeup.valid && lsu_wakeup.rd == prs2 || rs_valid[1];
    end
  end
  logic has_old_map;
  rf::preg old_index;
  always_ff @(posedge i_clock) begin
    if (rq1.pop) begin
      has_old_map <= rq_rat.has_old_map;
      old_index   <= rq_rat.old_index;
    end
  end
  assign dispatch_info.basic_inst_info.op = idu_data.op;
  assign dispatch_info.basic_inst_info.func = idu_data.func;
  assign dispatch_info.basic_inst_info.pc = idu_data.pc;
  assign dispatch_info.basic_inst_info.imm = idu_data.imm;
  assign dispatch_info.prd = prd;
  assign dispatch_info.vrd = idu_data.vrd;
  assign dispatch_info.mem_wen = idu_data.mem_wen;
  assign dispatch_info.reg_wen = idu_data.reg_wen;
  assign dispatch_info.has_old_map = has_old_map;
  assign dispatch_info.old_index = old_index;
  assign dispatch_info.need_rs = idu_data.need_rs;
  assign dispatch_info.rs_valid = rs_valid;
  assign dispatch_info.reg_rinfo.rs1 = prs1;
  assign dispatch_info.reg_rinfo.rs2 = prs2;
  assign dispatch_info.reg_rinfo.rs_zero = rs_zero;
  assign dispatch_info.quit = idu_data.quit;
  assign dispatch_info.is_lsu = idu_data.is_lsu;
  assign dispatch_info.bp_info = idu_data.bp_info;

endmodule
