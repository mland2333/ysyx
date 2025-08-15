`include "common_config.sv"
module ysyx_24110006_ROB #(
    parameter ROB_NUM = `ROB_NUM
) (
    input i_clock,
    input i_reset,
    if_pipeline_vr.in vr_in,
    input rob::inst_info_t dispatch_inst,
    input rob::commit_info_t commit_int,
    input rob::commit_info_t commit_lsu,
    input rob::store_commit_t commit_store,
    output rob::wb_index rob_index,
    output logic [1:0] retire_valid,
    output rename::retire_group_t retire_info,
    output rob::rob_t rob_out,
    output bp::result_t bp_result,
    output flush,
    output store_retire
);
  logic empty, almost_empty, full, almost_full;
  if_rq_rob_fifo #(
      .WIDTH($bits(rob::inst_info_t)),
      .NUM  (ROB_NUM)
  ) rq1 ();
  if_rq_rob_fifo #(
      .WIDTH($bits(rob::inst_info_t)),
      .NUM  (ROB_NUM)
  ) rq2 ();
  logic [1:0] pop_valid, push_valid;
  logic pop, push, pop2, push2;
  assign vr_in.ready = !full;
  assign pop = rq1.pop;
  assign push = vr_in.valid && vr_in.ready;
  assign rq1.push = push;
  assign rq1.pop = valid[rq1.pop_index];
  assign rq2.push = 0;
  assign rq2.pop = pop && valid[rq2.pop_index] && !(two_store || first_flush || second_flush);
  assign rq1.push_data = dispatch_inst;
  assign rq2.push_data = 0;
  rob::inst_info_t inst1, inst2;
  assign inst1 = rq1.pop_data;
  assign inst2 = rq2.pop_data;
  logic two_store, first_flush, second_flush;
  assign two_store = inst1.type_store && inst2.type_store;
  assign first_flush = result[rq1.pop_index].flush;
  assign second_flush = result[rq2.pop_index].flush;
  assign push2 = rq1.push && rq2.push;
  assign pop2 = rq1.pop && rq2.pop;
  localparam ROB_INDEX = $clog2(ROB_NUM);
  rob::result_t result[ROB_NUM];
  logic valid[ROB_NUM];
  ROB_FIFO #(
      .WIDTH($bits(rob::inst_info_t)),
      .NUM  (ROB_NUM)
  ) mrob (
      .i_clock(i_clock),
      .i_reset(i_reset),
      .i_flush(flush),
      .rq1(rq1),
      .rq2(rq2),
      .empty(empty),
      .almost_empty(almost_empty),
      .full(full),
      .almost_full()
  );
  always_ff @(posedge i_clock) begin
    for (int i = 0; i < ROB_NUM; i++) begin
      if (i_reset || flush) valid[i] <= 0;
      else if (commit_int.valid && commit_int.index[ROB_INDEX-1:0] == i) begin
        result[i] <= commit_int.result;
        valid[i]  <= 1;
      end else if (commit_lsu.valid && commit_lsu.index[ROB_INDEX-1:0] == i) begin
        result[i] <= commit_lsu.result;
        valid[i]  <= 1;
      end else if (commit_store.valid && commit_store.index[ROB_INDEX-1:0] == i) begin
        valid[i]  <= 1;
        result[i] <= 0;
      end else if (valid[i] && rq1.pop_index == i && rq1.pop) begin
        valid[i] <= 0;
      end else if (valid[i] && rq2.pop_index == i && rq2.pop) begin
        valid[i] <= 0;
      end
    end
  end

  assign retire_valid = {rq2.pop, rq1.pop};
  assign flush = retire_valid[0] && result[rq1.pop_index].flush;

  assign retire_info.d1.valid = rq1.pop && inst1.reg_wen && inst1.vrd != 0;
  assign retire_info.d1.has_old_map = inst1.has_old_map;
  assign retire_info.d1.old_index = inst1.old_index;
  assign retire_info.d1.vrd = inst1.vrd;
  assign retire_info.d1.prd = inst1.prd;

  assign retire_info.d2.valid = rq2.pop && inst2.reg_wen && inst2.vrd != 0;
  assign retire_info.d2.has_old_map = inst2.has_old_map;
  assign retire_info.d2.old_index = inst2.old_index;
  assign retire_info.d2.vrd = inst2.vrd;
  assign retire_info.d2.prd = inst2.prd;

  assign store_retire = rq1.pop && inst1.type_store || rq2.pop && inst2.type_store;

  
  assign bp_result.btb_update = rq1.pop && result[rq1.pop_index].btb_update;
  assign bp_result.pred_taken = retire_valid[1] ? inst2.bp_info.pred_taken : inst1.bp_info.pred_taken;
  assign bp_result.pc = retire_valid[1] ? inst2.pc : inst1.pc;
  assign bp_result.upc = retire_valid[1] ? result[rq2.pop_index].upc : result[rq1.pop_index].upc;
  assign rob_index = rq1.push_index;
endmodule
