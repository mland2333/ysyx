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
  assign r_valid = i_vr.valid && !i_flush && !full && !almost_full;
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
  assign i_vr.ready = (r_ready || o_vr.ready) && !full && !almost_full;
  logic update_reg;
  assign update_reg = r_valid && (r_ready || o_vr.ready) && !i_flush && !full && !almost_full;

  localparam PREG_NUM_INDEX = $clog2(PREG_NUM);
  if_rq_fifo #(.WIDTH(PREG_NUM_INDEX)) rq[1:0] ();
  if_rq_fifo #(.WIDTH(PREG_NUM_INDEX)) backup_rq[1:0] ();
  logic [1:0] pop;
  assign pop = {
    from_idu.inst_valid[1] && from_idu.d[1].reg_wen, from_idu.inst_valid[0] && from_idu.d[0].reg_wen
  };
  assign rq[0].pop = r_valid && i_vr.ready && !i_flush && (pop[0] || pop[1]);
  assign rq[1].pop = r_valid && i_vr.ready && !i_flush && (pop[0] && pop[1]);
  assign rq[0].push = retire.d[0].valid && retire.d[0].has_old_map || 
    retire.d[1].valid && retire.d[1].has_old_map;
  assign rq[1].push = retire.d[0].valid && retire.d[0].has_old_map && 
    retire.d[1].valid && retire.d[1].has_old_map;
  assign rq[0].push_data = retire.d[0].valid && retire.d[0].has_old_map ? retire.d[0].old_index : retire.d[1].old_index;
  assign rq[1].push_data = retire.d[1].old_index;

  assign backup_rq[0].pop = retire.d[0].valid || retire.d[1].valid;
  assign backup_rq[1].pop = retire.d[0].valid && retire.d[1].valid;
  assign backup_rq[0].push = retire.d[0].valid && retire.d[0].has_old_map ||
    retire.d[1].valid && retire.d[1].has_old_map;
  assign backup_rq[1].push = retire.d[0].valid && retire.d[0].has_old_map &&
    retire.d[1].valid && retire.d[1].has_old_map;
  assign backup_rq[0].push_data = retire.d[0].valid && retire.d[0].has_old_map ? retire.d[0].old_index : retire.d[1].old_index;
  assign backup_rq[1].push_data = retire.d[1].old_index;
  rename::free_list_backup_t free_list_backup;
  logic free_list_full, free_list_empty, free_list_almost_empty;
  DOUBLE_PROT_FREE_LIST #(
      .WIDTH(PREG_NUM_INDEX),
      .NUM  (PREG_NUM)
  ) mfree_list (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(flush_retire),
      .rq1(rq[0]),
      .rq2(rq[1]),
      .empty(free_list_empty),
      .almost_empty(free_list_almost_empty),
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
      .rq1(backup_rq[0]),
      .rq2(backup_rq[1]),
      .backup(free_list_backup)
  );
  logic full, empty, almost_full;
  logic flush_retire;
  assign full = free_list_empty;
  assign empty = free_list_full;
  assign almost_full = free_list_almost_empty;
  always_ff @(posedge i_clock) begin
    if (i_flush) flush_retire <= 1;
    else if (flush_retire) flush_retire <= 0;
  end

  ooo::idu2rename_t idu_data;
  always_ff @(posedge i_clock) begin
    if (update_reg) idu_data <= from_idu;
  end
  if_rq_rat rq_rat[2] ();
  assign rq_rat[0].valid = r_valid && i_vr.ready && !i_flush && pop[0];
  assign rq_rat[0].vrs   = from_idu.d[0].vrs;
  assign rq_rat[0].vrd   = from_idu.d[0].vrd;
  assign rq_rat[0].prd   = rq[0].pop_data;

  assign rq_rat[1].valid = r_valid && i_vr.ready && !i_flush && pop[1];
  assign rq_rat[1].vrs   = from_idu.d[1].vrs;
  assign rq_rat[1].vrd   = from_idu.d[1].vrd;
  assign rq_rat[1].prd   = !pop[0] && pop[1] ? rq[0].pop_data : rq[1].pop_data;
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
  rf::preg [1:0] prs[2];
  rf::preg prd[2];
  logic [1:0] rs_zero[2];
  generate
    for (genvar i = 0; i < 2; i++) begin
      always_ff @(posedge i_clock) begin
        if (i_reset) begin
          prs[i] <= 0;
          prd[i] <= 0;
          rs_zero[i] <= 0;
        end else if (update_reg) begin
          prs[i] <= rq_rat[i].prs;
          prd[i] <= rq_rat[i].prd;
          rs_zero[i] <= {from_idu.d[i].vrs[1] == 0, from_idu.d[i].vrs[0] == 0};
        end
      end
    end
  endgenerate
  function automatic logic check_rs_valid(rename::retire_group_t retire,
                                          rename::commit_group_t commit,
                                          bypass::wakeup_group_t wakeup, rf::preg prs);
    logic valid;
    valid = 0;
    foreach (retire.d[i]) valid |= retire.d[i].valid && retire.d[i].prd == prs;
    foreach (commit.d[i]) valid |= commit.d[i].valid && commit.d[i].prd == prs;
    foreach (wakeup.d[i]) valid |= wakeup.d[i].valid && wakeup.d[i].prd == prs;
    return valid;
  endfunction
  logic [1:0] rs_valid[2];
  logic has_old_map[2];
  rf::preg old_index[2];
  generate
    for (genvar i = 0; i < 2; i++) begin
      always_ff @(posedge i_clock) begin
        if (update_reg) begin
          rs_valid[i] <= rq_rat[i].rs_valid;
        end else if (!o_vr.ready) begin
          rs_valid[i][0] <= check_rs_valid(retire, commit, wakeup, prs[i][0]) || rs_valid[i][0];
          rs_valid[i][1] <= check_rs_valid(retire, commit, wakeup, prs[i][1]) || rs_valid[i][1];
        end
      end
      always_ff @(posedge i_clock) begin
        if (rq_rat[i].valid) begin
          has_old_map[i] <= rq_rat[i].has_old_map;
          old_index[i]   <= rq_rat[i].old_index;
        end
      end
    end
  endgenerate

  generate
    for (genvar i = 0; i < 2; i++) begin
      assign dispatch_info.d[i].basic_inst_info.op = idu_data.d[i].op;
      assign dispatch_info.d[i].basic_inst_info.func = idu_data.d[i].func;
      assign dispatch_info.d[i].basic_inst_info.pc = idu_data.d[i].pc;
      assign dispatch_info.d[i].basic_inst_info.imm = idu_data.d[i].imm;
      assign dispatch_info.d[i].prd = prd[i];
      assign dispatch_info.d[i].vrd = idu_data.d[i].vrd;
      assign dispatch_info.d[i].mem_wen = idu_data.d[i].mem_wen;
      assign dispatch_info.d[i].reg_wen = idu_data.d[i].reg_wen;
      assign dispatch_info.d[i].has_old_map = has_old_map[i];
      assign dispatch_info.d[i].old_index = old_index[i];
      assign dispatch_info.d[i].need_rs = idu_data.d[i].need_rs;
      assign dispatch_info.d[i].rs_valid = rs_valid[i];
      assign dispatch_info.d[i].reg_rinfo.rs = prs[i];
      assign dispatch_info.d[i].reg_rinfo.rs_zero = rs_zero[i];
      assign dispatch_info.d[i].quit = idu_data.d[i].quit;
      assign dispatch_info.d[i].is_lsu = idu_data.d[i].is_lsu;
      assign dispatch_info.d[i].bp_info = idu_data.d[i].bp_info;
      assign dispatch_info.inst_valid[i] = idu_data.inst_valid[i];
    end
  endgenerate

endmodule
