`include "common_config.sv"
module ISSUE_QUEUE #(
    parameter NUM = 8,
    parameter WIDTH = 8,
    parameter string MODE,
    parameter type T
) (
    input i_clock,
    input i_reset,
    input i_flush,
    input alloc,
    free,
    output valid,
    input [INDEX-1:0] alloc_index,
    output [INDEX-1:0] free_index,
    input [NUM-1:0] ctrl,
    input bypass::wakeup_group_t wakeup,
    input rename::commit_group_t commit,
    input T alloc_data,
    output T free_data,
    output bypass::src_loction_t loc
);
  localparam INDEX = $clog2(NUM);
  logic full, empty;
  T iq[NUM];

  logic [NUM-1:0] iq_valid;
  logic [1:0] rs_valid[NUM];
  bypass::src_loction_t locs[NUM];
  always_ff @(posedge i_clock) begin
    if (i_reset || i_flush) iq_valid <= 0;
    else if (alloc && free) begin
      iq_valid[alloc_index] <= 1;
      iq_valid[free_index]  <= 0;
    end else if (alloc) begin
      iq_valid[alloc_index] <= 1;
    end else if (free) begin
      iq_valid[free_index] <= 0;
    end
  end

  function logic get_valid_when_alloc(bypass::wakeup_group_t wakeup, rename::commit_group_t commit,
                                      rf::preg rs);
    logic valid;
    valid = 0;
    foreach (wakeup.d[i]) valid = valid | (wakeup.d[i].valid && wakeup.d[i].prd == rs);
    foreach (commit.d[i]) valid = valid | (commit.d[i].valid && commit.d[i].prd == rs);
    return valid;
  endfunction
  function logic get_valid_when_wait(bypass::wakeup_group_t wakeup, rf::preg rs);
    logic valid;
    valid = 0;
    foreach (wakeup.d[i]) valid = valid | (wakeup.d[i].valid && wakeup.d[i].prd == rs);
    return valid;
  endfunction
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM; i++) begin
      for (int j = 0; j < 2; j++) begin
        if (i_reset || i_flush) rs_valid[i][j] <= 0;
        else if (alloc && alloc_index == i) begin
          rs_valid[i][j] <= !alloc_data.data.need_rs[j] || alloc_data.data.rs_valid[j] ||
          get_valid_when_alloc(wakeup, commit, alloc_data.data.reg_rinfo.rs[j]);
        end else if (free && free_index == i) rs_valid[i][j] <= 0;
        else begin
          rs_valid[i][j] <= rs_valid[i][j] ||
              iq_valid[i] && get_valid_when_wait(wakeup, iq[i].data.reg_rinfo.rs[j]);
        end
      end
    end
  end

  function logic is_commit(rename::commit_group_t commit, rf::preg rs);
    foreach (commit.d[i]) if (commit.d[i].valid && commit.d[i].prd == rs) return 1;
    return 0;
  endfunction
  function bypass::src_loction_single_t get_loc_when_alloc(logic ready, bypass::wakeup_group_t wakeup,
                                                    rename::commit_group_t commit, rf::preg rs);
    bypass::src_loction_single_t loc;
    for (int i = 0; i < bypass::SRC_COUNT - 1; i++)
    loc[i] = wakeup.d[i].valid && wakeup.d[i].prd == rs && !ready;
    loc[bypass::SRC_COUNT-1] = is_commit(commit, rs) || ready;
    return loc;
  endfunction
  function bypass::src_loction_single_t get_loc_when_wait(logic ready, bypass::wakeup_group_t wakeup,
                                                   rf::preg rs);
    bypass::src_loction_single_t loc;
    for (int i = 0; i < bypass::SRC_COUNT - 1; i++)
    loc[i] = wakeup.d[i].valid && wakeup.d[i].prd == rs && !ready;
    loc[bypass::SRC_COUNT-1] = ready;
    return loc;
  endfunction
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < NUM; i++) begin
      for (int j = 0; j < 2; j++) begin
        if (i_reset || i_flush) begin
          locs[i].loc[j] <= 0;
        end else if (free && free_index == i) begin
          locs[i].loc[j] <= 0;
        end else if (alloc && alloc_index == i) begin
          locs[i].loc[j] <= get_loc_when_alloc(
              alloc_data.data.need_rs[j] && alloc_data.data.rs_valid[j],
              wakeup,
              commit,
              alloc_data.data.reg_rinfo.rs[j]
          );
        end else begin
          locs[i].loc[j] <=
              get_loc_when_wait(rs_valid[i][j], wakeup, iq[i].data.reg_rinfo.rs[j]);
        end
      end
    end
  end
  typedef struct packed {
    logic valid;
    rob::wb_index age;
    logic [INDEX-1:0] index;
  } entry_t;
  entry_t nodes[NUM*2];
  generate
    if (MODE == "AGE") begin : by_age
      for (genvar i = 0; i < NUM; i++) begin : leaf_init
        always_comb begin
          nodes[i+NUM].valid = rs_valid[i][0] && rs_valid[i][1] && iq_valid[i] && ctrl[i];
          nodes[i+NUM].age   = iq[i].rob_index;
          nodes[i+NUM].index = (INDEX)'(i);
        end
      end
      for (genvar level = 0; level < $clog2(NUM); level++) begin : tree_level
        for (genvar j = (1 << level); j < (1 << (level + 1)); j++) begin : tree_node
          select_older_age #(
              .T(entry_t),
              .C(rob::wb_index)
          ) oldest (
              .a(nodes[j*2]),
              .b(nodes[j*2+1]),
              .select(nodes[j])
          );
        end
      end
      assign free_index = nodes[1].index;
    end else if (MODE == "HEAD") begin : by_head
      logic [INDEX-1:0] r_ptr;
      always_ff @(posedge i_clock) begin
        if (i_reset || i_flush) r_ptr <= 0;
        else if (free) r_ptr <= r_ptr + 1;
      end
      assign free_index = r_ptr;
    end
  endgenerate

  always_ff @(posedge i_clock) begin
    if (alloc) iq[alloc_index] <= alloc_data;
  end
  assign valid = iq_valid[free_index] && rs_valid[free_index] == 2'b11;
  assign loc   = locs[free_index].loc;
  assign free_data = iq[free_index];


endmodule
