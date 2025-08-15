module RAT (
    input i_clock,
    input i_reset,
    input i_flush,
    input rename::retire_group_t retire_info,
    input rename::commit_t commit_int,
    commit_lsu,
    input bypass::wakeup_t int_wakeup,
    lsu_wakeup,
`ifdef CONFIG_SIM
    output logic [31:0][5:0] o_rat,
`endif
    if_rq_rat.in rq
);

  rf::preg rat [32];
  rf::preg arat[32];
  typedef enum {
    IDLE,
    MAPPED,
    COMMIT,
    READY
  } reg_state_t;
  reg_state_t reg_state[32], areg_state[32];
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) reg_state[i] <= IDLE;
      else if (i_flush) begin
        reg_state[i] <= areg_state[i];
      end else begin
        if (rq.valid && rq.vrd != 0 && rq.vrd == i) reg_state[i] <= MAPPED;
        else if (commit_int.valid && commit_int.prd == rat[commit_int.vrd] && commit_int.vrd == i)
          reg_state[i] <= COMMIT;
        else if (commit_lsu.valid && commit_lsu.prd == rat[commit_lsu.vrd] && commit_lsu.vrd == i)
          reg_state[i] <= COMMIT;
        else if (retire_info.d1.valid && retire_info.d1.prd == rat[retire_info.d1.vrd] && retire_info.d1.vrd == i)
          reg_state[i] <= READY;
        else if (retire_info.d2.valid && retire_info.d2.prd == rat[retire_info.d2.vrd] && retire_info.d2.vrd == i)
          reg_state[i] <= READY;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) areg_state[i] <= IDLE;
      else if (retire_info.d1.valid && retire_info.d1.vrd == i)
        areg_state[i] <= READY;
      else if (retire_info.d2.valid && retire_info.d2.vrd == i)
        areg_state[i] <= READY;
    end
  end
  always_ff @(posedge i_clock) begin
    if (i_reset) begin
      for (int i = 0; i < 32; i++) rat[i] <= 0;
    end else if (i_flush) begin
      rat <= arat;
    end else begin
      if (rq.valid && rq.vrd != 0) rat[rq.vrd] <= rq.prd;
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) arat[i] <= 0;
      else if (retire_info.d1.valid && retire_info.d1.vrd == i && !(retire_info.d2.valid && retire_info.d2.vrd == i))
        arat[i] <= retire_info.d1.prd;
      else if (retire_info.d2.valid && retire_info.d2.vrd == i)
        arat[i] <= retire_info.d2.prd;
    end
  end
  assign rq.rs_valid[0] = reg_state[rq.vrs1] != MAPPED ||
        rq.vrs1 == 0 ||
        retire_info.d1.valid && retire_info.d1.prd == rat[rq.vrs1] ||
        retire_info.d2.valid && retire_info.d2.prd == rat[rq.vrs1] ||
        commit_int.valid && commit_int.prd == rat[rq.vrs1] ||
        commit_lsu.valid && commit_lsu.prd == rat[rq.vrs1] ||
        int_wakeup.valid && int_wakeup.rd == rat[rq.vrs1] ||
        lsu_wakeup.valid && lsu_wakeup.rd == rat[rq.vrs1];
  assign rq.rs_valid[1] = reg_state[rq.vrs2] != MAPPED ||
        rq.vrs2 == 0 ||
        retire_info.d1.valid && retire_info.d1.prd == rat[rq.vrs2] ||
        retire_info.d2.valid && retire_info.d2.prd == rat[rq.vrs2] ||
        commit_int.valid && commit_int.prd == rat[rq.vrs2] ||
        commit_lsu.valid && commit_lsu.prd == rat[rq.vrs2] ||
        int_wakeup.valid && int_wakeup.rd == rat[rq.vrs2] ||
        lsu_wakeup.valid && lsu_wakeup.rd == rat[rq.vrs2];
  assign rq.has_old_map = reg_state[rq.vrd] != IDLE;
  assign rq.old_index = rat[rq.vrd];
  assign rq.prs1 = rat[rq.vrs1];
  assign rq.prs2 = rat[rq.vrs2];
`ifdef CONFIG_SIM
  always_comb begin
    for (int i = 0; i < 32; i++) o_rat[i] = arat[i];
  end
`endif
endmodule
