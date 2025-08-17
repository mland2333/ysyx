module RAT (
    input i_clock,
    input i_reset,
    input i_flush,
    input rename::retire_group_t retire,
    input rename::commit_group_t commit,
    input bypass::wakeup_group_t wakeup,
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
  function logic is_commit(rename::commit_group_t commit, rf::vreg index, rf::preg rat[32]);
    for(int i =0; i<rename::COMMIT_COUNT; i++)
      if(commit.d[i].valid && commit.d[i].prd == rat[commit.d[i].vrd] && commit.d[i].vrd == index) return 1;
    return 0;
  endfunction
  function logic is_retire(rename::retire_group_t retire, rf::vreg index, rf::preg rat[32]);
    for(int i =0; i<rename::RETIRE_COUNT; i++)
      if(retire.d[i].valid && retire.d[i].prd == rat[retire.d[i].vrd] && retire.d[i].vrd == index) return 1;
    return 0;
  endfunction
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) reg_state[i] <= IDLE;
      else if (i_flush) begin
        reg_state[i] <= areg_state[i];
      end else begin
        if (rq.valid && rq.vrd != 0 && rq.vrd == i) reg_state[i] <= MAPPED;
        else if(is_commit(commit, 5'(i), rat)) reg_state[i] <= COMMIT;
        else if(is_retire(retire, 5'(i), rat)) reg_state[i] <= READY;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) areg_state[i] <= IDLE;
      else begin
        for(int j = 0; j<rename::COMMIT_COUNT; j++)
          if(retire.d[j].valid && retire.d[j].vrd == i)
            areg_state[i] <= READY;
      end
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
      else if (retire.d[0].valid && retire.d[0].vrd == i && !(retire.d[1].valid && retire.d[1].vrd == i))
        arat[i] <= retire.d[0].prd;
      else if (retire.d[1].valid && retire.d[1].vrd == i)
        arat[i] <= retire.d[1].prd;
    end
  end
  function automatic logic check_rs_valid(
    rename::retire_group_t retire,
    rename::commit_group_t commit,
    bypass::wakeup_group_t wakeup,
    rf::preg rat[32],
    rf::vreg vrs
  );
    logic valid;
    valid = 0;
    foreach(retire.d[i]) valid |= retire.d[i].valid && retire.d[i].prd == rat[vrs];
    foreach(commit.d[i]) valid |= commit.d[i].valid && commit.d[i].prd == rat[vrs];
    foreach(wakeup.d[i]) valid |= wakeup.d[i].valid && wakeup.d[i].prd == rat[vrs];
    return valid;
  endfunction
  assign rq.rs_valid[0] = reg_state[rq.vrs[0]] != MAPPED ||
        rq.vrs[0] == 0 || check_rs_valid(retire, commit, wakeup, rat, rq.vrs[0]);
  assign rq.rs_valid[1] = reg_state[rq.vrs[1]] != MAPPED ||
        rq.vrs[1] == 0 || check_rs_valid(retire, commit, wakeup, rat, rq.vrs[1]);
  assign rq.has_old_map = reg_state[rq.vrd] != IDLE;
  assign rq.old_index = rat[rq.vrd];
  assign rq.prs[0] = rat[rq.vrs[0]];
  assign rq.prs[1] = rat[rq.vrs[1]];
`ifdef CONFIG_SIM
  always_comb begin
    for (int i = 0; i < 32; i++) o_rat[i] = arat[i];
  end
`endif
endmodule
