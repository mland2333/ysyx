module ysyx_24110006_RENAME #(
    parameter PREG_NUM = 64
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input rename::retire_group_t retire,
    input rename::commit_group_t commit,
    input bypass::wakeup_group_t wakeup,
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
  assign rq1.push = retire.d[0].valid && retire.d[0].has_old_map || 
    retire.d[1].valid && retire.d[1].has_old_map;
  assign rq2.push = retire.d[0].valid && retire.d[0].has_old_map && 
    retire.d[1].valid && retire.d[1].has_old_map;
  assign rq1.push_data = retire.d[0].valid && retire.d[0].has_old_map ? retire.d[0].old_index : retire.d[1].old_index;
  assign rq2.push_data = retire.d[1].old_index;

  assign backup_rq1.pop = retire.d[0].valid || retire.d[1].valid;
  assign backup_rq2.pop = retire.d[0].valid && retire.d[1].valid;
  assign backup_rq1.push = retire.d[0].valid && retire.d[0].has_old_map ||
    retire.d[1].valid && retire.d[1].has_old_map;
  assign backup_rq2.push = retire.d[0].valid && retire.d[0].has_old_map &&
    retire.d[1].valid && retire.d[1].has_old_map;
  assign backup_rq1.push_data = retire.d[0].valid && retire.d[0].has_old_map ? retire.d[0].old_index : retire.d[1].old_index;
  assign backup_rq2.push_data = retire.d[1].old_index;
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
  assign rq_rat.vrs  = from_idu.vrs;
  assign rq_rat.vrd   = from_idu.vrd;
  assign rq_rat.valid = rq1.pop;
  assign rq_rat.prd   = rq1.pop_data;
  RAT mrat (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(flush_retire),
      .retire(retire),
      .commit(commit),
      .wakeup(wakeup),
`ifdef CONFIG_SIM
      .o_rat(o_rat),
`endif
      .rq(rq_rat)
  );
  rf::preg [1:0] prs;
  rf::preg prd;
  logic [1:0] rs_zero;
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      prs <= 0;
      prd <= 0;
      rs_zero <= 0;
    end else if (update_reg) begin
      prs <= rq_rat.prs;
      prd <= rq1.pop_data;
      rs_zero <= {from_idu.vrs[1] == 0, from_idu.vrs[0] == 0};
    end
  end
  function automatic logic check_rs_valid(
    rename::retire_group_t retire,
    rename::commit_group_t commit,
    bypass::wakeup_group_t wakeup,
    rf::preg prs
  );
    logic valid;
    valid = 0;
    foreach(retire.d[i]) valid |= retire.d[i].valid && retire.d[i].prd == prs;
    foreach(commit.d[i]) valid |= commit.d[i].valid && commit.d[i].prd == prs;
    foreach(wakeup.d[i]) valid |= wakeup.d[i].valid && wakeup.d[i].prd == prs;
    return valid;
  endfunction
  logic [1:0] rs_valid;
  always_ff @(posedge i_clock) begin
    if (update_reg) begin
      rs_valid <= rq_rat.rs_valid;
    end else if (!o_vr.ready) begin
      rs_valid[0] <= check_rs_valid(retire, commit, wakeup, prs[0]) || rs_valid[0];
      rs_valid[1] <= check_rs_valid(retire, commit, wakeup, prs[1]) || rs_valid[1];
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
  assign dispatch_info.reg_rinfo.rs[0] = prs[0];
  assign dispatch_info.reg_rinfo.rs[1] = prs[1];
  assign dispatch_info.reg_rinfo.rs_zero = rs_zero;
  assign dispatch_info.quit = idu_data.quit;
  assign dispatch_info.is_lsu = idu_data.is_lsu;
  assign dispatch_info.bp_info = idu_data.bp_info;

endmodule
