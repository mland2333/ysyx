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
    if_rq_rat.in rq[2]
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
    for (int i = 0; i < rename::COMMIT_COUNT; i++)
    if (commit.d[i].valid && commit.d[i].prd == rat[commit.d[i].vrd] && commit.d[i].vrd == index)
      return 1;
    return 0;
  endfunction
  function logic is_retire(rename::retire_group_t retire, rf::vreg index, rf::preg rat[32]);
    for (int i = 0; i < rename::RETIRE_COUNT; i++)
    if (retire.d[i].valid && retire.d[i].prd == rat[retire.d[i].vrd] && retire.d[i].vrd == index)
      return 1;
    return 0;
  endfunction
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) reg_state[i] <= IDLE;
      else if (i_flush) begin
        reg_state[i] <= areg_state[i];
      end else begin
        if (rq[0].valid && rq[0].vrd == i || rq[1].valid && rq[1].vrd == i) reg_state[i] <= MAPPED;
        else if (is_commit(commit, 5'(i), rat)) reg_state[i] <= COMMIT;
        else if (is_retire(retire, 5'(i), rat)) reg_state[i] <= READY;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) areg_state[i] <= IDLE;
      else begin
        for (int j = 0; j < rename::COMMIT_COUNT; j++)
        if (retire.d[j].valid && retire.d[j].vrd == i) areg_state[i] <= READY;
      end
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) rat[i] <= 0;
      else if (i_flush) rat[i] <= arat[i];
      else if (rq[0].valid && (!rq[1].valid || rq[1].vrd != rq[0].vrd) && i == rq[0].vrd)
        rat[i] <= rq[0].prd;
      else if (rq[1].valid && i == rq[1].vrd) rat[i] <= rq[1].prd;
    end
  end
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < 32; i++) begin
      if (i_reset) arat[i] <= 0;
      else if (retire.d[0].valid && retire.d[0].vrd == i && !(retire.d[1].valid && retire.d[1].vrd == i))
        arat[i] <= retire.d[0].prd;
      else if (retire.d[1].valid && retire.d[1].vrd == i) arat[i] <= retire.d[1].prd;
    end
  end
  function automatic logic check_rs_valid(
      rename::retire_group_t retire, rename::commit_group_t commit, bypass::wakeup_group_t wakeup,
      rf::preg rat[32], rf::vreg vrs);
    logic valid;
    valid = 0;
    foreach (retire.d[i]) valid |= retire.d[i].valid && retire.d[i].prd == rat[vrs];
    foreach (commit.d[i]) valid |= commit.d[i].valid && commit.d[i].prd == rat[vrs];
    foreach (wakeup.d[i]) valid |= wakeup.d[i].valid && wakeup.d[i].prd == rat[vrs];
    return valid;
  endfunction
  assign rq[0].rs_valid[0] = reg_state[rq[0].vrs[0]] != MAPPED || rq[0].vrs[0] == 0 || check_rs_valid(
      retire, commit, wakeup, rat, rq[0].vrs[0]
  );
  assign rq[0].rs_valid[1] = reg_state[rq[0].vrs[1]] != MAPPED || rq[0].vrs[1] == 0 || check_rs_valid(
      retire, commit, wakeup, rat, rq[0].vrs[1]
  );
  assign rq[1].rs_valid[0] = (reg_state[rq[1].vrs[0]] != MAPPED || rq[1].vrs[0] == 0 || check_rs_valid(
      retire, commit, wakeup, rat, rq[1].vrs[0]
  )) && !(rq[0].valid && rq[0].vrd == rq[1].vrs[0]);
  assign rq[1].rs_valid[1] = (reg_state[rq[1].vrs[1]] != MAPPED || rq[1].vrs[1] == 0 || check_rs_valid(
      retire, commit, wakeup, rat, rq[1].vrs[1]
  )) && !(rq[0].valid && rq[0].vrd == rq[1].vrs[1]);
  assign rq[0].has_old_map = reg_state[rq[0].vrd] != IDLE;
  assign rq[1].has_old_map = reg_state[rq[1].vrd] != IDLE && !(rq[0].valid && rq[1].vrd == rq[0].vrd);
  assign rq[0].old_index = rat[rq[0].vrd];
  assign rq[1].old_index = rq[0].valid && rq[1].vrd == rq[0].vrd ? rq[0].prd : rat[rq[1].vrd];
  assign rq[0].prs[0] = rat[rq[0].vrs[0]];
  assign rq[0].prs[1] = rat[rq[0].vrs[1]];
  assign rq[1].prs[0] = rq[0].valid && rq[0].vrd == rq[1].vrs[0] ? rq[0].prd : rat[rq[1].vrs[0]];
  assign rq[1].prs[1] = rq[0].valid && rq[0].vrd == rq[1].vrs[1] ? rq[0].prd : rat[rq[1].vrs[1]];
`ifdef CONFIG_SIM
  always_comb begin
    for (int i = 0; i < 32; i++) o_rat[i] = arat[i];
  end
`endif
endmodule
